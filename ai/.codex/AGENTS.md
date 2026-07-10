## Skills

Skills 位于 `~/.config/myagents/skills/`，结构如下：
- `tools/<name>/skill.md` — 工具类 skill
- `workflows/<name>/skill.md` — 工作流 skill
- `common/` — 基础行为定义
- `roles/` — 角色定义（planner/coder/reviewer）

需要某个 skill 时，Read 对应的 skill.md 文件。
可用 skill 列表见 `~/.config/myagents/skills/SKILLS_CATALOG.md`。

## Python interpreter

- For local Python scripts, validators, and ad hoc checks, prefer `/opt/homebrew/Caskroom/miniconda/base/envs/work/bin/python` so common scientific and YAML dependencies are available. Repository-local interpreter, virtualenv, or project instructions take precedence.

## Scientific computing

- For scientific or numerical Python/Julia work, use the `$scientific-computing` skill. Repository-local instructions, tests, and numerical conventions remain authoritative.
<!-- CCG-FAST-CONTEXT-START -->
# fast-context MCP 工具使用指南

## 核心原则

**任何需要理解代码上下文、探索性搜索、或自然语言定位代码的场景，优先使用 `mcp__fast-context__fast_context_search`**

## 使用场景

### 必须用 fast_context_search
- 探索性搜索（不确定代码在哪个文件/目录）
- 用自然语言描述要找的逻辑（如"部署流程"、"事件处理"）
- 理解业务逻辑和调用链路
- 跨模块、跨层级查询（如从 router 追到 service 到 model）
- 新任务开始前的代码调研和架构理解
- 中文语义搜索（工具支持中英文双语查询）

### 根据需求选择工具
- **语义搜索 / 不确定位置** → `mcp__fast-context__fast_context_search`（返回文件+行号范围+grep关键词建议）
- **精确关键词搜索** → Grep
- **已知文件路径，查看内容** → Read
- **按文件名模式查找** → Glob
- **编辑已有文件** → Edit

### fast_context_search 参数调优
- `tree_depth=1, max_turns=1` — 快速粗查，适合小项目或初步定位
- `tree_depth=3, max_turns=3`（默认）— 平衡精度与速度，适合大多数场景
- `max_turns=5` — 深度搜索，适合复杂调用链追踪
- `project_path` — 指定搜索的项目根目录，默认为当前工作目录

### 禁止行为
- ❌ 猜测代码位置（"应该在 service/firmware 里"）
- ❌ 跳过搜索直接回答（"根据框架惯例，应该是..."）
- ❌ 遇到搜索就启动子代理（fast-context + Grep 组合优先）

### 子代理使用条件
仅当需要读取 10+ 文件交叉比对、或多轮搜索会撑爆上下文时，才启动子代理。

<!-- CCG-FAST-CONTEXT-END -->
