# This file should contain site-specific commands to be executed on Julia startup;
# Users may store their own personal commands in `~/.julia/config/startup.jl`.

using Pkg: Pkg

# 自动激活环境
isfile("Project.toml") && isfile("Manifest.toml") ? Pkg.activate(".") : Pkg.activate(expanduser("~/dotfiles/julia/base"))

# 加载 base 环境
let base_tools = expanduser("~/dotfiles/julia/base")
	if isdir(base_tools) && !(base_tools in LOAD_PATH)
		pushfirst!(LOAD_PATH, base_tools)
	end
end

atreplinit() do repl

	try
		@eval using Revise
	catch e
		@warn "error while importing Revise" e
	end

	try
		@eval using OhMyREPL
		@eval colorscheme!("BoxyMonokai256")
	catch e
		@warn "error while importing OhMyREPL" e

	end
end
# 南大源
get!(ENV, "JULIA_PKG_SERVER", "https://mirrors.nju.edu.cn/julia/")
