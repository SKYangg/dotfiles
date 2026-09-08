#!/bin/sh
set -eu
# CoC starts us in the Julia file's directory; select its nearest project.
project_dir=$PWD
while [ ! -f "$project_dir/Project.toml" ] && [ ! -f "$project_dir/JuliaProject.toml" ]; do
    if [ "$project_dir" = / ]; then
        echo 'Julia language server: no Project.toml or JuliaProject.toml found.' >&2
        exit 1
    fi
    project_dir=$(dirname "$project_dir")
done
tool_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ ! -f "$tool_dir/Manifest.toml" ]; then
    echo 'Julia language server: tool environment is not installed; see the Vim manual.' >&2
    exit 1
fi
# Exact runtime; no installation, updates, or default-channel fallback at startup.
export JULIA_LOAD_PATH='@:@stdlib'
export JULIA_DEPOT_PATH="$HOME/.julia:"
exec julia +1.12.7 --startup-file=no --history-file=no --threads=1 \
    --project="$tool_dir" -e '
using Pkg, TOML, LanguageServer
project_dir = only(ARGS)
project_file = isfile(joinpath(project_dir, "JuliaProject.toml")) ? joinpath(project_dir, "JuliaProject.toml") : joinpath(project_dir, "Project.toml")
compat = get(get(TOML.parsefile(project_file), "compat", Dict()), "julia", nothing)
if compat !== nothing && !(VERSION in Pkg.Types.semver_spec(compat))
    error("Julia language server runtime $(VERSION) does not satisfy project compat $(compat)")
end
println(stderr, "Vim Julia LSP: runtime=", VERSION, " project=", project_dir)
runserver(stdin, stdout, project_dir)
'  "$project_dir"
