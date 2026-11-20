#!/usr/bin/env python3
"""herdr のエージェント状態に合わせて、ペインの背景色を変える常駐プロセス（launchd から起動）。

作業中は緑、止まっている（完了・中断・許可待ち）は赤、エージェントがいなくなったら元に戻す。
状態は herdr 自身の検出（サイドバーのアイコンと同じ）を pane.updated で受け取るので、
Claude / Codex のどちらでも動き、hooks は要らない。色はペインの tty に OSC 11 を書いて変える。
herdr が止まると接続が切れて終了し、launchd（KeepAlive）が起動し直す。
"""

import json
import os
import select
import socket
import subprocess
import sys
import time

# Dragon の背景 #181616 から一目で分かり、文字も読める濃さ。好みで調整する。
COLORS = {"working": "#2A5232", "stopped": "#5A2328"}
HOLD = 1.5  # working から外れても、herdr の検出の一瞬の揺れで点滅しないようにこの秒数だけ待つ
SOCK = os.environ.get("HERDR_SOCKET_PATH") or os.path.expanduser("~/.config/herdr/herdr.sock")


def want(pane: dict) -> str | None:
    """ペインに付けたい色のキー。None は元の色（エージェントがいない）。"""
    if not pane.get("agent"):
        return None
    return "working" if pane.get("agent_status") == "working" else "stopped"


def due(shown: dict, target: dict, since: dict, now: float) -> dict:
    """今ペインに書くべき色を返す。一度も色を付けていないペインにはリセットを書かない。"""
    out = {}
    for p, t in target.items():
        if t == shown.get(p):
            continue
        if shown.get(p) == "working" and now - since[p] < HOLD:
            continue
        out[p] = t
    return out


def request(method: str, params: dict) -> dict:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as c:
        c.settimeout(2)
        c.connect(SOCK)
        c.sendall((json.dumps({"id": "agent-tint", "method": method, "params": params}) + "\n").encode())
        return json.loads(c.makefile().readline())["result"]


def find_tty(pane_id: str) -> str | None:
    """pane.process_info の tty は null のことがあるので、その場合はペインのシェルの tty を ps で引く。"""
    info = request("pane.process_info", {"pane_id": pane_id})["process_info"]
    tty = info.get("tty")
    if not tty and info.get("shell_pid"):
        tty = subprocess.run(["ps", "-o", "tty=", "-p", str(info["shell_pid"])], capture_output=True, text=True).stdout.strip()
    if not tty or tty.startswith("?"):
        return None
    return tty if tty.startswith("/") else "/dev/" + tty


def paint(path: str, key: str | None) -> None:
    seq = f"\033]11;{COLORS[key]}\007" if key else "\033]111\007"
    # launchd 配下なので制御端末を奪わないよう O_NOCTTY、^S で止まったペインで固まらないよう O_NONBLOCK。
    fd = os.open(path, os.O_WRONLY | os.O_NOCTTY | os.O_NONBLOCK)
    try:
        os.write(fd, seq.encode())
    finally:
        os.close(fd)


def main() -> None:
    shown: dict = {}
    target: dict = {}
    since: dict = {}
    ttys: dict = {}

    def see(pane: dict) -> None:
        p, t = pane["pane_id"], want(pane)
        if p not in target or target[p] != t:
            target[p], since[p] = t, time.monotonic()

    def forget(p: str) -> None:
        for d in (shown, target, since, ttys):
            d.pop(p, None)

    # 待機中のペインはイベントを出さないので、起動時に今の状態を一度全部拾う。
    for pane in request("pane.list", {})["panes"]:
        see(pane)
    c = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    c.connect(SOCK)
    subs = [{"type": "pane.updated"}, {"type": "pane.closed"}]
    c.sendall((json.dumps({"id": "agent-tint", "method": "events.subscribe", "params": {"subscriptions": subs}}) + "\n").encode())
    buf = b""
    while True:
        for p, key in due(shown, target, since, time.monotonic()).items():
            shown[p] = key
            try:
                if p not in ttys:
                    ttys[p] = find_tty(p)
                if ttys[p]:
                    paint(ttys[p], key)
            except (OSError, KeyError, ValueError):
                ttys.pop(p, None)  # ペインが消えた等。次の変化で引き直す
        if not select.select([c], [], [], HOLD / 3)[0]:
            continue
        chunk = c.recv(65536)
        if not chunk:
            sys.exit(1)  # herdr が止まった。launchd が起動し直す
        *lines, buf = (buf + chunk).split(b"\n")
        for line in lines:
            m = json.loads(line)
            data = m.get("data") or {}
            if m.get("event") == "pane_updated":
                see(data["pane"])
            elif m.get("event") == "pane_closed":
                forget(data["pane_id"])  # pane id が再利用されても古い tty に書かない


if __name__ == "__main__":
    if sys.argv[1:] == ["--test"]:
        assert want({"agent": "codex", "agent_status": "working"}) == "working"
        assert want({"agent": "claude", "agent_status": "idle"}) == "stopped"
        assert want({"agent": None, "agent_status": "unknown"}) is None
        shown, since = {"a": "working"}, {"a": 10.0, "b": 10.0, "c": 10.0}
        target = {"a": "stopped", "b": None, "c": "working"}
        assert due(shown, target, since, 10.5) == {"c": "working"}  # 揺れの間は赤にしない、素のシェルには書かない
        assert due(shown, target, since, 12.0) == {"a": "stopped", "c": "working"}
        assert due({"a": "stopped"}, {"a": None}, {"a": 10.0}, 10.0) == {"a": None}  # エージェント終了で即リセット
        print("ok")
        sys.exit(0)
    main()
