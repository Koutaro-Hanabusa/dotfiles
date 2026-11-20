#!/usr/bin/env python3
"""herdr のエージェント状態に合わせて、ペインの背景色を変える常駐プロセス（launchd から起動）。

作業中は緑、止まった（完了・中断・許可待ち）のにまだ見ていないペインは赤。
フォーカスしたら（見たら）赤を消し、エージェントがいなくなったら元に戻す。
状態は herdr 自身の検出（サイドバーのアイコンと同じ）を pane.list で読むので、
Claude / Codex のどちらでも動き、hooks は要らない。色はペインの tty に OSC 11 を書いて変える。
イベント購読だと取りこぼした変化で色が残るので、毎秒の一覧読みで常に今の状態に合わせる。
herdr が止まると例外で終了し、launchd（KeepAlive）が起動し直す。
"""

import json
import os
import socket
import subprocess
import sys
import time

# Dragon の背景 #181616 から一目で分かり、文字も読める濃さ。好みで調整する。
COLORS = {"working": "#2A5232", "stopped": "#5A2328"}
POLL = 1.0  # pane.list を読む間隔（秒）
HOLD = 1.5  # working から外れても、herdr の検出の一瞬の揺れで点滅しないようにこの秒数だけ待つ
UNKNOWN = "?"  # 起動直後のペイン。前のプロセスが付けた色が残っているかもしれないので必ず書き直す
SOCK = os.environ.get("HERDR_SOCKET_PATH") or os.path.expanduser("~/.config/herdr/herdr.sock")


def want(pane: dict, seen: set) -> str | None:
    """ペインに付けたい色のキー。None は元の色。seen は止まってからフォーカスされたペイン。"""
    p = pane["pane_id"]
    if not pane.get("agent"):
        return None
    if pane.get("agent_status") == "working":
        seen.discard(p)  # 次に止まったら、また見るまで赤
        return "working"
    if pane.get("focused"):
        seen.add(p)
    return None if p in seen else "stopped"


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
    seen: set = set()
    first = True
    while True:
        panes = {pane["pane_id"]: want(pane, seen) for pane in request("pane.list", {})["panes"]}
        now = time.monotonic()
        for p in list(target):
            if p not in panes:  # 閉じたペイン。pane id が再利用されても古い tty に書かない
                for d in (shown, target, since, ttys):
                    d.pop(p, None)
                seen.discard(p)
        for p, t in panes.items():
            if first:
                shown[p] = UNKNOWN
            if target.get(p, UNKNOWN) != t:
                target[p], since[p] = t, now
        first = False
        for p, key in due(shown, target, since, now).items():
            try:
                ttys[p] = ttys.get(p) or find_tty(p)
                if ttys[p]:
                    paint(ttys[p], key)
                elif key:
                    continue  # tty がまだ引けない。次の周回でやり直す
            except (OSError, KeyError, ValueError):
                ttys.pop(p, None)
                continue  # 書けなかったので shown を更新せず、次の周回でやり直す
            shown[p] = key
        time.sleep(POLL)


if __name__ == "__main__":
    if sys.argv[1:] == ["--test"]:
        seen: set = set()
        assert want({"pane_id": "x", "agent": "codex", "agent_status": "working"}, seen) == "working"
        assert want({"pane_id": "x", "agent": "claude", "agent_status": "idle"}, seen) == "stopped"
        assert want({"pane_id": "x", "agent": "claude", "agent_status": "idle", "focused": True}, seen) is None
        assert want({"pane_id": "x", "agent": "claude", "agent_status": "done"}, seen) is None  # 見た後は離れても赤にしない
        assert want({"pane_id": "x", "agent": "claude", "agent_status": "working"}, seen) == "working"
        assert want({"pane_id": "x", "agent": "claude", "agent_status": "idle"}, seen) == "stopped"  # 次の停止はまた赤
        assert want({"pane_id": "y", "agent": None, "agent_status": "unknown"}, seen) is None
        shown, since = {"a": "working"}, {"a": 10.0, "b": 10.0, "c": 10.0}
        target = {"a": "stopped", "b": None, "c": "working"}
        assert due(shown, target, since, 10.5) == {"c": "working"}  # 揺れの間は赤にしない、素のシェルには書かない
        assert due(shown, target, since, 12.0) == {"a": "stopped", "c": "working"}
        assert due({"a": "stopped"}, {"a": None}, {"a": 10.0}, 10.0) == {"a": None}  # エージェント終了で即リセット
        assert due({"a": UNKNOWN}, {"a": None}, {"a": 10.0}, 10.0) == {"a": None}  # 起動直後は残った色を消す
        print("ok")
        sys.exit(0)
    main()
