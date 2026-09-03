#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
run_tests.py

Copy the DolphinDB test suite (test/*.dos) into the caplib docker container and
run it through the native DolphinDB test() framework, relaying per-case output
and the final pass/fail summary. Sets the process exit code for CI/scripting
(0 = all passed, 1 = any failure or error).

Usage:
    python run_tests.py                                   # all 8 test files
    python run_tests.py --file test_validation.dos        # a single file
    python run_tests.py --container my-container          # custom container
    python run_tests.py --skip-copy                       # files already staged
    python run_tests.py --host 192.168.1.10 --port 8848   # non-default host

Requires: the `dolphindb` python package (pip install dolphindb) and the docker CLI.
"""
import argparse
import os
import re
import socket
import subprocess
import sys
import time

DEFAULT_CONTAINER = "caplibdolphin-test"
DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 8848
DEFAULT_USER = "admin"
DEFAULT_PASSWORD = "123456"
DEFAULT_REMOTE_DIR = "/data/ddb/test"

REPO_ROOT = os.path.dirname(os.path.abspath(__file__))
DEFAULT_LOCAL_DIR = os.path.join(REPO_ROOT, "test")


def sh(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def container_running(container):
    r = sh(["docker", "ps", "--format", "{{.Names}}"])
    return container in r.stdout.split()


def container_exists(container):
    r = sh(["docker", "ps", "-a", "--format", "{{.Names}}"])
    return container in r.stdout.split()


def ensure_container(container):
    if container_running(container):
        return True
    if container_exists(container):
        print(f"-> Container '{container}' exists but is stopped; starting it...")
        r = sh(["docker", "start", container])
        if r.returncode != 0:
            print(f"FATAL: docker start failed: {r.stderr.strip()}")
            return False
        return True
    print(f"FATAL: container '{container}' not found.")
    print("  Build/run it first, e.g.:  bash docker/build.sh --run")
    return False


def stage_files(container, local_dir, remote_dir):
    print(f"-> Staging {local_dir}/*.dos -> {container}:{remote_dir}/")
    r = sh(["docker", "exec", container, "mkdir", "-p", remote_dir])
    if r.returncode != 0:
        print(f"FATAL: docker exec mkdir failed: {r.stderr.strip()}")
        return False
    r = sh(["docker", "cp", os.path.join(local_dir, "."), f"{container}:{remote_dir}/"])
    if r.returncode != 0:
        print(f"FATAL: docker cp failed: {r.stderr.strip()}")
        return False
    print("-> Staged.")
    return True


def wait_ready(host, port, timeout=90):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with socket.create_connection((host, port), timeout=3):
                return True
        except OSError:
            time.sleep(2)
    return False


def run_tests(host, port, user, password, remote_dir, single_file):
    try:
        import dolphindb as ddb
    except ImportError:
        print(f"FATAL: 'dolphindb' python package not installed in: {sys.executable}")
        print(f'  Install it with:  {sys.executable} -m pip install dolphindb')
        return None, False

    target = f"{remote_dir}/{single_file}" if single_file else remote_dir
    s = ddb.session()
    s.connect(host, port, user, password)
    print(f"-> Running test(\"{target}\") ...")
    result = s.run(f'test("{target}")')
    result = result or ""
    print(result)
    m = re.search(r"#Fail/#Total Testing Cases:\s*(\d+)/(\d+)", result)
    if not m:
        print("WARN: could not parse the test summary from the output above.")
        return None, False
    fail, total = int(m.group(1)), int(m.group(2))
    return (total - fail, fail), True


def main():
    ap = argparse.ArgumentParser(description="Run the caplib DolphinDB test suite inside the docker container.")
    ap.add_argument("--container", default=DEFAULT_CONTAINER, help="docker container name (default: caplibdolphin-test)")
    ap.add_argument("--host", default=DEFAULT_HOST)
    ap.add_argument("--port", type=int, default=DEFAULT_PORT)
    ap.add_argument("--user", default=DEFAULT_USER)
    ap.add_argument("--password", default=DEFAULT_PASSWORD)
    ap.add_argument("--local-dir", default=DEFAULT_LOCAL_DIR, help="local test/ directory to stage (default: <repo>/test)")
    ap.add_argument("--remote-dir", default=DEFAULT_REMOTE_DIR, help="server-side test directory (default: /data/ddb/test)")
    ap.add_argument("--file", default=None, help="run a single file, e.g. test_validation.dos")
    ap.add_argument("--skip-copy", action="store_true", help="skip docker cp (files already staged in the container)")
    args = ap.parse_args()

    if not args.skip_copy:
        if not ensure_container(args.container):
            sys.exit(1)
        if not stage_files(args.container, args.local_dir, args.remote_dir):
            sys.exit(1)

    print(f"-> Waiting for DolphinDB at {args.host}:{args.port} ...")
    if not wait_ready(args.host, args.port):
        print("FATAL: DolphinDB did not become reachable in time.")
        sys.exit(1)

    try:
        summary, parsed = run_tests(args.host, args.port, args.user, args.password,
                                    args.remote_dir, args.file)
    except Exception as e:
        print(f"FATAL: test run failed: {e}")
        sys.exit(1)

    if not parsed:
        sys.exit(1)
    passed, failed = summary
    if failed == 0:
        print(f"-> PASSED {passed}/{passed}")
    else:
        print(f"-> FAILED {failed} / total {passed + failed}")
    sys.exit(1 if failed > 0 else 0)


if __name__ == "__main__":
    main()
