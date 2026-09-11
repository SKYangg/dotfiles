#!/usr/bin/env bash
# Minimal regression suite for the VimTeX-backed LaTeX build wrapper.
#
# Runs from any working directory. Builds a throwaway LaTeX fixture in a
# temporary workspace, drives the real vim configuration headlessly, and prints
# a PASS/FAIL summary. Test outputs/caches stay in temporary storage; no real project
# is compiled and no PDF viewer is opened.
#
# Usage:
#   vim/tests/run-latex-build-tests.sh [--workspace DIR] [--keep] [--timeout S]
#
# Exit status: 0 when every case passed, 1 on any failure, 2 on missing
# dependencies or harness errors. Missing dependencies are reported as errors,
# never silently skipped.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
VIMRC="${REPO_ROOT}/vim/.vimrc"
CASES="${SCRIPT_DIR}/latex-build-cases.vim"

WORKSPACE=""
KEEP=0
VIM_TIMEOUT=420

die() { printf 'error: %s\n' "$*" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace) [[ $# -ge 2 ]] || die "--workspace needs a value"; WORKSPACE="$2"; shift 2 ;;
    --keep)      KEEP=1; shift ;;
    --timeout)   [[ $# -ge 2 ]] || die "--timeout needs a value"; VIM_TIMEOUT="$2"; shift 2 ;;
    -h|--help)   sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)           die "unknown argument: $1" ;;
  esac
done

[[ "${VIM_TIMEOUT}" =~ ^[1-9][0-9]*$ ]] || die "--timeout must be a positive integer"

# --- dependency checks -------------------------------------------------------
missing=()
for tool in vim latexmk pdflatex; do
  command -v "${tool}" >/dev/null 2>&1 || missing+=("${tool}")
done
[[ -f "${VIMRC}" ]] || missing+=("${VIMRC}")
[[ -f "${CASES}" ]] || missing+=("${CASES}")
if [[ ${#missing[@]} -gt 0 ]]; then
  printf 'error: missing dependencies: %s\n' "${missing[*]}" >&2
  exit 2
fi
if ! vim --version | grep -q '+clientserver'; then
  echo "error: this vim lacks +clientserver (needed by the TeX server autocmd)" >&2
  exit 2
fi
for plugin in vimtex; do
  [[ -d "${HOME}/.vim/plugged/${plugin}" ]] \
    || die "plugin not installed: ~/.vim/plugged/${plugin} (run :PlugInstall)"
done

# VimTeX is pinned to v2.15 in vim/.vimrc. The plugin exposes no version
# variable, so the checkout itself is the only observable source.
VIMTEX_PIN="v2.15"
vimtex_desc="$(git -C "${HOME}/.vim/plugged/vimtex" describe --tags 2>/dev/null || echo unknown)"
vimtex_sha="$(git -C "${HOME}/.vim/plugged/vimtex" rev-parse HEAD 2>/dev/null || echo unknown)"

# --- workspace ---------------------------------------------------------------
if [[ -z "${WORKSPACE}" ]]; then
  WORKSPACE="$(mktemp -d "${TMPDIR:-/tmp}/vim-latex-regression.XXXXXX")" \
    || die "cannot create workspace"
  created_workspace=1
else
  [[ ! -e "${WORKSPACE}" && ! -L "${WORKSPACE}" ]] || die "--workspace must name a new directory"
  mkdir -p "${WORKSPACE}" || die "cannot create ${WORKSPACE}"
  WORKSPACE="$(cd -- "${WORKSPACE}" && pwd)"
  created_workspace=0
fi

cleanup() {
  if [[ ${KEEP} -eq 0 && ${created_workspace} -eq 1 && -n "${WORKSPACE}" ]]; then
    rm -rf "${WORKSPACE}"
  fi
}
trap cleanup EXIT

RESULTS="${WORKSPACE}/results.tsv"
VIM_LOG="${WORKSPACE}/vim-session.log"

# --- fixture: multi-file project under a path containing spaces --------------
paper="${WORKSPACE}/paper with spaces"
mkdir -p "${paper}/sections"
cat >"${paper}/main.tex" <<'EOF'
\documentclass{article}
\begin{document}
\input{sections/intro}
\end{document}
EOF
cat >"${paper}/sections/intro.tex" <<'EOF'
% !TeX root = ../main.tex
Intro line two.
Intro line three.
Intro line four.
EOF
cat >"${paper}/sections/appendix.tex" <<'EOF'
% !TeX root = ../main.tex
Appendix body.
EOF
# Custom $out_dir proves the project .latexmkrc is honoured.
cat >"${paper}/.latexmkrc" <<'EOF'
$pdf_mode = 1;
$out_dir = "build output";
EOF

# Standalone file with neither \documentclass nor a root directive.
mkdir -p "${WORKSPACE}/orphan"
cat >"${WORKSPACE}/orphan/orphan.tex" <<'EOF'
Just a fragment with no main document.
EOF

# Slow project so repeat-trigger and stop can be observed deterministically.
slow="${WORKSPACE}/slow build"
mkdir -p "${slow}"
cat >"${slow}/main.tex" <<'EOF'
\documentclass{article}
\begin{document}
Slow build fixture.
\end{document}
EOF
cat >"${slow}/.latexmkrc" <<'EOF'
$pdf_mode = 1;
sleep 25;
EOF

# --- run vim -----------------------------------------------------------------
echo "workspace: ${WORKSPACE}"
echo "vimrc:     ${VIMRC}"
echo "vim:       $(vim --version | head -1)"
echo "latexmk:   $(latexmk --version 2>&1 | head -1)"
echo "vimtex:    ${vimtex_desc} (${vimtex_sha})"
echo

export VIM_LATEX_TEST_WORKSPACE="${WORKSPACE}"
export VIM_LATEX_TEST_RESULTS="${RESULTS}"
export XDG_CACHE_HOME="${WORKSPACE}/cache"

# 'compatible' stays set when -u names a file, which breaks line continuations
# in the plugins; restore the normal interactive default explicitly.
# coc.nvim is irrelevant here and only adds a node process to every run.
vim -i NONE -n -u "${VIMRC}" \
    --cmd 'set nocompatible' \
    --cmd 'let g:coc_start_at_startup = 0' \
    --cmd 'let g:vimtex_cache_root = $VIM_LATEX_TEST_WORKSPACE . "/vimtex-cache"' \
    -T dumb --not-a-term \
    -S "${CASES}" \
    </dev/null >"${VIM_LOG}" 2>&1 &
vim_pid=$!

waited=0
while kill -0 "${vim_pid}" 2>/dev/null; do
  if [[ ${waited} -ge ${VIM_TIMEOUT} ]]; then
    kill -TERM "${vim_pid}" 2>/dev/null
    sleep 2
    kill -KILL "${vim_pid}" 2>/dev/null
    echo "FAIL harness/vim-session  vim exceeded ${VIM_TIMEOUT}s and was killed"
    echo
    echo "session log: ${VIM_LOG}"
    [[ ${KEEP} -eq 1 ]] && echo "workspace kept: ${WORKSPACE}"
    exit 1
  fi
  sleep 1
  waited=$((waited + 1))
done
wait "${vim_pid}"; vim_status=$?

if [[ ! -f "${RESULTS}" ]]; then
  echo "error: no results written; vim exited with status ${vim_status}" >&2
  echo "--- vim session log ---" >&2
  cat "${VIM_LOG}" >&2 2>/dev/null
  exit 2
fi

# --- report ------------------------------------------------------------------
pass=0; fail=0
if [[ ${vim_status} -ne 0 ]]; then
  printf "FAIL harness/vim-exit Vim exited with status %s\n" "${vim_status}"
  fail=$((fail + 1))
fi

if [[ "${vimtex_desc}" == "${VIMTEX_PIN}" ]]; then
  printf '%-4s %-36s %s\n' PASS 'preflight/vimtex-pinned-version' "${vimtex_desc}"
  pass=$((pass + 1))
else
  printf '%-4s %-36s %s\n' FAIL 'preflight/vimtex-pinned-version' \
    "expected ${VIMTEX_PIN}, checkout reports ${vimtex_desc}"
  fail=$((fail + 1))
fi
while IFS=$'\t' read -r status name detail; do
  [[ -z "${status:-}" ]] && continue
  printf '%-4s %-36s %s\n' "${status}" "${name}" "${detail}"
  if [[ "${status}" == "PASS" ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
done <"${RESULTS}"

# --- packaging check ---------------------------------------------------------
# Repository-only tests and maintenance documents must not become home links.
# Full installer regression: bash scripts/tests/bootstrap-tests.sh.
check_bootstrap_scope() {
  local probe out
  probe="$(mktemp -d "${TMPDIR:-/tmp}/vim-bootstrap-probe.XXXXXX")" || return 2
  out="$("${REPO_ROOT}/scripts/bootstrap.sh" --home "${probe}" --dry-run 2>&1)" || { rm -rf "${probe}"; return 2; }
  rm -rf "${probe}"
  printf '%s' "${out}" | grep -E "ln -s .*/vim/(tests/|maintenance\.md)" || true
}

stray="$(check_bootstrap_scope)" || die "bootstrap dry-run failed"
if [[ -z "${stray}" ]]; then
  printf '%-4s %-36s %s\n' PASS 'packaging/test-assets-not-linked' \
    'bootstrap.sh does not link vim/tests or vim/maintenance.md into $HOME'
  pass=$((pass + 1))
else
  printf '%-4s %-36s %s\n' FAIL 'packaging/test-assets-not-linked' \
    "bootstrap.sh would link $(printf '%s\n' "${stray}" | grep -c .) repo-only asset(s) into \$HOME"
  printf '%s\n' "${stray}" | sed 's/^/       /'
  fail=$((fail + 1))
fi

echo
echo "passed: ${pass}  failed: ${fail}  (vim exit ${vim_status}, ${waited}s)"
if [[ ${KEEP} -eq 1 ]]; then
  echo "workspace kept: ${WORKSPACE}"
  echo "session log:    ${VIM_LOG}"
fi

[[ ${fail} -eq 0 ]] || exit 1
exit 0
