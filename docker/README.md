# Caplib Docker 使用说明

这个目录面向 **最终使用者**，目标很简单：

- 自动下载 Caplib 插件发行包
- 自动准备 DolphinDB Server
- 构建并启动一个可直接连接的 Docker 环境

你不需要自己手动拼装 `libPluginCaplib.so`、`PluginCaplib.txt`、`libdqlibc.so`、`dqlibc.lic` 等文件。

## 适用场景

适合以下几类需求：

- 想快速验证插件是否能正常加载
- 想在本机得到一个独立的 DolphinDB + Caplib 运行环境
- 想用于演示、集成测试或内部试用

## 你会得到什么

构建完成后，容器内会包含：

- DolphinDB 3.00.5 Community Edition
- Caplib DolphinDB 插件
- `libdqlibc.so`
- `dqlibc.lic`
- `calendars.bin`

容器启动后默认监听：

- `8848`

## 使用前准备

请先确保本机具备：

- Docker
- `gh` 或 `GITHUB_TOKEN`
- 对 `CapRiskTech/caplib-plugin-dolphindb` 版本发布页的访问权限

如果你已经登录 GitHub CLI，可先确认：

```bash
gh auth status
```

## 快速开始

进入仓库目录：

```bash
cd caplib-plugin-dolphindb
```

### 只构建镜像

```bash
bash docker/build.sh
```

### 构建并启动容器

```bash
bash docker/build.sh --run
```

### 构建、启动并做基础验证

```bash
bash docker/build.sh --test
```

默认镜像名：

- `caplibdolphin:latest`

默认容器名：

- `caplibdolphin-test`（`--run` / `--test` 场景）

## 手动运行容器

如果镜像已经构建完成，也可以手动启动：

```bash
docker run -d -p 8848:8848 --name caplibdolphin caplibdolphin:latest
```

查看日志：

```bash
docker logs -f caplibdolphin
```

进入容器：

```bash
docker exec -it caplibdolphin bash
```

停止并删除容器：

```bash
docker stop caplibdolphin
docker rm caplibdolphin
```

## 从 DolphinDB / Python 连接

Python 示例：

```python
import dolphindb as ddb

s = ddb.session()
s.connect("localhost", 8848, "admin", "123456")

r = s.run("caplib::CalcYearFraction(2025.01.01, 2025.12.31, `ACTUAL_360)")
print(r)
```

如果你想手动加载插件，也可以执行：

```dolphindb
loadPlugin("/opt/ddb/server/plugins/caplib/PluginCaplib.txt")
```

## 使用自定义许可证

默认情况下，`build.sh` 会直接使用发行包中自带的 `dqlibc.lic`。

如果你需要替换为自己的许可证文件，可以这样执行：

```bash
DQLIBC_LICENSE_PATH=/path/to/dqlibc.lic bash docker/build.sh
```

## 发行包来源

`build.sh` 会自动下载以下内容：

- `CapRiskTech/caplib-plugin-dolphindb` 版本发布页中的插件压缩包
- DolphinDB 官方服务端压缩包

其中插件压缩包内已包含：

- `libPluginCaplib.so`
- `PluginCaplib.txt`
- `libdqlibc.so`
- `calendars.bin`
- `dqlibc.lic`

## 常用验证方式

### 1. 检查容器是否在运行

```bash
docker ps
```

### 2. 检查健康状态

```bash
docker inspect --format='{{.State.Health.Status}}' caplibdolphin
```

### 3. 查看 DolphinDB 日志

```bash
docker exec caplibdolphin tail -100 /opt/ddb/server/log/dolphindb.log
```

### 4. 运行容器内置测试脚本

在 DolphinDB 中执行：

```dolphindb
run("/opt/ddb/test_plugin.dos")
```

## 常见问题

### 无法下载版本发布资源

通常是 GitHub 权限或认证问题。先检查：

```bash
gh auth status
```

或者确认 `GITHUB_TOKEN` 是否具备 `repo` 权限。

### 端口 8848 无法连接

先检查容器是否正常启动：

```bash
docker ps
docker logs caplibdolphin
```

### 插件加载失败

建议优先看容器日志：

```bash
docker logs caplibdolphin
docker exec caplibdolphin tail -100 /opt/ddb/server/log/dolphindb.log
```

### 想重新构建

直接重新执行：

```bash
bash docker/build.sh
```

如果需要重新启动测试容器：

```bash
bash docker/build.sh --test
```
