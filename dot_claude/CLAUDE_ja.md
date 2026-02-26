you must: 回答は必ず日本語で行う。サブエージェントから英語で回答が返ってきた場合も正しく日本語に翻訳すること。
you must: 日付を取得するときは必ず time MCP server を使用すること。
you must: ユーザーから指示や質問を受けた際は、必ず以下のリストから適切なサブエージェントにタスクを委譲すること:

- @.react-pro
- @.frontend-developer
- @.golang-pro
- @.qa-expert
- @.backend-developer
- @.laravel-pro

you must: デザインの実装や Figma DevMode MCP を使用する際は、../skills/frontend-design/SKILL.md を参照して実装すること。
you must: チームエージェント起動時（Task tool + team_name）に `run_in_background: true` を絶対に使わないこと。`teammateMode` が "tmux" に設定されており、`run_in_background: true` だと in-process モードになり tmux ペインが作成されない。常に `run_in_background` を省略すること。
you must: このdotfilesリポジトリのファイルを編集した後は、必ず自動で `chezmoi apply --force` → commit → push を実行すること。ユーザーの「反映して」「pushして」を待つな。編集後即座にやれ。

## 常時発動スキル（必ず従うこと）

### nb-knowledge（知識記録）— 毎セッション必須
- セッション中に Q&A・学び・バグ修正・設計判断が発生したら、`nb add` でバックグラウンド記録すること
- タスク完了時・セッション終了間際に必ず振り返り、記録漏れがないか確認
- `nb add home:knowledge/ -c "内容"` を `run_in_background: true` で実行（メイン会話をブロックしない）
- Work PC の場合は `nb add work:knowledge/ -c "内容"`
- 既存ノート更新は Edit tool で直接編集 → `nb sync`（`nb edit` は使うな。nvim が開いてハングする）

### development-principles（開発原則）— 全判断に適用
- コードを書く・設計する・レビューする・提案する、全ての場面で development-principles スキルの原則に従え
- 特に以下の場面で意識的に適用すること:
  - **設計判断時**: シンプルさ > 拡張性。YAGNI を守れ
  - **エラー発生時**: 力技で押し通すな。根本原因を調べろ
  - **実装開始前**: 既存コードを読め（現地現物）。読まずに書くな
  - **完了報告時**: 動作確認したか自問しろ（検査）
- 判断に迷ったら「VI. 判断に迷ったときの優先順位」を参照

## nb によるドキュメント管理

nb-knowledge スキル（上記「常時発動スキル」参照）に従い、学びを記録すること。
Work PC 判定: `~/.is_work_pc` が存在 → `work:knowledge/`、なければ `home:knowledge/`
