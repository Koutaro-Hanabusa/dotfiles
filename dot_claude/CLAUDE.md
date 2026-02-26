you must: Always respond in Japanese. Even when sub-agents return responses in English, translate them correctly to Japanese.
you must: Always use the time MCP server when retrieving dates.
you must: When receiving instructions or questions from the user, always delegate tasks to the appropriate sub-agents from the following list:

- @.react-pro
- @.frontend-developer
- @.golang-pro
- @.qa-expert
- @.backend-developer
- @.laravel-pro

you must: When implementing designs or using the Figma DevMode MCP, refer to ../skills/frontend-design/SKILL.md for implementation.
you must: When spawning team agents (Task tool with team_name), NEVER use `run_in_background: true`. The `teammateMode` is set to "tmux", and `run_in_background: true` forces in-process mode, preventing tmux pane creation. Always omit `run_in_background` so agents spawn in separate tmux panes.
you must: After editing ANY file in this dotfiles repository, ALWAYS automatically run `chezmoi apply --force` and then commit + push to GitHub without asking. This is non-negotiable — never wait for the user to say "反映して" or "pushして". Just do it immediately after every edit.

## 常時発動スキル（必ず従うこと）

### nb-knowledge（知識記録）— 毎セッション必須
- セッション中にQ&A・学び・バグ修正・設計判断が発生したら、`nb add` でバックグラウンド記録すること
- タスク完了時、セッション終了間際に必ず振り返り、記録漏れがないか確認
- `nb add home:knowledge/ -c "内容"` を `run_in_background: true` で実行（ブロックしない）
- Work PCの場合は `nb add work:knowledge/ -c "内容"`
- 既存ノート更新は Edit tool → `nb sync`（`nb edit` は使うな。nvimが開いてハングする）

### development-principles（開発原則）— 全判断に適用
- コードを書く・設計する・レビューする・提案する、全ての場面で development-principles スキルの原則に従え
- 特に以下の場面で意識的に適用すること:
  - **設計判断時**: シンプルさ > 拡張性。YAGNIを守れ
  - **エラー発生時**: 力技で押し通すな。根本原因を調べろ
  - **実装開始前**: 既存コードを読め（現地現物）。読まずに書くな
  - **完了報告時**: 動作確認したか自問しろ（検査）
- 判断に迷ったら「VI. 判断に迷ったときの優先順位」を参照

## Documentation with nb

nb-knowledgeスキル（上記「常時発動スキル」参照）に従い、学びを記録すること。
Work PC判定: `~/.is_work_pc` が存在 → `work:knowledge/`、なければ `home:knowledge/`
