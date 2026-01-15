#!/bin/bash

# ローカルのgitリポジトリをスキャンしてgh-dashのrepoPaths設定を自動更新するスクリプト
# Usage: ./generate-gh-dash-paths.sh [SCAN_DIR]

SCAN_DIR="${1:-$(pwd)}"
CONFIG_FILE="$HOME/.config/gh-dash/config.yml"

# 設定ファイルの存在確認
if [ ! -f "$CONFIG_FILE" ]; then
    echo "エラー: $CONFIG_FILE が見つかりません"
    exit 1
fi

echo "スキャン対象: $SCAN_DIR"

# 新しいrepoPathsを生成
NEW_PATHS="repoPaths:"
for dir in "$SCAN_DIR"/*/; do
    [ -d "$dir/.git" ] || continue
    remote=$(git -C "$dir" remote get-url origin 2>/dev/null) || continue
    [[ "$remote" == *github.com* ]] || continue

    repo_path=$(echo "$remote" | sed -E 's/.*github\.com[:/](.+)(\.git)?$/\1/' | sed 's/\.git$//')
    dir_path="${dir%/}"
    NEW_PATHS="$NEW_PATHS
    ${repo_path}: ${dir_path}"
done

# 設定ファイルを更新（repoPathsセクションを置換）
{
    in_repo_paths=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^repoPaths: ]]; then
            echo "$NEW_PATHS"
            in_repo_paths=1
        elif [[ $in_repo_paths -eq 1 && "$line" =~ ^[a-zA-Z] ]]; then
            in_repo_paths=0
            echo "$line"
        elif [[ $in_repo_paths -eq 0 ]]; then
            echo "$line"
        fi
    done < "$CONFIG_FILE"
} > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

echo "更新完了: $CONFIG_FILE"
echo ""
echo "$NEW_PATHS" | head -5
echo "    ..."
echo "(計 $(echo "$NEW_PATHS" | wc -l | tr -d ' ') リポジトリ)"
