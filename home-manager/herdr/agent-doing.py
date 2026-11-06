#!/usr/bin/env python3
"""Claude Code / Codex の hooks から呼ばれ、各エージェントの直近の作業を herdr のサイドバーに出す。

PreToolUse で「誰が何をしているか」を記録し、Stop / SubagentStop でその行を消す。
メインは agent_id なし、サブエージェントは agent_id で区別する（両 CLI 共通のフィールド）。
表示は pane metadata の $doing1..$doingN（config.toml の [ui.sidebar.agents] rows）。
"""

import fcntl
import json
import os
import socket
import sys

ROWS = 4  # config.toml の rows に並べた $doing 行の数
TTL_MS = 30 * 60 * 1000  # 落ちたセッションの表示が残り続けないように
KEYS = ("description", "file_path", "path", "pattern", "query", "url", "command", "cmd", "prompt", "skill")


def summarize(tool: str, args: object) -> str:
    """ツール名と、何をしているか一番伝わる引数1つ。Bash は command より description を優先。"""
    if not isinstance(args, dict):
        return tool
    for key in KEYS:
        v = args.get(key)
        if isinstance(v, list):
            v = " ".join(map(str, v))
        if isinstance(v, str) and v.strip():
            v = " ".join(v.split())
            if "/" in v and " " not in v:
                v = v.rstrip("/").rsplit("/", 1)[-1]  # パスはファイル名だけ
            return f"{tool} {v}"[:80]
    return tool


def apply(rows: dict, e: dict) -> dict:
    """フック1回分を行の表に反映する。キーはエージェント（メインは "main"）。"""
    agent = e.get("agent_id") or "main"
    event = e.get("hook_event_name")
    if event == "PreToolUse":
        doing = summarize(str(e.get("tool_name") or "?"), e.get("tool_input"))
        if agent == "main":
            rows[agent] = f"▸ {doing}"
        else:
            rows[agent] = f"↳ {e.get('agent_type') or agent[:6]}: {doing}"
    elif event in ("Stop", "SubagentStop"):
        rows.pop(agent, None)
    return rows


def tokens(rows: dict) -> dict:
    """行を $doing1..$doingN に割り当てる。溢れた分は最後の行に件数で出す。None はその行を消す。"""
    lines = sorted(rows.items(), key=lambda kv: kv[0] != "main")  # メインを先頭に
    texts = [text for _, text in lines]
    if len(texts) > ROWS:
        texts = texts[: ROWS - 1] + [f"  …他 {len(texts) - ROWS + 1} エージェント"]
    return {f"doing{i + 1}": (texts[i] if i < len(texts) else None) for i in range(ROWS)}


def report(pane: str, sock: str, toks: dict) -> None:
    req = {
        "id": "agent-doing",
        "method": "pane.report_metadata",
        "params": {"pane_id": pane, "source": "dotfiles:agent-doing", "tokens": toks, "ttl_ms": TTL_MS},
    }
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as c:
        c.settimeout(0.5)
        c.connect(sock)
        c.sendall((json.dumps(req) + "\n").encode())
        c.recv(4096)


def main() -> None:
    pane, sock = os.environ.get("HERDR_PANE_ID"), os.environ.get("HERDR_SOCKET_PATH")
    if not pane or not sock:
        return
    e = json.load(sys.stdin)
    state_dir = os.path.join(os.environ.get("TMPDIR", "/tmp"), "herdr-agent-doing")
    os.makedirs(state_dir, exist_ok=True)
    path = os.path.join(state_dir, pane.replace(":", "_") + ".json")
    # 並列サブエージェントのフックは同時に走る。読み・書き・送信を1つのロックで直列化し、
    # 終わったエージェントの行が古い書き込みで復活しないようにする。
    with open(path, "a+", encoding="utf-8") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        f.seek(0)
        try:
            rows = json.load(f)
        except ValueError:
            rows = {}
        rows = apply(rows, e)
        f.seek(0)
        f.truncate()
        json.dump(rows, f, ensure_ascii=False)
        f.flush()
        report(pane, sock, tokens(rows))


if __name__ == "__main__":
    if sys.argv[1:] == ["--test"]:
        r: dict = {}
        apply(r, {"hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": {"command": "git status", "description": "Show status"}})
        apply(r, {"hook_event_name": "PreToolUse", "agent_id": "a1", "agent_type": "Explore", "tool_name": "Read", "tool_input": {"file_path": "/x/y/z.ts"}})
        assert r == {"main": "▸ Bash Show status", "a1": "↳ Explore: Read z.ts"}, r
        apply(r, {"hook_event_name": "SubagentStop", "agent_id": "a1"})
        assert r == {"main": "▸ Bash Show status"}, r
        assert tokens(r) == {"doing1": "▸ Bash Show status", "doing2": None, "doing3": None, "doing4": None}
        many = {f"s{i}": f"x{i}" for i in range(6)}
        assert tokens(many)["doing4"] == "  …他 3 エージェント"
        apply(r, {"hook_event_name": "Stop"})
        assert r == {}
        print("ok")
        sys.exit(0)
    try:
        main()
    except Exception:
        pass  # 表示用なのでエージェント本体の動作は止めない
