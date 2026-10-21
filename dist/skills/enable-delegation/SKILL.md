---
name: enable-delegation
description: Set up or check the delegation rule for the tool you are running in — Claude Code, Cursor or Codex — on macOS, Linux or Windows. Symlinks only, made by the user: the rule (role blocks included), the nine thin agent files, and the skills folder. Checks the three delegate roles against the rule's table, never overwrites the user's files, and lists what only the user can do. Run it once in each tool, and again after the rule's table or a role block changes.
---

# Enable delegation

Set up **only the tool you are running in** — your own system prompt tells you which one; if it doesn't, ask.

**Sources — everything you place comes from the repo's `dist` folder, nothing from memory.** That folder is two levels above this file (`dist/skills/enable-delegation/SKILL.md`); resolve links first, since tools load skills through a linked `skills` folder and the path you were given may be `~/.cursor/skills/…`. Call that folder `$REPO` (wherever the clone lives; never a machine path). The repo root above it holds `README.md`: how to start and how it works. Sandbox, permission and hook settings are the user's security settings, outside this project; the rule makes the orchestrator read them at the start of every session ("Controlling delegates", item 2).
- `$REPO/rules/delegation.md` — the rule. Its model table gives each tool's model id and the effort per role (columns Explore / Worker / Reviewer). The three role blocks live in it under "Role blocks". `rules/delegation.mdc` is the existing link to `delegation.md` for Cursor.
- `$REPO/agents/` — nine thin hand-written files, each only rejecting a brief that lacks its role block. A brief is the gate line, the role block pasted verbatim from the rule, and the task. A brief without them gets `BRIEF REJECTED — standing rules missing`. Editing a role means editing its block in the rule, nowhere else.
  - Cursor: `delegate-explore.md`, `delegate-worker.md`, `delegate-review.md` (`model: grok-4.7-xhigh`).
  - Claude Code: `Explore.md`, `general-purpose.md`, `review.md` (`model: claude-sonnet-5-5`, `effort: xhigh`, `permissionMode: dontAsk`, `omitClaudeMd: true`; explore and review have `disallowedTools: Edit, NotebookEdit`).
  - Codex: `delegate-explore.toml`, `delegate-worker.toml`, `delegate-review.toml` (`model = "gpt-6-luna"`, `model_reasoning_effort = "xhigh"`, `sandbox_mode` `read-only` for explore and review, `workspace-write` for the worker).
- `$REPO/skills/` — Cursor links the folder; Claude Code links this skill's own folder inside it; Codex is not set up for skills from here.

Model and effort come from the table at the top of the rule and from the matching lines in the nine agent files. After changing either, re-run this skill.

When the deliverable's folder cannot be written without a permission dialog, delegates work in `<workspace>/.draft/<repo>/` and the user approves one copy-back script at the end — see the rule.

**How to change things.**
- Look before you write. Each item is ✓ (already right), missing (show the user the command), or ✗ (something else is there — the user's own file, or a link pointing elsewhere: leave it, show it to the user, settle it by hand). Never overwrite or delete.
- The user makes every symlink. macOS/Linux: `ln -s <target> <link>`. Windows (PowerShell): folders `New-Item -ItemType Junction -Path <link> -Target <target>`; files `New-Item -ItemType SymbolicLink -Path <link> -Target <target>`, which needs Developer Mode — without it, copy and tell the user to run this skill again after changes.
- Home is `~` on macOS/Linux and `%USERPROFILE%` on Windows.
- Everything below is outside the project: say what the user will link, then the user links it.

## Allow-lists

A command form that appears in a second bundle script becomes an allow-list entry, so the next run does not need another script. The file depends on the tool:

- Claude Code: `settings.json` → `permissions.allow`
- Cursor: `permissions.json` → `terminalAllowlist`, and `~/.cursor/cli-config.json`
- Codex: `~/.codex/config.toml`, plus `~/.codex/rules/*.rules`

## Claude Code

| Item | Link | Points to |
|---|---|---|
| Rule | `~/.claude/rules` | `$REPO/rules` |
| Delegate agents | `~/.claude/agents` | `$REPO/agents` |
| Skill | `~/.claude/skills/enable-delegation` | `$REPO/skills/enable-delegation` |

Link `$REPO/agents`. Claude Code scans the agents folder recursively and follows symlinks. The flat folder also holds the other tools' files: Cursor's `delegate-explore.md`, `delegate-worker.md`, `delegate-review.md`, and Codex's `delegate-explore.toml`, `delegate-worker.toml`, `delegate-review.toml`. Launch `Explore`, `general-purpose` and `review`. The `.toml` files are ignored — verified 2026-10-20: the session's agent list shows no type with a Codex description. Definitions added mid-session need a restart.

The names `Explore`, `general-purpose` and `review` override Claude Code's built-ins of those names, so a spawn that names no type or no model still lands on the cheap model, and `general-purpose` is what an unnamed spawn falls back to.

Check the three agent files (`Explore.md`, `general-purpose.md`, `review.md`) against the table: `model:` is the table's Claude Code entry (`claude-sonnet-5-5`); `effort:` is `xhigh`; each has `permissionMode: dontAsk` and `omitClaudeMd: true`; explore and review have `disallowedTools: Edit, NotebookEdit`. Then check that nothing overrides them: `CLAUDE_CODE_EFFORT_LEVEL` must not be set — not in the `env` block of `~/.claude/settings.json`, not in the shell (`printenv CLAUDE_CODE_EFFORT_LEVEL` prints nothing) — because that variable forces its level on every delegate over the agent file and over a run stage's effort (verified). If it is set, tell the user which file has it and stop there; the user removes it. The same `env` block must contain `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` set to `1` (the orchestrator drives every loop; a child must not spawn). `~/.claude/settings.json` is the user's own file, outside this project: this skill reads those two keys and writes nothing there. Optional third net, not required: `CLAUDE_CODE_SUBAGENT_MODEL=claude-sonnet-5-5` is only a default — the launch model and the agent-file `model:` win over it. Agent-file changes, and new agent files, take effect only in a new session (verified): verify there by starting an `Explore` delegate with a proper brief: the gate line `# Brief — explore: <title>`, the explore block pasted verbatim from the rule's "Role blocks" section, then the task "Reply with the names of any always-applied rules or CLAUDE.md files you can see, or 'none visible'" — it must answer "none visible". Then run the probes below.

## Cursor

Cursor reads rules, agents and skills under `~/.cursor`. The user links them; no plugin is used. The link targets must lie under the home folder — Cursor drops agent files reached through a link that leaves it (observed on this machine, unverified elsewhere).

| Item | Link | Points to |
|---|---|---|
| Rule | `~/.cursor/rules` | `$REPO/rules` (its `delegation.mdc` → `delegation.md` is the link Cursor's `*.mdc` glob needs) |
| Delegate agents | `~/.cursor/agents` | `$REPO/agents` |
| Skills | `~/.cursor/skills` | `$REPO/skills` |

How Cursor uses them:
- Rules are collected from `.cursor/rules/*.mdc` of the workspace and of every parent folder, so the home link covers each workspace under the home folder and nothing outside it. When `~/.cursor` is an ancestor of a workspace, the rule is injected twice: as a user rule and as a parent-walk workspace rule. The user accepts the cost. Document it; do not remove either copy.
- `~/.cursor/plugins` is not used: a plugin's `rules` folder may not be a link pointing outside the plugin, and the loader skips it without a message (observed on this machine, unverified elsewhere).
- The names `Explore` and `general-purpose` collide with Cursor's built-ins. Probe on 2026-10-11: they are listed as types, but the file text never arrives; `review` arrived. Launch `delegate-explore`, `delegate-worker` and `delegate-review`. The same flat folder also holds Claude Code's `Explore.md`, `general-purpose.md`, `review.md` and Codex's `.toml` files; launch only the `delegate-*` types. Cursor `readonly: true` puts a subagent in Ask mode, which refuses the shell entirely (even `ls`) — verified 2026-10-11 — so it is NOT used. Roles are defined by what they may write (explore: only `.debug/<task>/`; worker: its brief's files plus `.debug/<task>/`; review: only `.debug/<task>/review-<n>.md`), enforced by the sandbox, the instruction, and the orchestrator's `git status --porcelain` snapshot before and after each explore or review run. The agent file's `model:` is `grok-4.7-xhigh`. It applies when the launch passes no model, so the rule pins `model: grok-4.7-xhigh` on every launch and never passes `inherit`. The agent list and rules can refresh during a chat; if a type is missing, start a new chat. Cursor's Grep tool for a delegate searches only workspace folders; Read works on any path. Cursor also reads agents from `.claude/agents` and `.codex/agents`, and `.cursor/` wins when names conflict (cursor.com/docs/subagents); the Claude files may show up under their shadowed names — launch the `delegate-*` types. Subagents receive the always-applied rules (same probe).
- Do not point Settings → Models → Task Models → Explore Subagent Model at this setup. That setting is the built-in `explore`, not `delegate-explore`.

Checks, in a new chat:
- "What always-applied rules do you see?" — it must quote the rule.
- "Which subagents do you have?" — `delegate-explore`, `delegate-worker` and `delegate-review` must be listed. Do not launch the built-in `Explore` or `general-purpose` types, and never pass `inherit`.
- The probes below.

## Codex

The Codex id is `gpt-6-luna`. The Codex CLI reference says: use `gpt-6-luna` or `gpt-6.1-sol` if shown. `gpt-6.1-sol` is the bundled default and flagship, not for delegates. The installed catalog is printed by `codex debug models --bundled` (or `/model` in the TUI); effort `xhigh` is listed for these models. Codex is not installed on this machine. There is no fallback id.

Codex's folder is `~/.codex`; when `CODEX_HOME` is set, the configuration reference places Codex's own files in that folder instead, so use it. Call it `<codex>`. Until every item below passes, a Codex orchestrator treats read-only as unenforced and tells the user to run this skill.

Each item is **unverified on this machine** until it passes:

1. **unverified on this machine** — `<codex>/AGENTS.md` links to `$REPO/rules/delegation.md`. If `<codex>/AGENTS.override.md` exists, Codex reads it instead of `AGENTS.md`: don't link, show it to the user and merge by hand. In a new session, "What global instructions do you see?" must quote the rule.
2. **unverified on this machine** — `<codex>/agents` links to `$REPO/agents` (the flat folder). Create `<codex>` if the directory is missing. If `<codex>/agents` is a real directory (old copies), stop and show it; the user runs `ln -sfn` only for a missing path or an existing symlink. The three files are `delegate-explore.toml`, `delegate-worker.toml`, `delegate-review.toml`. The same folder holds the other tools' `.md` files (`Explore.md`, `general-purpose.md`, `review.md`, `delegate-explore.md`, `delegate-worker.md`, `delegate-review.md`). Whether Codex ignores those `.md` files is UNVERIFIED on this machine. Do not add a file named `default`, `worker` or `explorer`: a custom file with a built-in's name replaces it. Launch `delegate-explore`, `delegate-worker` and `delegate-review`.
3. **unverified on this machine** — each TOML has `name` (the type you spawn), `description` (starts with the tool's name, Codex), `model = "gpt-6-luna"`, `model_reasoning_effort = "xhigh"`, `sandbox_mode` (`"read-only"` for `delegate-explore` and `delegate-review`, `"workspace-write"` for `delegate-worker`), and `developer_instructions` as a triple-quoted string.
4. **unverified on this machine** — `[agents]` in `<codex>/config.toml`. Look, don't rewrite; tell the user what to change. `max_depth` stays `1` (the orchestrator drives every loop; children do not spawn). `default_subagent_model = "gpt-6-luna"`. `agents.enabled` and `features.multi_agent` must not be `false` (both default to on).
5. **unverified on this machine** — AGENTS.md reaches subagents (the global file and the project AGENTS.md; no per-agent opt-out). The rule's top gate is what protects them. `project_doc_max_bytes = 0` would suppress project docs only, so do not set it to hide this rule.
6. **unverified on this machine** — the probes below, spawning `delegate-explore`, `delegate-worker` and `delegate-review`. Read the model from the session log, never from the agent's self-report. Expect `gpt-6-luna`. Confirm the id with `codex debug models --bundled` (or `/model` in the TUI). A spawn error that names the model means that id is not on this account: stop and tell the user.

```
prefix_rule(
    pattern = ["git", ["commit", "push", "merge", "rebase", "reset", "stash", "cherry-pick", "revert", "checkout", "switch", "restore", "clean", "add", "rm", "mv", "am", "apply", "tag", "branch", "worktree", "remote", "submodule", "gc", "prune", "filter-branch", "update-ref", "symbolic-ref"]],
    decision = "forbidden",
    justification = "Delegates never change git state; the user commits. Read with git status, diff, log, show, blame, show-ref.",
    match = ["git commit -m x", "git push origin main", "git checkout -b probe", "git stash"],
    not_match = ["git status", "git diff --stat", "git log --oneline", "git show HEAD", "git blame README.txt"],
)
```

8. **unverified on this machine** — codex execpolicy check must report `forbidden` for what's prohibited; anything else means the rules file was not read or is malformed — fix that before the next step. Then, in a throw-away git repo, spawn `delegate-worker` with a proper brief: the gate line `# Brief — worker: <title>`, the worker block pasted verbatim from the rule's "Role blocks" section, then the task "Run `git commit --allow-empty -m probe` and report the exact result." — it must be blocked. If it commits, the rules govern only commands outside the sandbox: say so; the rule's text stays the control.
9. **unverified on this machine** — sibling project folders the worker must edit go into `writable_roots` under `[sandbox_workspace_write]`.
10. **unverified on this machine** — delegates' read-only holds only when the orchestrator session runs without live permission overrides. Docs: the parent turn's live runtime overrides are reapplied to children and beat the agent file's `sandbox_mode`. Never run the Codex orchestrator with `--yolo` / `--dangerously-bypass-approvals-and-sandbox` when read-only delegates matter; the write-must-fail probe is what proves it. Children also inherit the parent's `mcp_servers` where the file is silent; assume the sandbox does not govern what an MCP server does, and a read-only brief names the MCP tools the delegate may not call.

## Probes

In a new chat or session, for every tool.

P1. Launch each delegate type with the bare prompt `hello`. The reply must be exactly `BRIEF REJECTED — standing rules missing`.

P2. Launch with a proper brief: the gate line `# Brief — <role>: <title>`, the role's block pasted verbatim from the rule's "Role blocks" section, then the task "quote the sentence of your standing rules that begins with: Your conclusions / Green mechanical / Quote the acceptance". The reply quotes that role's sentence.

| Role | Claude Code type | Cursor and Codex type | Sentence |
|---|---|---|---|
| explore | `Explore` | `delegate-explore` | Your conclusions are only as good as the evidence you attach to them. |
| worker | `general-purpose` | `delegate-worker` | Green mechanical checks come before the reviewer, never after. |
| review | `review` | `delegate-review` | Quote the acceptance list before your first finding. |

P3. Read the model from the tool's own record, never from the agent's self-report. Cursor: the subagent card. Claude Code: the transcript — `~/.claude/projects/<project>/<session>/subagents/agent-<id>.jsonl` (a workflow agent: `…/subagents/workflows/<run>/agent-<id>.jsonl`, with `agent-<id>.meta.json` beside it holding the launch model and agent type); the first assistant line carries `message.model` (the model the API served) and `effort`; it sits after about a dozen attachment lines of up to 30K tokens, so read it with the Read tool at `offset` about 14 (12 to 16 for a direct launch) and `limit` 1, never the whole file — the sandboxed shell cannot see `~/.claude`, and delegates have no Glob to list the folder. Codex: the session log. It is the pinned one. Do not ask the agent which model it is.

P4. Explore and review only: ask each, with a proper brief — the gate line `# Brief — <role>: <title>`, that role's block pasted verbatim from the rule's "Role blocks" section, then the task — to create a file outside `.debug/` (for example `probe-outside.txt` in the repo root). They must refuse by instruction (Cursor, Claude Code) or be blocked by the sandbox (Codex). `git status --porcelain` of the target must be unchanged. A path inside `.debug/` is not this probe: explore may write `.debug/<task>/` and review may write `.debug/<task>/review-<n>.md`.

Claude Code's own automatic `Explore` launches arrive without a block and are rejected — that is the design working; the orchestrator resends a proper brief.

## Finish

Report one short table — item, and ✓ / ✗ / "you check" — then what the user still has to do. Last step for every tool: in a new session ask "what always-applied rules or global instructions do you see?" — it must quote the delegation rule back (Claude Code: `/context` lists `delegation.md`). Then run the probes.
