require("duckdb"):setup()
require("mime-ext.local"):setup({
	custom_only = false,
	fallback_file1 = false,
})
require("yafg"):setup({
	editor = "vim",
	file_arg_format = "+{row} {file}",
})
