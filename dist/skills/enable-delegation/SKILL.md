---
name: enable-delegation
description: >-
  Set up or check the delegation rule for the tool you are running in — Claude Code, Cursor, Codex or Zed — on macOS, Linux or Windows.
  The user makes the links: the rule (role blocks included) and the nine thin agent files.
  For Cursor, the enable-delegation skill must be available on its own — a symlink to that folder, or a copy of it.
  Checks the three delegate roles against the rule's table, never overwrites the user's files, and lists what only the user can do.
  Run it once in each tool, and again after the rule's table or a role block changes.
---

# Enable delegation

Set up **only the tool you are running in** — your own system prompt tells you which one; if it doesn't, ask. Zed's says "You are the Zed coding agent running inside the Zed editor".

**Sources — everything you place comes from the repo's `dist` folder, nothing from memory.** Resolve links first. The path you were given may be `~/.cursor/skills/enable-delegation/…` or `~/.claude/skills/enable-delegation/…`. When `enable-delegation` is a symlink, the real file is `dist/skills/enable-delegation/SKILL.md` and `$REPO` is two levels above that real file (the `dist` folder). When it is a copy, walking up from the copy lands in the user's skills folder, which is not `$REPO`; `$REPO` is the clone's `dist`. Call `$REPO` wherever the clone lives; never a machine path. The repo root above it holds `README.md`: how to start and how it works. Sandbox, permission and hook settings are the user's security settings, outside this project; the rule makes the orchestrator read them at the start of every session ("Controlling delegates", item 2).
- `$REPO/rules/delegation.md` — the rule. Its model table gives each tool's model id and the effort per role (columns Explore / Worker / Reviewer). The three role blocks live in it under "Role blocks". `rules/delegation.mdc` is the existing link to `delegation.md` for Cursor.
- `$REPO/agents/` — nine thin hand-written files, each only rejecting a brief that lacks its role block. A brief is the gate line, the role block pasted verbatim from the rule, and the task. A brief without them gets `BRIEF REJECTED — standing rules missing`. Editing a role means editing its block in the rule, nowhere else.
  - Cursor: `delegate-explore.md`, `delegate-worker.md`, `delegate-review.md` (`model: grok-4.7-xhigh`).
  - Claude Code: `Explore.md`, `general-purpose.md`, `review.md` (`model: claude-sonnet-5-5`, `effort: xhigh`, `permissionMode: dontAsk`, `omitClaudeMd: true`; explore and review have `disallowedTools: Edit, NotebookEdit`).
  - Codex: `delegate-explore.toml`, `delegate-worker.toml`, `delegate-review.toml` (`model = "gpt-6-luna"`, `model_reasoning_effort = "xhigh"`, `sandbox_mode` `read-only` for explore and review, `workspace-write` for the worker).
- `$REPO/hooks/grok-delegate.sh` — the Grok launcher, linked as `~/.claude/hooks/grok-delegate.sh` like `agents` and `rules`, for Claude Code with Grok only (see the Grok section). The user links it as `~/.local/bin/grok-delegate`.
- `$REPO/skills/enable-delegation/` — this skill. Cursor needs it available inside the user's skills folder, and nothing else from this repo: a symlink to this folder, or a copy of it. Do not point Cursor's skills folder at `$REPO/skills`. That directory holds only this skill, and replacing the user's folder would hide their other skills. Claude Code links this skill's own folder (`~/.claude/skills/enable-delegation`). Codex is not set up for skills from here.

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
- Zed: `~/.config/zed/settings.json` → `agent.tool_permissions` (per tool `always_allow` / `always_confirm` / `always_deny` regex lists) and `agent.sandbox_permissions` (`write_paths`, `network_hosts`).

## Claude Code

| Item | Link | Points to |
|---|---|---|
| Rule | `~/.claude/rules` | `$REPO/rules` |
| Delegate agents | `~/.claude/agents` | `$REPO/agents` |
| Skill | `~/.claude/skills/enable-delegation` | `$REPO/skills/enable-delegation` |

Link `$REPO/agents`. Claude Code scans the agents folder recursively and follows symlinks. The flat folder also holds the other tools' files: Cursor's `delegate-explore.md`, `delegate-worker.md`, `delegate-review.md`, and Codex's `delegate-explore.toml`, `delegate-worker.toml`, `delegate-review.toml`. Launch `Explore`, `general-purpose` and `review`. The `.toml` files are ignored — verified 2026-10-20: the session's agent list shows no type with a Codex description. Definitions added mid-session need a restart.

The names `Explore`, `general-purpose` and `review` override Claude Code's built-ins of those names, so a spawn that names no type or no model still lands on the cheap model, and `general-purpose` is what an unnamed spawn falls back to. The Workflow tool's default type is the exception: see the `CLAUDE_CODE_SUBAGENT_MODEL` check below and probe P5.

Check the three agent files (`Explore.md`, `general-purpose.md`, `review.md`) against the table: `model:` is the Claude Code entry of the table's row 2, the Sonnet slug (`claude-sonnet-5-5`); `effort:` is `xhigh`; each has `permissionMode: dontAsk` and `omitClaudeMd: true`; explore and review have `disallowedTools: Edit, NotebookEdit`. Then check that nothing overrides them: `CLAUDE_CODE_EFFORT_LEVEL` must not be set — not in the `env` block of `~/.claude/settings.json`, not in the shell (`printenv CLAUDE_CODE_EFFORT_LEVEL` prints nothing) — because that variable forces its level on every delegate over the agent file and over a run stage's effort (verified). If it is set, tell the user which file has it and stop there; the user removes it. The same `env` block must contain `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` set to `1` (the orchestrator drives every loop; a child must not spawn). `~/.claude/settings.json` is the user's own file, outside this project: this skill reads those two keys and writes nothing there. Required third net: the same `env` block must contain `CLAUDE_CODE_SUBAGENT_MODEL` set to the Claude Code entry of the table's row 2, the Sonnet slug (`claude-sonnet-5-5`) — never a Grok id, even when the user opts into Grok. It is only a default — the launch model and the agent-file `model:` win over it — but it is the one thing that reaches the Workflow tool's built-in default type (`workflow-subagent`, used by a script's `agent()` that names no `agentType`), which no agent file overrides. Missing: show the user the line to add; this skill writes nothing there. `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` stays unset: it would override the launch model too. Agent-file changes, and new agent files, take effect only in a new session (verified): verify there by starting an `Explore` delegate with a proper brief: the gate line `# Brief — explore: <title>`, the explore block pasted verbatim from the rule's "Role blocks" section, then the task "Reply with the names of any always-applied rules or CLAUDE.md files you can see, or 'none visible'" — it must answer "none visible". Then run the probes below.

## Cursor

Cursor reads rules, agents and skills under `~/.cursor`. The user links them; no plugin is used. The link targets must lie under the home folder — Cursor drops agent files reached through a link that leaves it (observed on this machine, unverified elsewhere).

| Item | Link | Points to |
|---|---|---|
| Rule | `~/.cursor/rules` | `$REPO/rules` (its `delegation.mdc` → `delegation.md` is the link Cursor's `*.mdc` glob needs) |
| Delegate agents | `~/.cursor/agents` | `$REPO/agents` |
| Skill | `~/.cursor/skills/enable-delegation` | `$REPO/skills/enable-delegation` |

The skills folder stays the user's. This check passes when `enable-delegation` is available there, and it asks for nothing else. Two forms pass: a symlink `~/.cursor/skills/enable-delegation` → `$REPO/skills/enable-delegation`, which follows later edits of the skill, or a copy of that folder. A copy is a passing form, including where a symlink cannot be created — on Windows a file symlink needs Developer Mode, and without it the copy is the way. A copy does not follow later edits; after this skill changes, copy the folder again. The generic ✗ for "something else is there" does not apply to a copy of this skill: a real directory at that path which contains this skill is ✓. Other entries in the skills folder are the user's; leave them. Do not replace `~/.cursor/skills` with a link or a copy of `$REPO/skills`. If the skills folder is already that whole-folder link, the skill is available, so the availability check still passes — report that this hides any other skills, and do not tell the user to relink the folder to fix it. When the skill is missing, show `ln -s $REPO/skills/enable-delegation ~/.cursor/skills/enable-delegation` on macOS/Linux, or a copy of the folder where a symlink cannot be made. Never show a command that links `~/.cursor/skills` itself to `$REPO/skills`.

How Cursor uses them:
- Rules are collected from `.cursor/rules/*.mdc` of the workspace and of every parent folder, so the home link covers each workspace under the home folder and nothing outside it. When `~/.cursor` is an ancestor of a workspace, the rule is injected twice: as a user rule and as a parent-walk workspace rule. The user accepts the cost. Document it; do not remove either copy.
- `~/.cursor/plugins` is not used: a plugin's `rules` folder may not be a link pointing outside the plugin, and the loader skips it without a message (observed on this machine, unverified elsewhere).
- The names `Explore` and `general-purpose` collide with Cursor's built-ins. Probe on 2026-10-11: they are listed as types, but the file text never arrives; `review` arrived. Launch `delegate-explore`, `delegate-worker` and `delegate-review`. The same flat folder also holds Claude Code's `Explore.md`, `general-purpose.md`, `review.md` and Codex's `.toml` files; launch only the `delegate-*` types. Cursor `readonly: true` puts a subagent in Ask mode, which refuses the shell entirely (even `ls`) — verified 2026-10-11 — so it is NOT used. Roles are defined by what they may write (explore: only `.debug/<task>/`; worker: its brief's files plus `.debug/<task>/`; review: only `.debug/<task>/review-<n>.md`), enforced by the sandbox, the instruction, and the orchestrator's `git status --porcelain` snapshot before and after each explore or review run. The agent file's `model:` is `grok-4.7-xhigh`. Cursor does not refuse a name it does not offer. If this chat's subagent list lacks the delegate slug, do not launch; say so. Never pass `inherit`. The agent list and rules can refresh during a chat; if a type is missing, start a new chat. Cursor's Grep tool for a delegate searches only workspace folders; Read works on any path. Cursor also reads agents from `.claude/agents` and `.codex/agents`, and `.cursor/` wins when names conflict (cursor.com/docs/subagents); the Claude files may show up under their shadowed names — launch the `delegate-*` types. Subagents receive the always-applied rules (same probe).
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

## Zed

Zed's native agent is the orchestrator and launches sub-agents itself: `spawn_agent` takes the brief as `message` and the model as `model` — the exact id `list_agents_and_models` prints, `x_ai_subscribed/grok-4.7` for row 1 — plus `session_id` to resume. It has no effort argument and no agent type, and Zed has no agent definition files for native sub-agents: there is nothing to link under `agents/`, and the brief's role block is the delegate's whole instruction set. A sub-agent gets the parent's system prompt (the rule included — the gate line makes it skip it) and the parent's tools minus `spawn_agent`. The rule's gate is what rejects a brief without its block here: the personal `AGENTS.md` reaches every sub-agent, so a message that opens with the gate line and lacks the block gets `BRIEF REJECTED — standing rules missing`. A bare `hello` without the gate line is answered as chat, not rejected.

Zed's folder is `~/.config/zed` (`%APPDATA%\Zed` on Windows); on this machine it may be a symlink — `ls -la` it and follow it.

| Item | Link | Points to |
| --- | --- | --- |
| the rule | `~/.config/zed/AGENTS.md` | `$REPO/rules/delegation.md` (or `$REPO/AGENTS.md`, which links to it) |
| this skill | `~/.agents/skills/enable-delegation` | `$REPO/skills/enable-delegation` (flat: a direct child of `~/.agents/skills`) |

1. `~/.config/zed/AGENTS.md` resolves to `$REPO/rules/delegation.md` (`ls -la`, then `head -n 3` shows the rule's frontmatter).
2. `~/.agents/skills/enable-delegation/SKILL.md` resolves to this file, and `skill` lists `enable-delegation`.
3. `list_agents_and_models` lists `x_ai_subscribed/grok-4.7` (the SuperGrok subscription is signed in) and `anthropic/claude-sonnet-5-5` (row 2).
4. `settings.json` carries the block below, with `agent.subagent_model` a sibling of `agent.default_model` (not inside `sandbox_permissions`), the row-1 model, `enable_thinking: true`, `effort: "xhigh"`. Look, don't rewrite: the file is the user's; show the block and the diff, the user pastes it. With `tool_permissions.default: "allow"` the agent reads, edits and runs sandboxed commands without a dialog; `delete_path` and a recursive `rm` still ask; sandbox escalations (`allow_hosts`, `fs_write_paths`, `unsandboxed`) always ask because the three `allow_*` flags stay false. `write_paths` and `network_hosts` are the user's choice: list only the project parents and hosts they want every delegate to reach without a dialog.

```json
"agent": {
  "subagent_model": {
    "provider": "x_ai_subscribed",
    "model": "grok-4.7",
    "enable_thinking": true,
    "effort": "xhigh"
  },
  "tool_permissions": {
    "default": "allow",
    "tools": {
      "delete_path": { "default": "confirm" },
      "terminal": {
        "always_confirm": [
          { "pattern": "\\brm\\s+(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)\\b" }
        ]
      }
    }
  },
  "sandbox_permissions": {
    "write_paths": [],
    "network_hosts": [],
    "allow_all_hosts": false,
    "allow_fs_write_all": false,
    "allow_unsandboxed": false
  }
}
```

5. the effort: `xhigh` is the rule's value, and Zed's docs do not list the levels grok-4.7 accepts. Only the user can check: the thinking/effort control in the Agent Panel's model picker, with Grok 4.7 selected, shows the levels — on this machine it offers Extra High, which is `xhigh` in `settings.json` (the user confirmed it). If a later Zed or model drops it, the user picks the highest shown and the orchestrator changes the table in the rule to match.
6. a sub-agent cannot spawn: the probe below reports no `spawn_agent` in its tool list.
7. sibling project folders the delegates must write to are under `write_paths`; the sandbox already allows the open project and `/tmp`.

Probes P1–P4 below apply; launch each as `spawn_agent` with `model: x_ai_subscribed/grok-4.7`. P1 in Zed is the gate line without the block — the message `# Brief — explore: probe`, a blank line, then `Reply with the single word PONG` — because a bare `hello` carries no gate line and is answered as chat; the reply must be exactly `BRIEF REJECTED — standing rules missing`. P2: add to the explore task "then quote the line of your system prompt that names your model, and say whether `spawn_agent` is among your tools" — the line must read "You are powered by the model named Grok 4.7" and the answer must be no (item 6). P3: Zed's own record is its log — Linux `~/.local/share/zed/logs/Zed.log` (other platforms unverified) — one `Thread::send called with model: Grok 4.7` line per launch; note the log's line count before the launches and read only the lines after it. P4: a `git status --porcelain` snapshot of the project taken before the launches must be unchanged after them.

## Probes

In a new chat or session, for every tool.

P1. Launch each delegate type with the bare prompt `hello`. The reply must be exactly `BRIEF REJECTED — standing rules missing`. In Zed the prompt is the gate line without the block instead (the Zed section): there the rule's gate rejects, not an agent file.

P2. Launch with a proper brief: the gate line `# Brief — <role>: <title>`, the role's block pasted verbatim from the rule's "Role blocks" section, then the task "quote the sentence of your standing rules that begins with: Your conclusions / Green mechanical / Quote the acceptance". The reply quotes that role's sentence.

| Role | Claude Code type | Cursor and Codex type | Zed | Sentence |
|---|---|---|---|---|
| explore | `Explore` | `delegate-explore` | `spawn_agent`, model from the table | Your conclusions are only as good as the evidence you attach to them. |
| worker | `general-purpose` | `delegate-worker` | the same | Green mechanical checks come before the reviewer, never after. |
| review | `review` | `delegate-review` | the same | Quote the acceptance list before your first finding. |

P3. Read the model from the tool's own record, never from the agent's self-report. Cursor: the subagent card. Claude Code: the transcript — `~/.claude/projects/<project>/<session>/subagents/agent-<id>.jsonl` (a workflow agent: `…/subagents/workflows/<run>/agent-<id>.jsonl`, with `agent-<id>.meta.json` beside it holding the launch model and agent type); the first assistant line carries `message.model` (the model the API served) and `effort`; it sits after about a dozen attachment lines of up to 30K tokens, so read it with the Read tool at `offset` about 14 (12 to 16 for a direct launch) and `limit` 1, never the whole file — the sandboxed shell cannot see `~/.claude`, and delegates have no Glob to list the folder. Codex: the session log. Zed: the Zed log, one `Thread::send called with model:` line per launch — the Zed section names the path. It is the pinned one. Do not ask the agent which model it is.

P4. Explore and review only: ask each, with a proper brief — the gate line `# Brief — <role>: <title>`, that role's block pasted verbatim from the rule's "Role blocks" section, then the task — to create a file outside `.debug/` (for example `probe-outside.txt` in the repo root). They must refuse by instruction (Cursor, Claude Code) or be blocked by the sandbox (Codex). `git status --porcelain` of the target must be unchanged. A path inside `.debug/` is not this probe: explore may write `.debug/<task>/` and review may write `.debug/<task>/review-<n>.md`.

P5. Claude Code only, in a new session: a Workflow with one `agent()` that names no `agentType` and no `model`, task "Reply with the single word PONG". Read the model as in P3: it must be the Claude Code entry of the table's row 2, the Sonnet slug (`claude-sonnet-5-5`), never a Grok id. The reply is PONG, not a rejection, because no agent file reaches that type — which is why every stage still names `agentType`.

Claude Code's own automatic `Explore` launches arrive without a block and are rejected — that is the design working; the orchestrator resends a proper brief.

## Grok (Claude Code only, optional)

Only in Claude Code (in Cursor and Codex skip this section and ask nothing about Grok), after the Claude Code checks and P1–P5. The opt-in is `DELEGATE_TO=grok` in `settings.json` `env`: the orchestrator then runs the script `grok-delegate` (`$REPO/hooks/grok-delegate.sh`) as a background Bash call and no Claude agent runs; unset, or any other value, leaves the delegates on Sonnet (row 2). This section writes nothing: it shows the user the lines to add, and the user runs the skill again.

1. **Detect:** `command -v grok`. Not found: one Finish row, "Grok: not installed — skipped"; ask nothing and stop here.
2. **Ask** through the question tool (Claude Code: AskUserQuestion): "Delegate to Grok 4.7 in Claude Code?" Two options, a pro and a con each, one line each:
   - Yes. Pro: cheap delegates on a non-Claude model. Con: the setup below, and the user's Grok quota spent on every delegate run.
   - No. Pro: nothing to set up and no Grok quota spent. Con: the delegates stay on Sonnet, no second model family.
3. **No:** `DELEGATE_TO` stays unset (already `grok` in `settings.json` `env`: show the line; the user removes it). Finish row "Grok: declined — delegates stay on Sonnet". Stop here.
4. **Yes:** G1–G6 and the settings lines below, in this order: G1; the `~/.grok` lines in `sandbox.filesystem`, then G2; the script link and the other settings lines except `DELEGATE_TO=grok`; G3 and G4, then the `GROK_SANDBOX` line from G4; G5 and G6; `DELEGATE_TO=grok` last, so the rule never meets a half-set-up Grok.

**Script.** The user makes the link (macOS and Linux; Windows: not set up): `ln -s "$REPO/hooks/grok-delegate.sh" ~/.claude/hooks/grok-delegate.sh`, then `ln -s "<real path of ~/.claude/hooks>/grok-delegate.sh" ~/.local/bin/grok-delegate`; every hop must be a path the sandbox can read (it hides `~/.claude`, and a link through a folder outside its allow list resolves to nothing there). Check `command -v grok-delegate`: missing, show that line; something else at that path, ✗ and leave it. It needs the allow entry `Bash(grok-delegate *)`; `Bash(grok *)` stays for the G4 probes.

**Settings lines.** Show the user each line missing from `~/.claude/settings.json`; this skill writes nothing there. One fragment to merge by hand (`/home/<user>/.grok` is the absolute path of `~/.grok`; `GROK_SANDBOX` is the G4 result: `strict`, `devbox` or `off`; the `GROK_CLAUDE_*`, `GROK_MEMORY` and `GROK_SUBAGENTS` lines keep this project's Claude context and subagents out of grok; the telemetry and feedback lines are optional privacy):
```json
{
  "env": {
    "GROK_SANDBOX": "<G4 result>", "GROK_SUBAGENTS": "0", "GROK_MEMORY": "0", "GROK_DISABLE_AUTOUPDATER": "1",
    "GROK_CLAUDE_HOOKS_ENABLED": "0", "GROK_CLAUDE_AGENTS_ENABLED": "0", "GROK_CLAUDE_RULES_ENABLED": "0",
    "GROK_CLAUDE_SKILLS_ENABLED": "0", "GROK_CLAUDE_MCPS_ENABLED": "0", "GROK_TELEMETRY_ENABLED": "0",
    "GROK_TELEMETRY_TRACE_UPLOAD": "0", "GROK_FEEDBACK_ENABLED": "0", "DELEGATE_TO": "grok"
  },
  "sandbox": {
    "filesystem": { "allowRead": ["/home/<user>/.grok"], "allowWrite": ["/home/<user>/.grok"] },
    "network": { "allowedDomains": ["cli-chat-proxy.grok.com", "auth.x.ai"] }
  },
  "permissions": { "allow": ["Bash(grok *)", "Bash(grok-delegate *)"], "deny": ["Bash(*/.grok/auth.json*)"] }
}
```
Only when `sandbox.filesystem.denyRead` covers `/tmp` (for example `/**` or `/`), also merge `{"sandbox": {"filesystem": {"allowRead": ["/tmp/claude-http-*.sock"]}}}`; without it every outbound connection aborts (`Proxy CONNECT aborted`, exit 56).

Never a `Read(~/.grok/auth.json)` deny: Claude Code copies `Read(…)` denies into the sandbox's read-deny list, and grok then cannot read its own login. Never `GROK_FOLDER_TRUST=0` (it ungates project hooks, MCP and rules) or `--trust` (it persists). The account-level data-sharing flag is seen and changed only through `/privacy` in grok's interactive TUI; the env lines do not touch it.

- G1. `command -v grok` and `grok --version` both print; otherwise stop and tell the user.
- G2. `find "$HOME/.grok" -maxdepth 1 -name auth.json -size +0c` prints the path when the login file is non-empty (never opened; the command avoids the literal path, which the deny line would match). Run it only after the `~/.grok` `allowRead` line is in place; nothing printed means not logged in, and the user logs in.
- G3. From the sandbox, `curl -s -o /dev/null -w '%{http_code}'` to `https://cli-chat-proxy.grok.com/` and `https://auth.x.ai/`: any HTTP status passes. Exit 56 with `Proxy CONNECT aborted` means the socket fragment above is missing.
- G4. With the `env` lines in place (`printenv GROK_CLAUDE_HOOKS_ENABLED` prints `0`) and after saying each run spends a little of the user's Grok quota, for `strict`, then `devbox`, run `grok -p "Reply with the single word OK" --model grok-4.7 --max-turns 1 --no-auto-update --output-format plain --sandbox <profile>`: the first with exit 0 and `OK` in its output is the `GROK_SANDBOX` value. Neither passes: run it with `--sandbox off` (then `off` is the value and Claude Code's sandbox is the only confinement; if `off` fails too, stop). A `strict` refusal with a hook write-deny or bwrap-plan error so far came from a missing `.claude/settings.json` (a `/dev/null` placeholder in the sandbox; grok 1.0.70). On `devbox`, warn the user that it confines almost nothing beyond `off`: it reads anything, writes every top-level directory except `/data`, allows the network, and is meant for disposable VMs.
- G5. Write a minimal valid brief under `.debug/` (gate line `# Brief — explore: <title>`, the explore block pasted verbatim from the rule's "Role blocks" section, the task "list the top-level entries of `<dir>`", and `Working directory: <dir>`) and run `grok-delegate explore "<absolute path>"`. `printenv GROK_SANDBOX` must print the G4 result first, else the script runs with grok's own default (`off`, unless `config.toml` sets `[sandbox] profile`); no new session is needed. Pass: line 1 `GROK OK`, line 2 `session <UUID>`, then a listing; it spends a little quota.
- G6. `grok-delegate explore "<file without the block>"`, for example a file holding only `hello`: the output is exactly `BRIEF REJECTED — standing rules missing` and the exit code is 3; grok does not run, so no session and no quota.

## Finish

Report one short table — item, and ✓ / ✗ / "you check" — then what the user still has to do. In Claude Code, the Grok step adds "Grok: not installed — skipped", or "Grok: declined — delegates stay on Sonnet", or after a yes one row each for the script (✓ when `command -v grok-delegate` finds it), G1–G6 (✓ / ✗, G4 naming the profile) and the settings lines (`DELEGATE_TO=grok` last). Last step for every tool: in a new session ask "what always-applied rules or global instructions do you see?" — it must quote the delegation rule back (Claude Code: `/context` lists `delegation.md`). Then run the probes.
