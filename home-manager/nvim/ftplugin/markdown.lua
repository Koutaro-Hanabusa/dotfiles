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

-- :Er - markdown 内の ```mermaid ブロックを mmdc で PNG 化し macOS の
-- デフォルトビューア (Preview.app) で開く。image.nvim の inline 描画は
-- Ghostty + Kitty プロトコルでの相性問題で escape sequence が漏れるため
-- 外部プレビューに寄せた実装。
vim.api.nvim_buf_create_user_command(0, "Er", function()
	if vim.fn.executable("mmdc") == 0 then
		vim.notify("mmdc (mermaid-cli) が PATH にありません", vim.log.levels.ERROR)
		return
	end

	-- treesitter で fenced code block を抽出 (diagram.nvim と同じ query)
	local ok_parser, parser = pcall(vim.treesitter.get_parser, 0, "markdown")
	if not ok_parser or not parser then
		vim.notify("markdown treesitter parser がありません (:TSInstall markdown)", vim.log.levels.ERROR)
		return
	end
	parser:parse(true)
	local root = parser:parse()[1]:root()
	local query = vim.treesitter.query.parse(
		"markdown",
		"(fenced_code_block (info_string) @info (code_fence_content) @code)"
	)

	local blocks = {}
	local current_lang = nil
	for id, node in query:iter_captures(root, 0) do
		local key = query.captures[id]
		local text = vim.treesitter.get_node_text(node, 0)
		if key == "info" then
			current_lang = text
		elseif current_lang == "mermaid" then
			table.insert(blocks, text)
			current_lang = nil
		end
	end

	if #blocks == 0 then
		vim.notify("mermaid ブロックが見つかりません", vim.log.levels.WARN)
		return
	end

	-- PUPPETEER_EXECUTABLE_PATH は home.sessionVariables 経由で入る想定だが、
	-- 既存シェルから起動された nvim では未設定の可能性があるので二重保険。
	if vim.env.PUPPETEER_EXECUTABLE_PATH == nil or vim.env.PUPPETEER_EXECUTABLE_PATH == "" then
		vim.env.PUPPETEER_EXECUTABLE_PATH = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
	end

	local basename = vim.fn.expand("%:t:r")
	local paths = {}
	for i, source in ipairs(blocks) do
		-- 予測可能な path (毎回同じ) にすることで Preview.app 側で再読込されやすい
		local src_path = ("/tmp/mermaid_%s_%d.mmd"):format(basename, i)
		local png_path = ("/tmp/mermaid_%s_%d.png"):format(basename, i)
		vim.fn.writefile(vim.split(source, "\n"), src_path)
		local result = vim.system({ "mmdc", "-i", src_path, "-o", png_path }, { text = true }):wait()
		if result.code ~= 0 then
			vim.notify(("block #%d render 失敗:\n%s"):format(i, result.stderr or ""), vim.log.levels.ERROR)
		else
			table.insert(paths, png_path)
		end
	end

	if #paths == 0 then return end
	vim.system({ "open", unpack(paths) }, { detach = true })
	vim.notify(("mermaid %d block を Preview.app で開いた: %s"):format(#paths, table.concat(paths, ", ")), vim.log.levels.INFO)
end, { desc = "Preview mermaid blocks with Preview.app" })
