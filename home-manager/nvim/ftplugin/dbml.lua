-- DBML ftplugin: render サブコマンドで SVG を生成し macOS Preview.app で開く。
-- image.nvim による inline 描画は Ghostty との相性で escape sequence が
-- 漏れる問題があるため外部プレビューに寄せた実装。
--
-- 前提: dbml-language-server が PATH に存在 (home.nix で dbmlLspPkg 追加済み)。

vim.bo.commentstring = "// %s"

vim.api.nvim_buf_create_user_command(0, "Er", function()
	local input = vim.fn.expand("%:p")
	if input == "" then
		vim.notify("バッファが未保存", vim.log.levels.ERROR)
		return
	end

	-- 予測可能な path に出す (毎回同じ場所なので再読込しやすい)
	local basename = vim.fn.expand("%:t:r")
	local svg_path = ("/tmp/dbml_%s.svg"):format(basename)
	local html_path = ("/tmp/dbml_%s.html"):format(basename)
	-- dbml-renderer (viz.js ベース) を使用
	local result = vim.system({ "dbml-renderer", "-i", input, "-o", svg_path }, { text = true }):wait()
	if result.code ~= 0 then
		vim.notify("dbml render 失敗: " .. (result.stderr or "unknown"), vim.log.levels.ERROR)
		return
	end

	-- viz.js の SVG は固定 px の width/height を持つので Preview.app / 直開き
	-- だと原寸表示になり巨大になる。HTML でラップしてブラウザで開くことで
	-- viewport にフィットさせる (pinch/scroll でパン・ズームも可能)。
	local svg = table.concat(vim.fn.readfile(svg_path), "\n")
	local html = ([[<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>%s</title>
<style>
  html, body { margin: 0; padding: 0; height: 100%%; background: #1a1a1a; }
  body { display: flex; align-items: center; justify-content: center; }
  svg { max-width: 100vw; max-height: 100vh; width: auto; height: auto; }
</style>
</head>
<body>
%s
</body>
</html>]]):format(basename, svg)
	vim.fn.writefile(vim.split(html, "\n"), html_path)

	vim.system({ "open", html_path }, { detach = true })
	vim.notify(("ブラウザで開いた: %s"):format(html_path), vim.log.levels.INFO)
end, { desc = "DBML: preview ER diagram (open externally)" })
