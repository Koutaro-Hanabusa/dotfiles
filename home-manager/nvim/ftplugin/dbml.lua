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

	-- 予測可能な path に出す (毎回同じ場所なので Preview.app 側で再読込されやすい)
	local output = ("/tmp/dbml_%s.svg"):format(vim.fn.expand("%:t:r"))
	-- dbml-renderer (viz.js ベース) を使用。自作 render より綺麗な SVG を生成
	local result = vim.system({ "dbml-renderer", "-i", input, "-o", output }, { text = true }):wait()
	if result.code ~= 0 then
		vim.notify("dbml render 失敗: " .. (result.stderr or "unknown"), vim.log.levels.ERROR)
		return
	end

	vim.system({ "open", output }, { detach = true })
	vim.notify(("Preview.app で開いた: %s"):format(output), vim.log.levels.INFO)
end, { desc = "DBML: preview ER diagram (open externally)" })
