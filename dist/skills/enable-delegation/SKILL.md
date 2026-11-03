---
name: enable-delegation
description: >-
  Set up or check the delegation rule for the tool you are running in — Claude Code, Cursor, Codex or Zed — on macOS, Linux or Windows.
  The user makes the links: the rule (role blocks included) and the nine thin agent files (Zed: the rule and this skill only).
  For Cursor, the enable-delegation skill must be available on its own — a symlink to that folder, or a copy of it.
  Checks the three delegate roles against the rule's table, never overwrites the user's files, and lists what only the user can do.
  Run it once in each tool, and again after the rule's table or a role block changes.
  Also lists each tool's documented switches for telemetry, feedback and training data, with the warning that documentation is not a guarantee.
---

# Enable delegation

Set up **only the tool you are running in** — your own system prompt tells you which one; if it doesn't, ask. Zed's says "You are the Zed coding agent running inside the Zed editor".

**Sources — everything you place comes from the repo's `dist` folder, nothing from memory.** Resolve links first. The path you were given may be `~/.cursor/skills/enable-delegation/…`, `~/.claude/skills/enable-delegation/…` or `~/.agents/skills/enable-delegation/…` (Zed). When `enable-delegation` is a symlink, the real file is `dist/skills/enable-delegation/SKILL.md` and `$REPO` is two levels above that real file (the `dist` folder). When it is a copy, walking up from the copy lands in the user's skills folder, which is not `$REPO`; `$REPO` is the clone's `dist`. Call `$REPO` wherever the clone lives; never a machine path. The repo root above it holds `README.md`: how to start and how it works. Sandbox, permission and hook settings are the user's security settings, outside this project; the rule makes the orchestrator read them at the start of every session ("Controlling delegates", item 2).
- `$REPO/rules/delegation.md` — the rule. Its model table gives each tool's model id and the effort per role (columns Explore / Worker / Reviewer). The three role blocks live in it under "Role blocks". `rules/delegation.mdc` is the existing link to `delegation.md` for Cursor.
- `$REPO/agents/` — nine thin hand-written files, each only rejecting a brief that lacks its role block. A brief is the gate line, the role block pasted verbatim from the rule, and the task. A brief without them gets `BRIEF REJECTED — standing rules missing`. Editing a role means editing its block in the rule, nowhere else.
  - Cursor: `delegate-explore.md`, `delegate-worker.md`, `delegate-review.md` (the row-1 Cursor model and table effort).
  - Claude Code: `Explore.md`, `general-purpose.md`, `review.md` (the row-2 Claude Code model, `effort: xhigh`, `permissionMode: dontAsk`, `omitClaudeMd: true`; explore and review have `disallowedTools: Edit, NotebookEdit`).
  - Codex: `delegate-explore.toml`, `delegate-worker.toml`, `delegate-review.toml` (the row-3 Codex model, `model_reasoning_effort = "xhigh"`, `sandbox_mode` `read-only` for explore and review, `workspace-write` for the worker).
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

Link `$REPO/agents`. Claude Code scans the agents folder recursively and follows symlinks. The flat folder also holds the other tools' files: Cursor's `delegate-explore.md`, `delegate-worker.md`, `delegate-review.md`, and Codex's `delegate-explore.toml`, `delegate-worker.toml`, `delegate-review.toml`. Launch `Explore`, `general-purpose` and `review`. The `.toml` files are ignored: the session's agent list shows no type with a Codex description. Definitions added mid-session need a restart.

The names `Explore`, `general-purpose` and `review` override Claude Code's built-ins of those names, so a spawn that names no type or no model still lands on the cheap model, and `general-purpose` is what an unnamed spawn falls back to. The Workflow tool's default type is the exception: see the `CLAUDE_CODE_SUBAGENT_MODEL` check below and probe P5.

Check the three agent files (`Explore.md`, `general-purpose.md`, `review.md`) against the table: `model:` is the Claude Code entry of row 2; `effort:` is `xhigh`; each has `permissionMode: dontAsk` and `omitClaudeMd: true`; explore and review have `disallowedTools: Edit, NotebookEdit`. Then check that nothing overrides them: `CLAUDE_CODE_EFFORT_LEVEL` must not be set — not in the `env` block of `~/.claude/settings.json`, not in the shell (`printenv CLAUDE_CODE_EFFORT_LEVEL` prints nothing) — because that variable forces its level on every delegate over the agent file and over a run stage's effort (verified). If it is set, tell the user which file has it and stop there; the user removes it. The same `env` block must contain `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` set to `1` (the orchestrator drives every loop; a child must not spawn). `~/.claude/settings.json` is the user's own file, outside this project: this skill reads those two keys and writes nothing there. Required third net: the same `env` block must contain `CLAUDE_CODE_SUBAGENT_MODEL` set to the Claude Code entry of row 2 — never a row-1 id, even when the user opts into Grok. It is only a default — the launch model and the agent-file `model:` win over it — but it is the one thing that reaches the Workflow tool's built-in default type (`workflow-subagent`, used by a script's `agent()` that names no `agentType`), which no agent file overrides. Missing: show the user the line to add; this skill writes nothing there. `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` stays unset: it would override the launch model too. Agent-file changes, and new agent files, take effect only in a new session (verified): verify there by starting an `Explore` delegate with a proper brief: the gate line `# Brief — explore: <title>`, the explore block pasted verbatim from the rule's "Role blocks" section, then the task "Reply with the names of any always-applied rules or CLAUDE.md files you can see, or 'none visible'" — it must answer "none visible". Then run the probes below.

## Cursor

Cursor reads rules, agents and skills under `~/.cursor`. The user links them; no plugin is used. The link targets must lie under the home folder — Cursor drops agent files reached through a link that leaves it.

| Item | Link | Points to |
|---|---|---|
| Rule | `~/.cursor/rules` | `$REPO/rules` (its `delegation.mdc` → `delegation.md` is the link Cursor's `*.mdc` glob needs) |
| Delegate agents | `~/.cursor/agents` | `$REPO/agents` |
| Skill | `~/.cursor/skills/enable-delegation` | `$REPO/skills/enable-delegation` |

The skills folder stays the user's. This check passes when `enable-delegation` is available there, and it asks for nothing else. Two forms pass: a symlink `~/.cursor/skills/enable-delegation` → `$REPO/skills/enable-delegation`, which follows later edits of the skill, or a copy of that folder. A copy is a passing form, including where a symlink cannot be created — on Windows a file symlink needs Developer Mode, and without it the copy is the way. A copy does not follow later edits; after this skill changes, copy the folder again. The generic ✗ for "something else is there" does not apply to a copy of this skill: a real directory at that path which contains this skill is ✓. Other entries in the skills folder are the user's; leave them. Do not replace `~/.cursor/skills` with a link or a copy of `$REPO/skills`. If the skills folder is already that whole-folder link, the skill is available, so the availability check still passes — report that this hides any other skills, and do not tell the user to relink the folder to fix it. When the skill is missing, show `ln -s $REPO/skills/enable-delegation ~/.cursor/skills/enable-delegation` on macOS/Linux, or a copy of the folder where a symlink cannot be made. Never show a command that links `~/.cursor/skills` itself to `$REPO/skills`.

How Cursor uses them:
- Rules are collected from `.cursor/rules/*.mdc` of the workspace and of every parent folder, so the home link covers each workspace under the home folder and nothing outside it. When `~/.cursor` is an ancestor of a workspace, the rule is injected twice: as a user rule and as a parent-walk workspace rule. The user accepts the cost. Document it; do not remove either copy.
- `~/.cursor/plugins` is not used: a plugin's `rules` folder may not be a link pointing outside the plugin, and the loader skips it without a message.
- The names `Explore` and `general-purpose` collide with Cursor's built-ins. They are listed as types, but the file text never arrives; `review` arrived. Launch `delegate-explore`, `delegate-worker` and `delegate-review`. The same flat folder also holds Claude Code's `Explore.md`, `general-purpose.md`, `review.md` and Codex's `.toml` files; launch only the `delegate-*` types. Cursor `readonly: true` puts a subagent in Ask mode, which refuses the shell entirely (even `ls`) — so it is NOT used. Roles are defined by what they may write (explore: only `.debug/<task>/`; worker: its brief's files plus `.debug/<task>/`; review: only `.debug/<task>/review-<n>.md`), enforced by the sandbox, the instruction, and the orchestrator's `git status --porcelain` snapshot before and after each explore or review run. The agent file's `model:` is the Cursor model from row 1. Cursor does not refuse a name it does not offer. If this chat's subagent list lacks the delegate slug, do not launch; say so. Never pass `inherit`. The agent list and rules can refresh during a chat; if a type is missing, start a new chat. Cursor's Grep tool for a delegate searches only workspace folders; Read works on any path. Cursor also reads agents from `.claude/agents` and `.codex/agents`, and `.cursor/` wins when names conflict (cursor.com/docs/subagents); the Claude files may show up under their shadowed names — launch the `delegate-*` types. Subagents receive the always-applied rules (same probe).
- Do not point Settings → Models → Task Models → Explore Subagent Model at this setup. That setting is the built-in `explore`, not `delegate-explore`.

Checks, in a new chat:
- "What always-applied rules do you see?" — it must quote the rule.
- "Which subagents do you have?" — `delegate-explore`, `delegate-worker` and `delegate-review` must be listed. Do not launch the built-in `Explore` or `general-purpose` types, and never pass `inherit`.
- The probes below.

## Codex

The Codex delegate id is the Codex column of row 3 in the rule table; this skill does not duplicate it. The installed catalog is printed by `codex debug models --bundled` (or `/model` in the TUI), and the catalog entry must be checked for the table's effort. Local availability and default selection are machine checks, not claims made by this portable skill; there is no fallback id.

Codex's folder is `~/.codex`; when `CODEX_HOME` is set, the configuration reference places Codex's own files in that folder instead, so use it. Call it `<codex>`. Until every item below passes, a Codex orchestrator treats read-only as unenforced and tells the user to run this skill.

Each item below remains unconfirmed until its stated check passes:

1. `<codex>/AGENTS.md` links to `$REPO/rules/delegation.md`. If `<codex>/AGENTS.override.md` exists, Codex reads it instead of `AGENTS.md`: don't link, show it to the user and merge by hand. In a new session, "What global instructions do you see?" must quote the rule.
2. `<codex>/agents` links to `$REPO/agents` (the flat folder). Create `<codex>` if the directory is missing. If `<codex>/agents` is a real directory (old copies), stop and show it; the user runs `ln -sfn` only for a missing path or an existing symlink. The three files are `delegate-explore.toml`, `delegate-worker.toml`, `delegate-review.toml`. The same folder holds the other tools' `.md` files (`Explore.md`, `general-purpose.md`, `review.md`, `delegate-explore.md`, `delegate-worker.md`, `delegate-review.md`). Whether Codex ignores those `.md` files is a runtime check. Do not add a file named `default`, `worker` or `explorer`: a custom file with a built-in's name replaces it. Launch `delegate-explore`, `delegate-worker` and `delegate-review`.
3. Each TOML has `name` (the type you spawn), `description` (starts with the tool's name, Codex), the model from row 3, `model_reasoning_effort = "xhigh"`, `sandbox_mode` (`"read-only"` for `delegate-explore` and `delegate-review`, `"workspace-write"` for `delegate-worker`), and `developer_instructions` as a triple-quoted string.
4. `[agents]` in `<codex>/config.toml`. Look, don't rewrite; tell the user what to change. `max_depth` stays `1` (the orchestrator drives every loop; children do not spawn). `default_subagent_model` matches the Codex model in row 3. `agents.enabled` and `features.multi_agent` must not be `false` (both default to on).
5. AGENTS.md reaches subagents (the global file and the project AGENTS.md; no per-agent opt-out). The rule's top gate is what protects them. `project_doc_max_bytes = 0` would suppress project docs only, so do not set it to hide this rule.
6. The probes below, spawning `delegate-explore`, `delegate-worker` and `delegate-review`. Read the model from the session log, never from the agent's self-report. Expect the Codex ID from row 3. Confirm the id with `codex debug models --bundled` (or `/model` in the TUI). A spawn error that names the model means that id is not on this account: stop and tell the user.

```
prefix_rule(
    pattern = ["git", ["commit", "push", "merge", "rebase", "reset", "stash", "cherry-pick", "revert", "checkout", "switch", "restore", "clean", "add", "rm", "mv", "am", "apply", "tag", "branch", "worktree", "remote", "submodule", "gc", "prune", "filter-branch", "update-ref", "symbolic-ref"]],
    decision = "forbidden",
    justification = "Delegates never change git state; the user commits. Read with git status, diff, log, show, blame, show-ref.",
    match = ["git commit -m x", "git push origin main", "git checkout -b probe", "git stash"],
    not_match = ["git status", "git diff --stat", "git log --oneline", "git show HEAD", "git blame README.txt"],
)
```

8. `codex execpolicy check` must report `forbidden` for what's prohibited; anything else means the rules file was not read or is malformed — fix that before the next step. Then, in a throw-away git repo, spawn `delegate-worker` with a proper brief: the gate line `# Brief — worker: <title>`, the worker block pasted verbatim from the rule's "Role blocks" section, then the task "Run `git commit --allow-empty -m probe` and report the exact result." — it must be blocked. If it commits, the rules govern only commands outside the sandbox: say so; the rule's text stays the control.
9. Sibling project folders the worker must edit go into `writable_roots` under `[sandbox_workspace_write]`; inspect this setting and report it, rather than inferring effective runtime paths from the file alone.
10. Delegates' read-only holds only when the orchestrator session runs without live permission overrides. Docs: the parent turn's live runtime overrides are reapplied to children and beat the agent file's `sandbox_mode`. Never run the Codex orchestrator with `--yolo` / `--dangerously-bypass-approvals-and-sandbox` when read-only delegates matter; the write-must-fail probe is what proves it. Children also inherit the parent's `mcp_servers` where the file is silent; assume the sandbox does not govern what an MCP server does, and a read-only brief names the MCP tools the delegate may not call.

## Zed

Zed's native agent is the orchestrator and launches sub-agents itself: `spawn_agent` takes the brief as `message` and the model as `model` — the exact row-1 id that `list_agents_and_models` prints — plus `session_id` to resume. It has no effort argument and no agent type, and Zed has no agent definition files for native sub-agents: there is nothing to link under `agents/`, and the brief's role block is the delegate's whole instruction set. A sub-agent gets the parent's system prompt (the rule included — the gate line makes it skip it) and the parent's tools minus `spawn_agent` and `create_thread`. The rule's gate is what rejects a brief without its block here: the personal `AGENTS.md` reaches every sub-agent, so a message that opens with the gate line and lacks the block gets `BRIEF REJECTED — standing rules missing`. A bare `hello` without the gate line is answered as chat, not rejected.

Zed's folder is `~/.config/zed` (`%APPDATA%\Zed` on Windows); on this machine it may be a symlink — `ls -la` it and follow it.

| Item | Link | Points to |
| --- | --- | --- |
| the rule | `~/.config/zed/AGENTS.md` | `$REPO/rules/delegation.md` (or `$REPO/AGENTS.md`, which links to it) |
| this skill | `~/.agents/skills/enable-delegation` | `$REPO/skills/enable-delegation` (flat: a direct child of `~/.agents/skills`) |

1. `~/.config/zed/AGENTS.md` resolves to `$REPO/rules/delegation.md` (`ls -la`, then `head -n 3` shows the rule's frontmatter).
2. `~/.agents/skills/enable-delegation/SKILL.md` resolves to this file, and `skill` lists `enable-delegation`.
3. `list_agents_and_models` lists the row-1 and row-2 models (the first may require the user's provider subscription). If the row-1 id is missing, the rule's pin paragraph applies: row 2 is the delegate model, the block below takes row 2, and the Finish table gets a row naming the model row used.
4. `settings.json` carries the block below, with `agent.subagent_model` a sibling of `agent.default_model` (not inside `sandbox_permissions`), the row-1 model, `enable_thinking: true`, `effort: "xhigh"`. The rule's Zed ID is `<provider>/<model>`: split the selected row's ID (row 1, or row 2 per item 3) at its first `/`, put the prefix in `provider` and the remainder in `model`, then replace both placeholders before pasting. Look, don't rewrite: the file is the user's; show the block and the diff, the user pastes it. With `tool_permissions.default: "allow"` the agent reads, edits and runs sandboxed commands without a dialog; `delete_path` and a recursive `rm` still ask; sandbox escalations (`allow_hosts`, `fs_write_paths`, `unsandboxed`) always ask because the three `allow_*` flags stay false. `write_paths` and `network_hosts` are the user's choice: list only the project parents and hosts they want every delegate to reach without a dialog.

```json
"agent": {
  "subagent_model": {
    "provider": "<provider from row 1>",
    "model": "<model from row 1>",
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

5. the effort: `xhigh` is the rule's value, and Zed's docs do not list the levels the row-1 model accepts. Only the user can check: the thinking/effort control in the Agent Panel's model picker, with the row-1 model selected, shows the levels — the user maps Extra High to `xhigh` in `settings.json`. If a later Zed or model drops it, the user picks the highest shown and the orchestrator changes the table in the rule to match.
6. a sub-agent cannot spawn: the probe below reports neither `spawn_agent` nor `create_thread` in its tool list.
7. sibling project folders the delegates must write to are under `write_paths`; the sandbox already allows the open project and `/tmp`.

Probes P1–P4 below apply; launch each as `spawn_agent` with the row-1 model from the rule table. P1 in Zed is the gate line without the block — the message `# Brief — explore: probe`, a blank line, then `Reply with the single word PONG` — because a bare `hello` carries no gate line and is answered as chat; the reply must be exactly `BRIEF REJECTED — standing rules missing`. P2: add to the explore task "then quote the line of your system prompt that names your model, and say whether `spawn_agent` or `create_thread` is among your tools" — the model line must name the row-1 model and the answer must be no to both (item 6). P3: Zed's own record is its log — Linux `~/.local/share/zed/logs/Zed.log`, macOS `~/Library/Logs/Zed/Zed.log`, Windows `C:\Users\<you>\AppData\Local\Zed\logs\Zed.log`, or the command `zed: open log` (zed.dev/docs/troubleshooting) — one model-selection line per launch; note the log's line count before the launches and read only the lines after it. P4: a `git status --porcelain` snapshot of the project taken before the launches must be unchanged after them.

## Probes

In a new chat or session, for every tool.

P1. Launch each delegate type with the bare prompt `hello`. The reply must be exactly `BRIEF REJECTED — standing rules missing`. In Zed the prompt is the gate line without the block instead (the Zed section): there the rule's gate rejects, not an agent file.

P2. Launch with a proper brief: the gate line `# Brief — <role>: <title>`, the role's block pasted verbatim from the rule's "Role blocks" section, then the task "quote the sentence of your standing rules that begins with: Your conclusions / Green mechanical / Quote the acceptance". The reply quotes that role's sentence.

| Role | Claude Code type | Cursor and Codex type | Zed | Sentence |
|---|---|---|---|---|
| explore | `Explore` | `delegate-explore` | `spawn_agent`, model from the table | Your conclusions are only as good as the evidence you attach to them. |
| worker | `general-purpose` | `delegate-worker` | the same | Green mechanical checks come before the reviewer, never after. |
| review | `review` | `delegate-review` | the same | Quote the acceptance list before your first finding. |

P3. Read the model from the tool's own record, never from the agent's self-report. Cursor: the subagent card. Claude Code: the transcript — `~/.claude/projects/<project>/<session>/subagents/agent-<id>.jsonl` (a workflow agent: `…/subagents/workflows/<run>/agent-<id>.jsonl`, with `agent-<id>.meta.json` beside it holding the launch model and agent type); the first assistant line carries `message.model` (the model the API served) and `effort`; it sits after about a dozen attachment lines of up to 30K tokens, so read it with the Read tool at `offset` about 14 (12 to 16 for a direct launch) and `limit` 1, never the whole file — the sandboxed shell cannot see `~/.claude`, and delegates have no Glob to list the folder. Codex: the session log. Zed: the Zed log, one `Thread::send called with model:` line per launch — the Zed section names the path; the line carries the model's display name (`Grok 4.7`), which `list_agents_and_models` pairs with the row-1 id. It is the pinned one. Do not ask the agent which model it is.

P4. Explore and review only: ask each, with a proper brief — the gate line `# Brief — <role>: <title>`, that role's block pasted verbatim from the rule's "Role blocks" section, then the task — to create a file outside `.debug/` (for example `probe-outside.txt` in the repo root). They must refuse by instruction (Cursor, Claude Code) or be blocked by the sandbox (Codex). `git status --porcelain` of the target must be unchanged. A path inside `.debug/` is not this probe: explore may write `.debug/<task>/` and review may write `.debug/<task>/review-<n>.md`.

P5. Claude Code only, in a new session: a Workflow with one `agent()` that names no `agentType` and no `model`, task "Reply with the single word PONG". Read the model as in P3: it must be the Claude Code entry of row 2, never the row-1 id. The reply is PONG, not a rejection, because no agent file reaches that type — which is why every stage still names `agentType`.

Claude Code's own automatic `Explore` launches arrive without a block and are rejected — that is the design working; the orchestrator resends a proper brief.

## Grok (Claude Code only, optional)

Only in Claude Code (in Cursor and Codex skip this section and ask nothing about Grok), after the Claude Code checks and P1–P5. The opt-in is `DELEGATE_TO=grok` in `settings.json` `env`: the orchestrator then runs the script `grok-delegate` (`$REPO/hooks/grok-delegate.sh`) as a background Bash call and no Claude agent runs; unset, or any other value, leaves the delegates on row 2. This section writes nothing: it shows the user the lines to add, and the user runs the skill again.

1. **Detect:** `command -v grok`. Not found: one Finish row, "Grok: not installed — skipped"; ask nothing and stop here.
2. **Ask** through the question tool (Claude Code: AskUserQuestion): "Delegate to the row-1 model in Claude Code?" Two options, a pro and a con each, one line each:
   - Yes. Pro: cheap delegates on a non-Claude model. Con: the setup below, and the user's Grok quota spent on every delegate run.
   - No. Pro: nothing to set up and no Grok quota spent. Con: the delegates stay on Sonnet, no second model family.
3. **No:** `DELEGATE_TO` stays unset (already `grok` in `settings.json` `env`: show the line; the user removes it). Finish row "Grok: declined — delegates stay on row 2". Stop here.
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
- G4. With the `env` lines in place (`printenv GROK_CLAUDE_HOOKS_ENABLED` prints `0`) and after saying each run spends a little of the user's Grok quota, derive the unqualified row-1 model by taking the remainder after the first `/` in the row-1 Zed ID; replace `<unqualified row-1 model>` before running `grok -p "Reply with the single word OK" --model <unqualified row-1 model> --max-turns 1 --no-auto-update --output-format plain --sandbox <profile>` for `strict`, then `devbox`: the first with exit 0 and `OK` in its output is the `GROK_SANDBOX` value. Neither passes: run it with `--sandbox off` (then `off` is the value and Claude Code's sandbox is the only confinement; if `off` fails too, stop). A `strict` refusal with a hook write-deny or bwrap-plan error so far came from a missing `.claude/settings.json` (a `/dev/null` placeholder in the sandbox; grok 1.0.70). On `devbox`, warn the user that it confines almost nothing beyond `off`: it reads anything, writes every top-level directory except `/data`, allows the network, and is meant for disposable VMs.
- G5. Write a minimal valid brief under `.debug/` (gate line `# Brief — explore: <title>`, the explore block pasted verbatim from the rule's "Role blocks" section, the task "list the top-level entries of `<dir>`", and `Working directory: <dir>`) and run `grok-delegate explore "<absolute path>"`. `printenv GROK_SANDBOX` must print the G4 result first, else the script runs with grok's own default (`off`, unless `config.toml` sets `[sandbox] profile`); no new session is needed. Pass: line 1 `GROK OK`, line 2 `session <UUID>`, then a listing; it spends a little quota.
- G6. `grok-delegate explore "<file without the block>"`, for example a file holding only `hello`: the output is exactly `BRIEF REJECTED — standing rules missing` and the exit code is 3; grok does not run, so no session and no quota.

## Telemetry and training data

Run this part in the tool you are running in (and for grok when the Grok section is in use), after the checks above. Same rules: look, don't write; show the user the missing lines (for a TOML file, merged into the tables it already has — a repeated table header is invalid); account-level choices are "you check", with the steps listed under each tool. Three kinds, never confused: **telemetry** (usage metrics, crash reports), **feedback** (explicit submissions, surveys, thread sharing) and **training** (the vendor learning from your content — mostly an account setting, not a file). Update checks are listed as optional: they are not tracking, and off means no update checks.

**Warning.** Everything below is what each vendor's documentation said when skill updated and can drift, so verify. This skill cannot see what a binary or a server actually sends, stores or trains on, and the texts change without notice: treat the switches as documented intent, not a guarantee, and re-check them after each tool update. Whatever you type into an agent still reaches the model provider — that is the feature, not telemetry — and the provider's own retention applies on top; the notes below name what is known.

### Claude Code — `~/.claude/settings.json` → `env`

```json
"DISABLE_TELEMETRY": "1", "DISABLE_ERROR_REPORTING": "1", "DISABLE_FEEDBACK_COMMAND": "1"
```

`DISABLE_TELEMETRY` stops the usage metrics and the session surveys (`DO_NOT_TRACK=1` is the same switch); `DISABLE_ERROR_REPORTING` the error reports (messages and stack traces to a third-party service); `DISABLE_FEEDBACK_COMMAND` the `/feedback`, `/bug` and `/share` commands and Claude-drafted feedback. The umbrella `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: "1"` covers telemetry, error reporting and `/feedback`, and also stops auto-updates and release notes — any non-empty value disables, `0` included, so to turn things back on unset it, never set it to `0`. Optional: `DISABLE_AUTOUPDATER: "1"` (update); `CLAUDE_CODE_DISABLE_OFFICIAL_MARKETPLACE_AUTOINSTALL: "1"` (update: the official plugin marketplace auto-install, which the umbrella does not cover); `"skipWebFetchPreflight": true` in the settings JSON, which stops the domain safety check WebFetch sends to Anthropic before fetching — WebFetch then no longer consults Anthropic's blocklist, so pair it with WebFetch permission rules. `CLAUDE_CODE_ENABLE_TELEMETRY` stays unset: it exports OpenTelemetry to your own collector, not to Anthropic. A managed `env` block can force OpenTelemetry back on — say so when one exists.
You check: training is an account choice, not a variable. On Free, Pro, Max and Ultra accounts, sessions — Claude Code included — are used for training while the data-training setting at claude.ai/settings/data-privacy-controls is on; turn it off. API-key, Team and Enterprise use is not trained on by default.
- Account side (Free, Pro, Max, Ultra — Claude Code sessions under that login included): your name → **Settings** → **Privacy** → **Help improve our AI models** ("Allow the use of your chats and coding sessions to train and improve Anthropic AI models"): toggle off (the page `claude.ai/settings/data-privacy-controls`; the same walk on mobile. On means those sessions train Claude and are kept 5 years; off, 30 days; Incognito chats are never used either way. The same page has **Your feedback → Manage** and **Delete sessions stored by Anthropic** ("Permanently delete Anthropic's server-side copies of your Claude Code sessions. Sessions stored locally on your computer aren't affected.").
- Team, Enterprise, API: not trained on by default; Anthropic may train if you explicitly report feedback or bugs (the thumbs up/down — the whole conversation, kept up to 5 years) "or otherwise choose to allow us to use your data" (for example an organization admin's Development Partner Program opt-in, first-party API only). API organizations: the Console's **Settings → Privacy** page (`platform.claude.com/settings/privacy`) holds the switches — **Join our Development Partner Program**: leave unjoined ("voluntarily sharing your organization's Claude Code sessions with Anthropic to improve our services, including model training"; "previously shared data cannot be deleted"); **Allow user feedback**: off ("Reports include the full prompt, response, and feedback for future improvements to our models"); **Allow Claude Code metrics logging**: your choice — "metrics collection to track Claude Code usage across your organization", shown on the Console's Claude Code analytics page (usage and spend per user), with a **Delete data** button beneath the toggle on the same Privacy page ("Delete all collected metrics data. This action cannot be undone."); **Data retention** shows the organization default "On · 30 days", and turning it off is Zero Data Retention via **Contact support**. Claude for Work (Team, Enterprise): a Primary Owner or Owner stops members' feedback under **Organization settings → Data and Privacy → Rate chats**.

### grok CLI — `~/.grok/config.toml`

```toml
[features]
telemetry = false
feedback = false
[diagnostics]
error_reporting = false
[telemetry]
trace_upload = false
mixpanel_enabled = false
```

The env forms the Grok section sets in Claude Code's `env` (`GROK_TELEMETRY_ENABLED`, `GROK_TELEMETRY_TRACE_UPLOAD`, `GROK_FEEDBACK_ENABLED`) reach grok when Claude Code launches it (a `grok` started from a shell sees only what that shell exports), and only `GROK_FEEDBACK_ENABLED` is documented with `0` as its off value; the other two map to the keys above, so the file is the documented form, and it also covers an interactive `grok`. Optional: `auto_update = false` under the existing `[cli]` table (update). What grok actually decided is in its log, not in the files: each start appends a `trace.upload.decision` line to `~/.grok/logs/unified.jsonl` (undocumented; grok 1.0.70) carrying `telemetry_mode`, `telemetry_source`, `trace_upload`, `uploads_enabled`, every input it weighed (`in_env_*`, `in_cfg_*`, `in_remote_*`) and the account state (`data_collection_disabled`, `upload_reason`); read the newest line after a grok run. `~/.grok/settings_cache.json` is the server's flag payload, re-fetched at every start, with `telemetry_enabled: true` as the product default — not a switch and nothing to flush; the decision line shows whether the local `false` won (observed: it did, `telemetry_source: env`, the remote `true` ignored).
You check: training is the account choice behind `/privacy` in grok's interactive TUI — "Coding data, retention, and training", Opt out; it does not touch `[features] telemetry`, and a team admin can opt the team out but not back in. The decision line's `data_collection_disabled` and `upload_reason` record that choice as grok read it (`zdr_team`: a Zero Data Retention team, where the choice cannot be changed). The SuperGrok account Zed uses takes a different path — the grok.com line below.
- Account side, the CLI: `/privacy` → **Coding data, retention, and training** → **Opt out**. A personal account can go both ways; a team admin signed in as the team opts the whole team out and cannot opt it back in; other team, organization or API-key logins see the row locked (`ZDR`, `· Admin Managed`, `· Personal Account Only`).
- The Grok dashboard, `grok.com/dashboard` → Settings → **Privacy**: **Privacy Mode (no training)** — "Your code data will not be trained on or used to improve the product. Code may be stored for Cloud Agent, Team Rules, and other features. This setting does not cover Grok API usage." — keep it Active (Edit changes it); and **Restricted and early-access models** — "These models require accepting the provider's data-retention policy before they can be used" — where **Claude Fable 5 / 5.1** is acknowledged or revoked ("One acknowledgement covers both models"). Ask, in the shape of the Cursor question below: "Keep the Claude Fable 5 / 5.1 data-policy acknowledgement on this Grok account?" — Yes: the models stay usable here under the provider's data-retention policy; No: **Revoke acknowledgement**, and they cannot be used until acknowledged again. The grok user guide does not mention this dashboard, so whether its Privacy Mode and the CLI's `/privacy` are one setting is not written down; the CLI's decision line is what shows the account state grok read.
- Zero Data Retention (team admin only): xAI Console → team picker → delete the team's Files and Collections → **Team Settings** → **Zero Data Retention (ZDR)** → **Enable** (accept the Enterprise Terms and Privacy Policy) → confirm; team-wide, every key. xAI does not recommend it for most customers (it disables Files, Collections and Batch). With ZDR on, coding-data sharing cannot be changed at all. No ZDR row: not an admin, self-serve not enabled, or an Enterprise Customer Agreement — sales@x.ai.
- SuperGrok / grok.com: Settings → **Data & Information → Data Controls** → **Improve the Model**: off — "By allowing your data to be used for training our models, you help enhance your own experience and improve the quality of the model for all users." (the grok.com settings screen; xAI's security FAQ names the same toggle, "from grok.com or mobile data controls settings", when describing Build-mode chats). Zed's SuperGrok provider carries the endpoints `auth.x.ai/zed-supergrok` and `api.x.ai/v1` in its binary — the xAI API, whose stated policy is "never trains on your API inputs or outputs without your explicit permission" with 30-day audit storage; none of the xAI pages read for this section (its security FAQ, Grok FAQ, privacy policy and docs index) says whether the grok.com toggle counts as that permission for API traffic — keep it off either way.
- X account (Grok on x.com, and the X data xAI trains on): X settings → **Privacy & Safety** → **Data sharing and personalization** → **Grok & Third-party Collaborators** → **Data Sharing**: de-select "Allow your public data as well as your interactions, inputs, and results with Grok and xAI to be used for training and fine-tuning." (X Help Center, "About Grok"). It covers Grok Bot in X Chat too (whose use "is governed by the Cursor Privacy Policy"); after a thumbs up/down on a conversation "X and xAI may use that conversation" for training, and "Protect your posts" (Privacy & Safety → Audience and tagging) keeps your posts out of training as well. The article says nothing about grok.com or the API.

### Cursor

No settings-file switch is documented. Privacy Mode is the control — Cursor Settings → General, or the team dashboard, where an admin can enforce it: "your code is never used for training by Cursor or other AI model providers". Usage, log and device data are still collected under the privacy policy, with no documented switch — VS Code's `telemetry.telemetryLevel` setting is absent from Cursor's bundles (0 occurrences in Cursor 3.27's `workbench.desktop.main.js` and `main.js`), so it is not a Cursor control.
You check: Privacy Mode on. With your own API keys Cursor's zero-data-retention does not apply — the provider's policy does. Content flagged for security review, and anything you submit as Feedback, may still be used for training.
- Account side: Cursor Settings (Ctrl+Shift+J; Cmd+Shift+J on macOS) → **General** → **Privacy Mode**: on. Team: `cursor.com/dashboard` → Settings → Privacy Mode: enable, and enforce so members cannot turn it off. Cursor says Privacy Mode is on by default for team members and for Enterprise teams — verify rather than assume.
- Models with provider-side retention (Claude Fable 5 / 5.1): requests to them fail until their retention policy is approved from the dashboard — Cursor requires that approval for Enterprise customers, for Teams with Privacy Mode and for individual customers with Privacy Mode alike, and an approval covers the whole team (Cursor prints the path for one model: `cursor.com/dashboard/restricted_models/claude-fable-5-1`). Anthropic stores their inputs and outputs for harm-prevention review, not training. Do not decide this for the user and do not wait for an admin: **ask** through the question tool, "Allow the retention-required models (Claude Fable 5 / 5.1) in Cursor?", two options with a pro and a con each, one line each, first the one that matches what the user already does (running one of these models as the orchestrator in Zed or Claude Code means the same retention already applies there):
  - Yes. Pro: those models work in Cursor, as the orchestrator too. Con: Anthropic keeps their inputs and outputs for review; a team's approval covers every member.
  - No. Pro: no Anthropic review-retention of your Cursor requests. Con: those models fail in Cursor, including as the orchestrator — the delegates (row 1) do not need them.
  Yes: show the dashboard path (a team member without dashboard rights hands it to their admin); the Finish row reads "Cursor retention models: approved by you". No: "left blocked". Cursor's settings also offer **Privacy Mode (Legacy)** — "No training and no storage. Background Agent and other features that require code storage will be disabled." — the stricter variant (`PRIVACY_MODE_NO_STORAGE` in Cursor 3.27; the help page names only Privacy Mode), and Cursor warns "You won't be able to switch back to Privacy Mode (Legacy)."

### Codex — `~/.codex/config.toml`

```toml
[analytics]
enabled = false
[feedback]
enabled = false
```

`analytics.enabled = false` disables the built-in Statsig metrics exporter; unset means the client default, which the reference does not state — missing is not off. `feedback.enabled = false` stops `/feedback` submissions (default true). The `[otel]` exporters (`exporter`, `metrics_exporter`, `trace_exporter`) go to your own collector, not to OpenAI: set each to `"none"` or leave it unset — except `metrics_exporter`, whose default `statsig` follows `analytics.enabled`; `log_user_prompt` stays unset or `false`; a managed `otel` table can force the exporters. Optional: `check_for_update_on_startup = false` (update; the reference says only when updates are centrally managed). Project-local config cannot set telemetry routing; only the user file counts.
You check: data sent to the API is not used for training unless the account opts in; abuse-monitoring logs are kept up to 30 days unless the organisation is approved for Zero Data Retention or Modified Abuse Monitoring (Settings → Organization → Data controls). Neither is a config key. With a ChatGPT sign-in instead of an API key, that ChatGPT account's data controls apply — the bullets below.
- Account side (API organizations): no training on API data unless you explicitly opt in — the page names no toggle, so if your organization's settings show one, it stays off. Zero Data Retention or Modified Abuse Monitoring: after sales approval, in the API organization's **Settings → Organization → Data controls → Data Retention** — ZDR or Modified Abuse Monitoring for the organization; `default`, either control, or **None** per project.
- A Codex signed in with a ChatGPT account, personal (Free, Plus, Pro): "data sharing is enabled by default" — account menu → **Settings** → **Data controls** (`chatgpt.com/settings/data-controls`) → **Improve the model for everyone** ("Control whether your chats are used for model training"): off, Done (applies to the account across web and mobile; it is the only training control on that page — the rest are location, Work network access, sharing, archive, delete, export and cookies). Codex has its own switch on top: **Include environments** in Codex settings, which "controls whether additional context from your Codex environments can be used to train OpenAI models" — "Changing your ChatGPT setting or opting out through the Privacy Portal does not change that setting", so turn it off separately. A thumbs up/down on a response still lets the whole conversation be used for training, and during a Trusted Access session (Daybreak Blue) OpenAI "may use content from your interactions" even with Improve the model for everyone off. Managed workspaces (Business, Enterprise, Edu, Healthcare): "OpenAI does not use content … to train its models" by default; "Parent or guardian settings and workspace controls may limit whether you can change it." Source: help.openai.com article 7730893, "Data controls in ChatGPT" — it refuses automated reading.

### Zed — `~/.config/zed/settings.json`

```json
"telemetry": { "diagnostics": false, "metrics": false },
"edit_predictions": { "allow_data_collection": "no" },
"agent": { "enable_feedback": false }
```

`diagnostics` are the crash reports, `metrics` the usage data; `allow_data_collection: "no"` pins edit-prediction training-data collection off whatever the status-bar toggle says (collection is opt-in, and only for files in open-source projects outside `disabled_globs`); `enable_feedback: false` hides the thumbs that share an agent thread with Zed. `telemetry.anthropic_retention` stays `false`, its default: it is a gate for Anthropic models without zero data retention, not telemetry. Optional: `"auto_update": false` (update). Edit Prediction itself sends editing context per keystroke — that is the feature; leave it on if you use it.
You check: the Training Data Collection toggle under Privacy in the Edit Prediction status bar menu is off (the setting above pins it anyway). Known on the provider side: Anthropic keeps Claude Fable prompts and outputs for at least 30 days for safety review, not training, own API key included, and Zed cannot opt out of it.
- Account side: the Zed pages read for this section (privacy-and-security, ai-improvement, zed-hosted-models, business admin-controls) name no personal account setting for any of this; the opt-in lives in the editor: Edit Prediction status bar menu → **Privacy** → **Training Data Collection** (leave it off); a thumbs rating on an agent thread is itself the share, so do not rate. Zed Business: data sharing off by default, and owners and admins set the feedback toggles at `dashboard.zed.dev` → your organization → **Data & Privacy** (Agent Thread Feedback, Edit Prediction Feedback).

## Finish

Report one short table — item, and ✓ / ✗ / "you check" — then what the user still has to do. The telemetry section adds one row per switch: ✓ set, missing (the line shown), or you check (account-level — print the steps listed under that tool); a question the section asks gets its own row with the answer. In Claude Code, the Grok step adds "Grok: not installed — skipped", or "Grok: declined — delegates stay on Sonnet", or after a yes one row each for the script (✓ when `command -v grok-delegate` finds it), G1–G6 (✓ / ✗, G4 naming the profile) and the settings lines (`DELEGATE_TO=grok` last). Last step for every tool: in a new session ask "what always-applied rules or global instructions do you see?" — it must quote the delegation rule back (Claude Code: `/context` lists `delegation.md`). Then run the probes.
