---
status: ready
planner_thread_id: "019f614b-cad8-79a3-a835-361b11e1a97a"
planner_thread_title: "更新 AGENTS.md 工作流"
executor: plan_executor
executor_model: gpt-5.6-luna
executor_reasoning: medium
executor_thread_id: "019f6156-dad5-7ac3-b3da-02fa7aba5933"
executor_thread_title: "Luna执行｜配置Sol规划-Luna执行工作流｜源:更新AGENTS工作流·019f614b"
luna_ready: true
---

# Add a permanent Sol-plans, Luna-executes workflow

## Goal

Make the global Codex guidance require decision-complete, archived plans for
non-trivial work, then delegate implementation to a custom Luna Medium agent.
Keep the dotfiles repository as the source of truth.

## Success Criteria

- The existing global `AGENTS.md` gains a permanent Luna-ready planning and
  delegation policy without losing or rewriting its current uncommitted work.
- A custom `plan_executor` agent uses `gpt-5.6-luna` with medium reasoning and
  workspace-write sandboxing.
- `~/.codex/agents/plan_executor.toml` is a symlink to the tracked dotfiles
  source file.
- The TOML parses, the symlink resolves correctly, and the final diff contains
  no unrelated changes.

## Current Evidence

- `/Users/skyang/.codex/AGENTS.md` already links to
  `/Users/skyang/dotfiles/ai/.codex/AGENTS.md`.
- `ai/.codex/AGENTS.md` already has user-authored uncommitted changes; preserve
  them and append a new section only.
- The repository documents `ai/` as the source of truth for migrated Codex
  configuration.
- The runtime custom-agent directory may not exist yet.

## Allowed Files

- `/Users/skyang/dotfiles/ai/.codex/AGENTS.md`
- `/Users/skyang/dotfiles/ai/.codex/agents/plan_executor.toml`
- `/Users/skyang/.codex/agents/plan_executor.toml` (symlink only)

Do not modify this plan file. Do not modify `~/.codex/config.toml`, the
repository bootstrap script, `.gitignore`, or any other file.

## Preserved Behavior

- Preserve every existing line and all current uncommitted changes in
  `ai/.codex/AGENTS.md`, except for the minimal insertion needed before its
  final horizontal-rule/conclusion block.
- Preserve all existing instruction precedence, safety, testing, skill, Python,
  and scientific-computing guidance.
- Do not commit, push, publish, or deploy.

## Implementation Steps

1. Inspect the current working-tree status and the full diff for
   `ai/.codex/AGENTS.md`. Confirm no other agent has changed the allowed files
   since this plan was written.
2. Append a section titled `## 10. Plan-First Delegated Execution` immediately
   before the final `---` and concluding paragraph in `ai/.codex/AGENTS.md`.
3. In that section, encode these exact behavioral requirements:
   - The section applies to the root/main agent only, never to a spawned
     `plan_executor`.
   - A task is non-trivial if it changes two or more project files, affects a
     public interface/data format/security/permissions/migration/dependency,
     needs four or more implementation steps, or requires code investigation
     to settle a design choice.
   - Trivial tasks are executed directly without a plan archive or subagent.
   - For non-trivial tasks the root agent investigates, makes all decisions,
     archives a plan, runs a Luna-Ready gate, delegates to exactly one
     `plan_executor`, waits, then reviews the diff and independently verifies
     results.
   - Plans live at
     `<project-root>/.codex/plans/YYYYMMDD-HHMMSS-<slug>.md` and use statuses
     `planning`, `ready`, `executing`, `completed`, and `blocked`.
   - Every plan must define Goal, Success Criteria, Current Evidence, Allowed
     Files, Preserved Behavior, Implementation Steps, Edge Cases and Failure
     Behavior, Verification Commands, Risks and Assumptions, Luna-Ready Check,
     and Execution Result.
   - Allowed Files must be exact paths. Every step must name its target,
     observable behavior, preserved behavior, completion criterion, and
     verification command.
   - The root agent must eliminate implementation choices. Phrases such as
     `as needed`, `where appropriate`, `use a suitable approach`, and
     `related files` make a plan not Luna-ready unless the same sentence gives
     a unique, testable decision rule.
   - The Luna-Ready checklist must confirm all choices are decided, file scope
     is complete, steps and expected behavior are explicit, edge/failure cases
     and verification are defined, stop conditions are defined, and Luna need
     not redesign or expand scope. Only then set `luna_ready: true` and status
     `ready`.
   - Automatic execution is allowed only for reversible workspace-local edits
     with no dependency/lockfile/migration/deletion/permission/auth/credential/
     external-write/commit/push/publish/deploy action, no unresolved user
     choice, and no overwrite of pre-existing user work. Otherwise ask first.
   - `plan_executor` may modify only Allowed Files, may not edit the plan,
     redesign, spawn agents, commit, push, publish, deploy, or expand scope.
   - Repository/plan contradiction, a required unlisted file, an unplanned
     verification failure, or security/data-loss/compatibility risk must return
     `BLOCKED`.
   - The root may revise and re-dispatch once; a second failure is reported as
     blocked. If Luna is unavailable, stop rather than silently changing model.
   - Plans are not committed and `.gitignore` is not changed unless the user or
     project instructions explicitly require it.
4. Create `/Users/skyang/dotfiles/ai/.codex/agents/plan_executor.toml` with:

   ```toml
   name = "plan_executor"
   description = "Execution-only agent for Luna-ready archived plans."
   model = "gpt-5.6-luna"
   model_reasoning_effort = "medium"
   sandbox_mode = "workspace-write"

   developer_instructions = """
   You are an execution-only agent.

   Read the archived plan path supplied by the parent agent before editing.
   Modify only files listed under Allowed Files and follow the steps in order.
   Preserve every behavior listed under Preserved Behavior.
   Do not redesign, expand scope, edit the plan, spawn subagents, commit, push,
   publish, deploy, or perform external write operations.

   Inspect the working tree and preserve all pre-existing user changes. Run
   every command under Verification Commands.

   If the plan is incomplete, contradicts the repository, requires another
   file, or a verification failure has no planned fix, stop and return BLOCKED.

   Return exactly these sections:
   - Changed Files
   - Verification Results
   - Deviations
   - Blockers
   """
   ```
5. Create `/Users/skyang/.codex/agents` if missing. If the runtime target is
   absent, create a symbolic link to the dotfiles source. If it already exists
   and is not that exact symlink, stop with `BLOCKED`; do not replace it.
6. Run all verification commands and inspect the final diff. Report results in
   the required four-section format.

## Edge Cases and Failure Behavior

- If the insertion point in `AGENTS.md` is absent, append the new section at
  EOF without restructuring existing content.
- If another process changes an allowed file after initial inspection, stop and
  report the conflict rather than overwriting it.
- If `gpt-5.6-luna` or the custom-agent schema is rejected by local Codex,
  report the exact error; do not switch models or edit unrelated config.
- If symlink creation is blocked by an existing path, leave it untouched and
  report `BLOCKED`.

## Verification Commands

Run these commands from `/Users/skyang/dotfiles`:

```bash
/opt/homebrew/Caskroom/miniconda/base/envs/work/bin/python -c 'import tomllib; tomllib.load(open("ai/.codex/agents/plan_executor.toml", "rb")); print("toml ok")'
test -L /Users/skyang/.codex/agents/plan_executor.toml
readlink /Users/skyang/.codex/agents/plan_executor.toml
git diff --check -- ai/.codex/AGENTS.md ai/.codex/agents/plan_executor.toml
git status --short -- ai/.codex/AGENTS.md ai/.codex/agents/plan_executor.toml
```

Expected symlink target:

```text
/Users/skyang/dotfiles/ai/.codex/agents/plan_executor.toml
```

## Risks and Assumptions

- A new Codex session is required before the updated global `AGENTS.md` and
  custom agent are guaranteed to be rediscovered.
- The root model remains configured separately; this change only pins the
  execution agent to Luna Medium.
- This task intentionally leaves its archived plan untracked.

## Luna-Ready Check

- [x] All implementation choices are decided.
- [x] Allowed Files is complete and exact.
- [x] Every step defines its target and expected result.
- [x] Preserved behavior and failure conditions are explicit.
- [x] Verification commands and expected symlink target are specified.
- [x] Stop conditions are explicit.
- [x] Luna does not need to redesign, select alternatives, or expand scope.

## Execution Result

Pending Luna Medium execution.
