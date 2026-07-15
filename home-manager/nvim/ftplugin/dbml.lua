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

	local output = vim.fn.tempname() .. "-" .. vim.fn.expand("%:t:r") .. ".svg"
	local result = vim.system({ "dbml-language-server", "render", input, "-o", output }, { text = true }):wait()
	if result.code ~= 0 then
		vim.notify("dbml render 失敗: " .. (result.stderr or "unknown"), vim.log.levels.ERROR)
		return
	end

	vim.system({ "open", output }, { detach = true })
	vim.notify("Preview.app で開きました", vim.log.levels.INFO)
end, { desc = "DBML: preview ER diagram (open externally)" })
