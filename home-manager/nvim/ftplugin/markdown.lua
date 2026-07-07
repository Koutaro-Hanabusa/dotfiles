-- マークダウンでリストを自動継続
-- 改行時に - や * や 1. などを自動挿入

-- formatoptions の設定
-- r: Enterキーで改行時にコメント文字を自動挿入
-- o: o/Oで新行作成時にコメント文字を自動挿入
vim.opt_local.formatoptions:append("r")
vim.opt_local.formatoptions:append("o")

-- マークダウンのリスト記号をコメントとして認識させる
vim.opt_local.comments = "b:-,b:*,b:+,b:1."

vim.api.nvim_buf_create_user_command(0, "Md", function()
	if vim.fn.executable("glow") == 0 then
		vim.notify("glow が利用できません", vim.log.levels.WARN)
		return
	end

	vim.cmd("!" .. "glow -p " .. vim.fn.shellescape(vim.fn.expand("%:p")))
end, { desc = "Preview markdown with glow" })
