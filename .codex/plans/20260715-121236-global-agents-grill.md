---
status: blocked
planner_thread_id: "019f63ee-1acf-7602-a819-1f6e23716725"
planner_thread_title: "评估引入 grill-me-doc"
executor: plan_executor
executor_model: gpt-5.6-luna
executor_reasoning: medium
executor_thread_id: "/root/plan_executor"
executor_thread_title: "plan_executor"
luna_ready: true
---

# Optimize global AGENTS guidance and add an explicit grill skill

## Goal

Reduce the fixed-context cost of the global `AGENTS.md` while preserving its
current cross-repository safety and execution behavior. Add a single explicit
`grill` skill that challenges framing, confirmation bias, and solution fixation
before high-impact planning without slowing ordinary work.

## Success Criteria

- `/Users/skyang/dotfiles/ai/.codex/AGENTS.md` remains the global source of
  truth and is reduced from 16,101 bytes / 343 lines to at most 10,240 bytes /
  220 lines.
- The condensed file preserves instruction precedence, evidence-first work,
  scope control, user-work protection, verification, search selection, skill
  routing, Python and scientific-computing guidance, Luna-ready delegation,
  Goal integration, conservative parallelism, and executor provenance.
- The global file adds only a concise explicit trigger for `$grill`; the full
  interview procedure lives in the skill.
- `grill` is a single instruction-only skill, is discoverable by native Codex
  and the curated registry, and cannot trigger implicitly.
- Registry metadata and the human-readable catalog contain `grill`, and all
  applicable validators pass or have a documented scope limitation.
- No unrelated dirty files are modified, committed, reverted, published, or
  deleted.

## Current Evidence

- `~/.codex/AGENTS.md` resolves to
  `/Users/skyang/dotfiles/ai/.codex/AGENTS.md`.
- The current global file is 16,101 bytes, 2,273 words, and 343 lines.
- The whole global file is already an uncommitted user change relative to Git;
  treat its live contents, not `HEAD`, as the behavioral baseline.
- Official Codex documentation states that instruction discovery stops at a
  combined 32 KiB by default. That is a truncation ceiling, not a recommended
  global-file target; global guidance is paid as first-turn context.
- Official skill documentation states that skill metadata is always available
  but the body is loaded progressively. It supports
  `policy.allow_implicit_invocation: false` in `agents/openai.yaml`.
- The curated registry scans `workflows/<name>/skill.md`, while native Codex
  requires `SKILL.md`. This macOS volume is case-insensitive, so both spellings
  resolve to the same regular-file inode; one real `SKILL.md` serves both.
- The `skill-creator` procedure requires `init_skill.py`, `SKILL.md`, and
  `agents/openai.yaml`, and explicitly forbids auxiliary README/DESIGN files.

## Allowed Files

- `/Users/skyang/dotfiles/ai/.codex/AGENTS.md`
- `/Users/skyang/dotfiles/myagents/skills/organize_temp_skills.py`
- `/Users/skyang/dotfiles/myagents/skills/workflows/grill/SKILL.md`
- `/Users/skyang/dotfiles/myagents/skills/workflows/grill/agents/openai.yaml`
- `/Users/skyang/dotfiles/myagents/skills/manifest.yaml`
- `/Users/skyang/dotfiles/myagents/skills/SKILLS_CATALOG.md`

Do not modify this plan file. Do not modify profiles, `tool_map.yaml`,
`.gitignore`, Codex config, other skills, or any unrelated dirty file.

## Preserved Behavior

- Preserve the live global guidance's meaning, even when wording is condensed.
- Keep the non-trivial-task threshold at three or more coupled project files,
  or any existing public-interface/data/security/permission/migration/
  dependency/design-investigation trigger.
- Keep one-executor default, Luna-ready gate, exact Allowed Files, independent
  root verification, one revision limit, and stop-if-Luna-unavailable behavior.
- Keep Goal completion and blocked rules, conservative parallel write-set
  rules, executor naming/provenance, no destructive Git, and no unrequested
  commit/push/publish/deploy behavior.
- Keep project-local instructions and project environments authoritative.
- Do not make grill automatic and do not make ordinary low-risk tasks ask more
  questions.

## Implementation Steps

1. Re-read every Allowed File that already exists. Stop with `BLOCKED` if an
   allowed file changed after this plan's evidence was gathered or if the new
   skill directory already exists with user content.
2. Initialize the skill exactly once with the built-in skill creator script:

   ```bash
   /opt/homebrew/Caskroom/miniconda/base/envs/work/bin/python \
     /Users/skyang/dotfiles/myagents/skills/.system/skill-creator/scripts/init_skill.py \
     grill \
     --path /Users/skyang/dotfiles/myagents/skills/workflows \
     --interface display_name="Design Grill" \
     --interface short_description="Challenge a design before committing" \
     --interface default_prompt="Use $grill to stress-test this plan before implementation."
   ```

   Do not add scripts, references, assets, examples, README, or DESIGN files.
3. Replace the generated `SKILL.md` body with a concise imperative workflow
   containing these exact behavioral requirements:
   - Run only after explicit `$grill`, `grill this`, `stress-test this design`,
     or an equivalent explicit user request. Never self-trigger it.
   - Do not implement or mutate project state during the interview.
   - Inspect the filesystem, source, tests, configuration, and tools before
     asking factual questions. Ask the user only for decisions.
   - Establish the decision, current proposal, success criteria, constraints,
     and non-goals before branching.
   - Challenge the initial frame with the strongest credible alternative,
     including a simpler or no-change option when one exists.
   - Check only material branches: assumptions, users, domain terms, interfaces,
     data/state, failure behavior, reversibility, compatibility, security,
     performance, migration, observability, and verification.
   - Order branches by dependency and ask one decision at a time. For every
     question, give a recommended answer, its evidence, the strongest credible
     alternative, and what evidence would reverse the recommendation.
   - After each answer, state the resolved decision and its downstream
     consequences before asking the next question.
   - Explicitly counter anchoring, confirmation bias, solution fixation, sunk
     cost, and availability bias, but do not mechanically ask about irrelevant
     categories.
   - Stop when objectives, boundaries, key decisions, failure cases, and
     verification are decision-complete, or when the user ends the session.
   - Finish with `Decisions`, `Rejected Alternatives`, `Assumptions`,
     `Open Issues`, and `Readiness: ready | draft | blocked`.
   - Reuse an existing authoritative plan/PRD/process log/wiki when capture is
     authorized. Do not create parallel `CONTEXT.md` or ADR files unless the
     repository already uses them or the user explicitly requests them.
4. Ensure `agents/openai.yaml` contains only the generated interface fields
   plus:

   ```yaml
   policy:
     allow_implicit_invocation: false
   ```

   All strings remain quoted and the default prompt explicitly mentions
   `$grill`.
5. Keep only the real `workflows/grill/SKILL.md`; do not create a lowercase
   duplicate or symlink. Verify that both case spellings resolve to the same
   inode on this volume and that the curated scanner can read `skill.md`.
6. Add `"grill"` alphabetically to `WORKFLOW_SKILLS` in
   `organize_temp_skills.py`. In `normalize_entry_name`, add one guard before
   any rename: when both case spellings exist and `samefile()` reports that
   they are the same inode, return `False`. Make no other classifier changes.
7. Replace the live global `AGENTS.md` with a condensed document using exactly
   these sections in order:
   - `0. Scope and Instruction Precedence`
   - `1. Evidence, Decisions, and Grill`
   - `2. Simple and Surgical Changes`
   - `3. Protect Existing Work`
   - `4. Goal-Driven Execution and Verification`
   - `5. Repository Search and Tool Selection`
   - `6. Skills and Runtime`
   - `7. Scientific Computing`
   - `8. Plan-First Delegated Execution`, with compact subsections for Goal
     integration, conservative parallel execution, and provenance.

   Preserve every behavior listed under Preserved Behavior. Point detailed
   fast-context guidance to its skill. Add a three-bullet grill boundary:
   explicit trigger only, facts discovered before questions, and no grill for
   low-risk/reversible work. Remove examples and repeated restatements that do
   not change behavior. The final file must satisfy both size limits.
8. Regenerate, in order, `manifest.yaml` and `SKILLS_CATALOG.md` with the
   repository scripts. Do not hand-edit their generated skill entries.
9. Run every verification command, inspect the final allowed-file state, and
   return the executor report sections `Changed Files`, `Verification Results`,
   `Deviations`, and `Blockers`.

## Edge Cases and Failure Behavior

- If the global file cannot reach both size limits without dropping preserved
  behavior, return `BLOCKED`; do not silently remove a policy.
- If `init_skill.py` creates unexpected resources or an existing `grill`
  directory, stop rather than overwrite it.
- If the two case spellings do not resolve to the same inode, return `BLOCKED`;
  do not create a duplicate entry or redesign the registry.
- If a generated registry command changes files outside Allowed Files, stop and
  report them without reverting user work.
- Generic `verify-module` expects README/DESIGN files, but the more specific
  skill-creator contract forbids them. Use `quick_validate.py` as the module
  integrity gate and record this deliberate exception.
- The working tree contains unrelated changes. Treat generic change-analyzer
  findings outside Allowed Files as informational, not as permission to edit.
- Any security Critical/High finding in Allowed Files is blocking.

## Verification Commands

Run from the stated directories:

```bash
wc -l -w -c /Users/skyang/dotfiles/ai/.codex/AGENTS.md
rg -n 'Scope and Instruction|Evidence, Decisions, and Grill|Protect Existing Work|Goal-Driven|Repository Search|Skills and Runtime|Scientific Computing|Plan-First Delegated|Luna-Ready|Goal Integration|Conservative Parallel|Provenance|three or more coupled|plan_executor|gpt-5.6-luna|\$grill' /Users/skyang/dotfiles/ai/.codex/AGENTS.md
stat -f '%i %N' /Users/skyang/dotfiles/myagents/skills/workflows/grill/SKILL.md /Users/skyang/dotfiles/myagents/skills/workflows/grill/skill.md
/opt/homebrew/Caskroom/miniconda/base/envs/work/bin/python /Users/skyang/dotfiles/myagents/skills/.system/skill-creator/scripts/quick_validate.py /Users/skyang/dotfiles/myagents/skills/workflows/grill
/opt/homebrew/Caskroom/miniconda/base/envs/work/bin/python /Users/skyang/dotfiles/myagents/skills/update_manifest.py --root /Users/skyang/dotfiles/myagents/skills
/opt/homebrew/Caskroom/miniconda/base/envs/work/bin/python /Users/skyang/dotfiles/myagents/skills/generate_catalog.py --root /Users/skyang/dotfiles/myagents/skills
/opt/homebrew/Caskroom/miniconda/base/envs/work/bin/python /Users/skyang/dotfiles/myagents/skills/lint_skills.py --root /Users/skyang/dotfiles/myagents/skills
cd /Users/skyang/dotfiles/myagents/skills && /opt/homebrew/Caskroom/miniconda/base/envs/work/bin/python -c 'from pathlib import Path; from loader import SkillLoader; r=SkillLoader(Path(".")).resolve_skill("grill"); print(r["path"])'
node /Users/skyang/dotfiles/myagents/skills/workflows/ccg/tools/verify-security/scripts/security_scanner.js /Users/skyang/dotfiles/myagents/skills/workflows/grill
node /Users/skyang/dotfiles/myagents/skills/workflows/ccg/tools/verify-quality/scripts/quality_checker.js /Users/skyang/dotfiles/myagents/skills/workflows/grill
cd /Users/skyang/dotfiles && node /Users/skyang/dotfiles/myagents/skills/workflows/ccg/tools/verify-change/scripts/change_analyzer.js --mode working
git -C /Users/skyang/dotfiles diff --check -- ai/.codex/AGENTS.md
git -C /Users/skyang/dotfiles status --short
```

Expected results:

- `AGENTS.md` is at most 220 lines and 10,240 bytes.
- Both `stat` lines report the same inode.
- `quick_validate.py`, registry lint, and loader resolution pass.
- `grill` appears once in the manifest and catalog.
- Security reports zero Critical/High findings in the skill.
- Quality output has no blocking issue attributable to the skill.
- Change-analyzer limitations from unrelated dirty files are documented.
- `git diff --check` reports no whitespace errors.

## Risks and Assumptions

- A new Codex task may be required before the new skill appears in the native
  selector and before the optimized global guidance is reloaded.
- The 8–10 KiB target is an operating recommendation derived from fixed-context
  cost and the user's layered configuration, not an official Codex hard limit.
- The official default combined AGENTS limit remains 32 KiB.
- Case-insensitive same-inode resolution intentionally bridges this curated
  registry's lowercase lookup and native Codex's uppercase `SKILL.md`.

## Luna-Ready Check

- [x] All content, placement, trigger, compatibility, and size decisions are set.
- [x] Allowed Files is complete and exact.
- [x] Preserved behavior and prohibited scope are explicit.
- [x] The skill workflow and its termination criteria are fully specified.
- [x] Edge cases, stop conditions, and verification commands are defined.
- [x] Luna need not select an alternative design or expand scope.

## Execution Result

First execution stopped at the planned symlink guard: this macOS volume treats
`SKILL.md` and `skill.md` as the same regular file, so the symlink could not be
created. Revision 1 replaces the invalid symlink design with verified
case-insensitive same-inode compatibility and adds a normalization guard.

The single allowed Luna Medium redispatch completed the condensed global
`AGENTS.md`, the explicit-only `grill` skill, its `agents/openai.yaml`, and the
registry scanner's same-inode guard. It verified the 188-line / 10,240-byte
global file and matching inode `719733654` for the two case spellings.

The redispatch then stalled for 623.4 seconds before manifest regeneration was
completed and was interrupted. Consequently `manifest.yaml` and
`SKILLS_CATALOG.md` do not yet contain `grill`, and the remaining validation
commands were not run. Under the preserved one-revision limit, this plan is
`blocked`; no further executor redispatch or root-side implementation was
performed.
