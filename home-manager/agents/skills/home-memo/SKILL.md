---
name: home-memo
description: Koutaro の home・個人ノートを指定して検索する依頼に使う。検索先未指定や home/work 横断の過去参照は knowledges を使う。
---

# Home Memo

`/home-memo`、「home-memo で調べて」、「個人ノートから探して」などで home ノートを読む。`mcp__home-memo__search_knowledge` に短い検索語を渡し、必要な候補と原典を確認する。概念・言い換えは意味検索、完全一致・網羅はローカルノートが使えるなら `kb search` を選ぶ。結果には `home/knowledge/xxx.md` の原典と古さを示し、見つからない・検索不能な場合も伝える。書き込みは明示された依頼がある場合だけ行う。検索先の判断や手段を詳しく選ぶ必要がある場合だけ [knowledges](../knowledges/SKILL.md) を読む。
