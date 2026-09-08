# This file should contain site-specific commands to be executed on Julia startup;
# Users may store their own personal commands in `~/.julia/config/startup.jl`.

using Pkg: Pkg

# 自动激活环境。优先使用当前项目，其次使用可覆盖的 dotfiles 根目录；
# 不把某台机器的绝对路径写进启动文件。
let project_dir = if isfile(joinpath(pwd(), "Project.toml"))
		pwd()
	elseif haskey(ENV, "DOTFILES_JULIA_BASE") && isfile(joinpath(ENV["DOTFILES_JULIA_BASE"], "Project.toml"))
		ENV["DOTFILES_JULIA_BASE"]
	else
		candidate = joinpath(get(ENV, "DOTFILES_ROOT", joinpath(homedir(), "dotfiles")), "julia", "base")
		isfile(joinpath(candidate, "Project.toml")) ? candidate : nothing
	end
	project_dir !== nothing && Pkg.activate(project_dir)
end

# 加载 base 环境
let base_tools = get(ENV, "DOTFILES_JULIA_BASE", joinpath(get(ENV, "DOTFILES_ROOT", joinpath(homedir(), "dotfiles")), "julia", "base"))
	if isfile(joinpath(base_tools, "Project.toml")) && !(base_tools in LOAD_PATH)
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
