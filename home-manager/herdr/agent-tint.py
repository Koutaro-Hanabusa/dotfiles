#!/usr/bin/env python3
"""herdr のエージェント状態に合わせて、ペインの背景色を変える常駐プロセス（launchd から起動）。

作業中は緑、止まった（完了・中断・許可待ち）のにまだ見ていないペインは赤。
フォーカスして（見て）赤を消し、エージェントがいなくなったら元に戻す。
herdr サイドバーのエージェント行にも、印（🔄/❗）と同じ色の文字を pane metadata の
$tint_mark / $tint_<色キー>_label で出す（config.toml）。
状態は herdr 自身の検出（サイドバーのアイコンと同じ）を session.snapshot で読むので、
Claude / Codex のどちらでも動き、hooks は要らない。色はペインの tty に OSC 11 を書いて変える。
イベント購読だと取りこぼした変化で色が残るので、毎秒のスナップショットで常に今の状態に合わせる。
herdr が止まると例外で終了し、launchd（KeepAlive）が起動し直す。
"""

import functools
import json
import os
import signal
import socket
import subprocess
import sys
import time

# Dragon の背景 #181616 から一目で分かり、文字も読める濃さ。好みで調整する。
COLORS = {"working": "#2A5232", "stopped": "#5A2328"}
POLL = 1.0  # スナップショットを読む間隔（秒）
HOLD = 1.5  # working から外れても、herdr の検出の一瞬の揺れで点滅しないようにこの秒数だけ待つ
UNKNOWN = "?"  # 起動直後のペイン。前のプロセスが付けた色が残っているかもしれないので必ず書き直す
# サイドバーの印（絵文字）と、エージェント名の横に出す文字。文字の色は config.toml 側で付ける。
MARKS = {"working": "🔄", "stopped": "❗"}  # 並ぶと色だけでは見分けにくいので形も変える
LABELS = {"working": "作業中", "stopped": "未確認"}
TERMINAL = "com.mitchellh.ghostty"  # herdr を映しているターミナルの bundle id
SOCK = os.environ.get("HERDR_SOCKET_PATH") or os.path.expanduser("~/.config/herdr/herdr.sock")


def terminal_in_front() -> bool:
    """herdr を映すターミナルが最前面か。別アプリを見ている間の herdr 上のフォーカスは「見た」に数えない。"""
    asn = subprocess.run(["lsappinfo", "front"], capture_output=True, text=True).stdout.strip()
    info = subprocess.run(["lsappinfo", "info", "-only", "bundleid", asn], capture_output=True, text=True).stdout
    return f'"{TERMINAL}"' in info


def want(agent: dict | None, seen: dict, front) -> str | None:
    """ペインに付けたい色のキー。None は元の色。agent は snapshot の agents の要素（いなければ None）。

    seen は「止まってから見た」ときの state_change_seq。毎秒の読みが短い作業を取りこぼしても、
    seq が進んでいれば新しい停止なので、また見るまで赤にする。
    """
    if not agent:
        return None
    if agent.get("agent_status") == "working":
        return "working"
    p, seq = agent["pane_id"], agent.get("state_change_seq")
    if seen.get(p, UNKNOWN) != seq and agent.get("focused") and front():
        seen[p] = seq
    return None if seen.get(p, UNKNOWN) == seq else "stopped"


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


def report(pane_id: str, key: str | None) -> None:
    """サイドバー用の印と文字。色キーに対応する文字のトークンだけに値を入れ、他は None で消す。"""
    tokens = {"tint_mark": MARKS.get(key)}
    for k in COLORS:
        tokens[f"tint_{k}_label"] = LABELS[k] if k == key else None
    request("pane.report_metadata", {"pane_id": pane_id, "source": "dotfiles:agent-tint", "tokens": tokens})


def main() -> None:
    # 背景色（shown）とサイドバーの印（marked）は別々に失敗しうるので、実際に書けた状態を別々に持つ。
    shown: dict = {}
    marked: dict = {}
    target: dict = {}
    since: dict = {}
    ttys: dict = {}
    seen: dict = {}
    first = True

    def tint(p: str, key: str | None) -> None:
        try:
            ttys[p] = ttys.get(p) or find_tty(p)
            if not ttys[p]:
                raise OSError(f"{p} の tty が見つからない")
            paint(ttys[p], key)
        except OSError:
            ttys.pop(p, None)  # 次は tty を引き直す
            raise

    outputs = ((shown, tint), (marked, report))
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))  # finally で色を戻してから終わる
    try:
        while True:
            snap = request("session.snapshot", {})["snapshot"]
            agents = {a["pane_id"]: a for a in snap["agents"]}
            if first:
                # 起動前に止まったものは見たかどうか分からない。全部赤にすると本当の未確認が埋もれるので、見た扱いにする。
                seen.update({p: a.get("state_change_seq") for p, a in agents.items() if a.get("agent_status") != "working"})
            front = functools.cache(terminal_in_front)  # 必要になった周回だけ、1回だけ調べる
            panes = {pane["pane_id"]: want(agents.get(pane["pane_id"]), seen, front) for pane in snap["panes"]}
            now = time.monotonic()
            for p in list(target):
                if p not in panes:  # 閉じたペイン。pane id が再利用されても古い tty に書かない
                    for d in (shown, marked, target, since, ttys, seen):
                        d.pop(p, None)
            for p, t in panes.items():
                if first:
                    shown[p] = marked[p] = UNKNOWN
                if target.get(p, UNKNOWN) != t:
                    target[p], since[p] = t, now
            first = False
            for state, write in outputs:
                for p, key in due(state, target, since, now).items():
                    try:
                        write(p, key)
                    except (OSError, KeyError, ValueError):
                        continue  # その出力だけ、書けるまで次の周回でやり直す（ペインが閉じれば止む）
                    state[p] = key
            time.sleep(POLL)
    finally:
        # launchctl での停止や設定から外したときに、付けた色を残さない。
        for state, write in outputs:
            for p, key in state.items():
                if key in COLORS:
                    try:
                        write(p, None)
                    except (OSError, KeyError, ValueError):
                        pass


if __name__ == "__main__":
    if sys.argv[1:] == ["--test"]:
        seen: dict = {}
        yes, no = (lambda: True), (lambda: False)

        def a(status: str, seq: int, focused: bool = False) -> dict:
            return {"pane_id": "x", "agent": "claude", "agent_status": status, "state_change_seq": seq, "focused": focused}

        assert want(a("working", 1), seen, yes) == "working"
        assert want(a("idle", 2), seen, yes) == "stopped"  # フォーカスなし
        assert want(a("idle", 2, focused=True), seen, no) == "stopped"  # 別アプリを見ている
        assert want(a("idle", 2, focused=True), seen, yes) is None  # 見た
        assert want(a("idle", 2), seen, yes) is None  # 見た後は離れても赤にしない
        assert want(a("idle", 4), seen, yes) == "stopped"  # 読み逃した短い作業の後の停止はまた赤
        assert want(None, seen, yes) is None
        shown, since = {"a": "working"}, {"a": 10.0, "b": 10.0, "c": 10.0}
        target = {"a": "stopped", "b": None, "c": "working"}
        assert due(shown, target, since, 10.5) == {"c": "working"}  # 揺れの間は赤にしない、素のシェルには書かない
        assert due(shown, target, since, 12.0) == {"a": "stopped", "c": "working"}
        assert due({"a": "stopped"}, {"a": None}, {"a": 10.0}, 10.0) == {"a": None}  # エージェント終了で即リセット
        assert due({"a": UNKNOWN}, {"a": None}, {"a": 10.0}, 10.0) == {"a": None}  # 起動直後は残った色を消す
        assert terminal_in_front() in (True, False)
        print("ok")
        sys.exit(0)
    main()
