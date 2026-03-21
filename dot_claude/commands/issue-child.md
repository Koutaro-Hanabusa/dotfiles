# 子Issue作成コマンド

ghコマンドで特定のissueを親とする子issueを作成するカスタムコマンド

## 基本コマンド

```bash
function create-child-issue
    set TITLE $argv[1]
    set PARENT_NUMBER $argv[2]
    set BODY $argv[3]
    
    if test -z "$TITLE" -o -z "$PARENT_NUMBER"
        echo "使用方法: create-child-issue \"タイトル\" PARENT_NUMBER [\"内容\"]"
        return 1
    end
    
    if test -z "$BODY"
        set BODY "親Issue: #$PARENT_NUMBER の子Issue"
    end
    
    # リポジトリ情報を取得
    set REPO_INFO (gh repo view --json owner,name)
    set OWNER (echo $REPO_INFO | jq -r '.owner.login')
    set REPO (echo $REPO_INFO | jq -r '.name')
    
    # 子Issueを作成
    set CHILD_ISSUE (gh issue create --title "$TITLE" --body "$BODY" --json number,url)
    set CHILD_NUMBER (echo $CHILD_ISSUE | jq -r '.number')
    set CHILD_URL (echo $CHILD_ISSUE | jq -r '.url')
    
    # 親Issueにコメントを追加
    gh issue comment $PARENT_NUMBER --body "子Issue作成: #$CHILD_NUMBER"
    
    # 子Issueに親へのリンクをコメント
    gh issue comment $CHILD_NUMBER --body "親Issue: #$PARENT_NUMBER"
    
    echo "親Issue: https://github.com/$OWNER/$REPO/issues/$PARENT_NUMBER"
    echo "作成した子Issue: $CHILD_URL"
end
```

## 使用例

```bash
create-child-issue "バグ修正: ログイン機能" 1276
create-child-issue "新機能: ダッシュボード改善" 1276 "詳細な説明"
```
