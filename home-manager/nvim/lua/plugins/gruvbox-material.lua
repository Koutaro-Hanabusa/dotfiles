return {
  "sainnhe/gruvbox-material",
  lazy = false,
  priority = 1000,
  config = function()
    -- hard / medium / soft。medium が 1980s レトロな暖色トーンの標準。
    vim.g.gruvbox_material_background = "medium"
    -- material: 低彩度で目に優しい。original はオリジナル gruvbox の高彩度。
    vim.g.gruvbox_material_foreground = "material"
    -- 区切り線・行番号などの UI パーツを目立たせない
    vim.g.gruvbox_material_ui_contrast = "low"
    -- 浮動ウィンドウは背景を暗くするだけにして枠の主張を抑える
    vim.g.gruvbox_material_float_style = "dim"
    -- diagnostic を下線ではなく色付き文字で出す（波線だらけの IDE 感を避ける）
    vim.g.gruvbox_material_diagnostic_virtual_text = "colored"
    -- ハイライトを事前生成してカラースキーム適用を高速化
    vim.g.gruvbox_material_better_performance = 1

    vim.cmd.colorscheme("gruvbox-material")
  end,
}
