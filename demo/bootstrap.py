# -*- coding: utf-8 -*-
"""
init_database.py —— 一键初始化入口。

依次完成：
  1) 建库 + 全部表（执行 sql/00_create_database.dos，内含 dropDatabase，会清空同名库）
  2) 加载 sql/ 中的基础数据：日历、收益率曲线定义、债券信息、日 K 线
  3) 可选（--deploy）：通过 DolphinDB 会话把 6 个业务 .dos 写到【服务端】
     scripts 目录（mkdir + file 句柄落盘），无需访问服务器宿主机文件系统，
     只需要 DolphinDB 的地址和账号密码即可，适用于远程服务器场景。

执行后：dfs://caplib-bond 库结构完整、基础数据就绪；加 --deploy 时服务端 scripts
目录含全部业务函数，在 DolphinDB 会话中 run 即可调用定价 / 估值 / VaR-ES。

用法：
    python init_database.py
    python init_database.py --deploy
    python init_database.py --host 127.0.0.1 --port 8849 --user admin --pass 123456

    --deploy          同时部署业务脚本到服务端 scripts 目录（默认不部署）
    --server-scripts  服务端 scripts 目录（容器内路径），
                      默认 /data/ddb/server/scripts
    --sql             基础数据脚本目录，默认 ./sql
    --keep            保留现有库、不重建（跳过 00 的 dropDatabase，仅重载数据）
"""
import argparse
import os
import sys

import dolphindb as ddb

# Windows 控制台默认 GBK，中文 print 会乱码；切到 UTF-8
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

# 业务脚本（项目源目录），部署到服务端 scripts 目录
BUSINESS_SCRIPTS = [
    "create_calendar.dos",
    "create_bond_templates.dos",
    "build_yield_curve.dos",
    "bond_pricing.dos",
    "bond_risk.dos",
    "pricing_batch.dos",
]

# 基础数据脚本（00 单独处理）
BASE_SCRIPTS = [
    "t_calendar.dos",
    "t_bond_yield_curve_def.dos",
    "t_bond_info.dos",
    "t_bond_day_kline.dos",
]


def parse_args():
    here = os.path.dirname(os.path.abspath(__file__))
    p = argparse.ArgumentParser(description="初始化 caplib-bond 数据库")
    p.add_argument("--host", default="127.0.0.1")
    p.add_argument("--port", type=int, default=8849)
    p.add_argument("--user", default="admin")
    p.add_argument("--pass", dest="password", default="123456")
    p.add_argument("--db", default="dfs://caplib-bond")
    p.add_argument("--source", default=here,
                   help="业务脚本源目录（项目目录）")
    p.add_argument("--server-scripts", default="/data/ddb/server/scripts",
                   help="服务端（容器内）scripts 目录，不存在则自动 mkdir")
    p.add_argument("--sql", default=os.path.join(here, "sql"))
    p.add_argument("--deploy", action="store_true",
                   help="同时部署业务脚本到服务端 scripts 目录（默认不部署）")
    p.add_argument("--keep", action="store_true",
                   help="保留现有库，仅重载数据，不执行 dropDatabase")
    return p.parse_args()


def run_script(s, path):
    with open(path, encoding="utf-8") as f:
        return s.run(f.read())


def deploy_business_scripts(s, args):
    """通过 DolphinDB 会话把业务 .dos 写到服务端 scripts 目录。

    只依赖 DolphinDB 连接（地址 + 账号密码），不接触宿主机文件系统，
    因此远程服务器只开 8848 端口也能部署。
    """
    # 服务端目录不存在则创建（mkdir 要求会话已登录，connect 时已完成）
    s.run(f"""
if(!exists("{args.server_scripts}"))
    mkdir("{args.server_scripts}")
""")

    # 服务端写文件函数：file 句柄 + writeLine（LF 结尾，无 CRLF 问题）
    # 注：DolphinDB 函数名不能以下划线开头
    s.run("""
def deployWriteFile(path, text) {
    f = file(path, "w")
    f.writeLine(text)
    f.close()
}
""")

    target_dir = args.server_scripts.rstrip("/")
    expected_sizes = {}
    for name in BUSINESS_SCRIPTS:
        with open(os.path.join(args.source, name), encoding="utf-8") as fp:
            content = fp.read()  # 文本模式：CRLF 统一规整为 LF
        # writeLine 会在末尾补一个 \n
        expected_sizes[name] = len(content.encode("utf-8")) + 1
        s.run("deployWriteFile", f"{target_dir}/{name}", content)
        print(f"[3] 部署业务脚本 {name} -> {target_dir}")

    # 用 files() 核对落盘结果（文件名 + 字节数）
    listing = s.run(f'files("{target_dir}")')
    sizes = dict(zip(listing["filename"], listing["fileSize"]))
    print(f"[3] 服务端 {target_dir} 核对：")
    ok = True
    for name in BUSINESS_SCRIPTS:
        actual = sizes.get(name)
        match = actual == expected_sizes[name]
        ok &= match
        flag = "OK" if match else "大小不一致!"
        print(f"    {name:30} {actual} bytes  {flag}")
    if not ok:
        raise RuntimeError("部署校验失败：服务端文件大小与本地不一致")


def main():
    args = parse_args()

    s = ddb.session()
    s.connect(args.host, args.port, args.user, args.password)

    # 1) 建库 + 全部表
    if args.keep:
        print("[1] --keep：跳过重建，沿用现有库与表")
    else:
        run_script(s, os.path.join(args.sql, "00_create_database.dos"))
        print(f"[1] 已重建数据库 {args.db}（库 + 全部表）")

    # 2) 加载基础数据
    for name in BASE_SCRIPTS:
        run_script(s, os.path.join(args.sql, name))
        print(f"[2] 已加载基础数据 {name}")

    # 3) 可选：部署业务脚本到服务端
    if args.deploy:
        deploy_business_scripts(s, args)
    else:
        print("[3] 未部署业务脚本（加 --deploy 可部署）")

    # 4) 核对基础表行数
    counts = {}
    for table in ["t_calendar", "t_bond_yield_curve_def",
                  "t_bond_info", "t_bond_day_kline"]:
        counts[table] = s.run(
            f'sum(exec count(*) from loadTable("dfs://caplib-bond","{table}") map)')
    print("\n初始化完成，基础表行数：")
    for t, n in counts.items():
        print(f"  {t:28} {n}")

    s.close()


if __name__ == "__main__":
    main()
