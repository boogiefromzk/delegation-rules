#!/usr/bin/env bash
# grok-delegate <explore|worker|review> <message file> [<session UUID>]
# Runs grok on a brief (new session) or on a follow-up message (resume). Constants live in the env (GROK_SANDBOX, ...).
# Exit: 2 usage error, 3 brief rejected by the gate, 4 grok stopped for a permission, else grok's own exit code.
# Output: GROK OK | GROK FAILED (exit N) | GROK STOPPED (permission required), then "session <UUID>", then grok's output.
set -u
die() { echo "grok-delegate: $1" >&2; exit 2; }
reject() { echo "BRIEF REJECTED — standing rules missing"; exit 3; }
[ "$#" -eq 2 ] || [ "$#" -eq 3 ] || die "usage: grok-delegate <explore|worker|review> <message file> [<session UUID>]"
role=$1 file=$2
case "$role" in explore|worker|review) ;; *) die "role must be explore, worker or review, not $role" ;; esac
[ -f "$file" ] && [ -r "$file" ] || die "cannot read $file"
case "$file" in /*) ;; *) file=$PWD/$file ;; esac  # grok runs with another --cwd
out=$(mktemp "${TMPDIR:-/tmp}/grok-delegate.XXXXXX") || die "cannot create a temp file"
trap 'rm -f "$out"' EXIT
if [ "$#" -eq 3 ]; then  # resume: a follow-up message, no gate check
  uuid=$3
  case "$uuid" in ""|*[!0-9a-f-]*) die "unknown session $uuid" ;; esac
  sess=(-r "$uuid")
else  # new session: the gate matches whole lines, with U+2014 em dashes
  case "$(head -n 1 "$file")" in "# Brief — $role:"*) ;; *) reject ;; esac
  grep -Fxq "## Standing rules — $role" "$file" || reject
  grep -Fxq "(end of standing rules — $role)" "$file" || reject
  if [ -r /proc/sys/kernel/random/uuid ]; then uuid=$(cat /proc/sys/kernel/random/uuid); else uuid=$(uuidgen); fi
  uuid=$(printf %s "$uuid" | tr '[:upper:]' '[:lower:]')
  [ -n "$uuid" ] || die "cannot make a session UUID"
  sess=(-s "$uuid")
fi
cwd=$(grep -m 1 -E '^Working directory: /' "$file")
cwd=${cwd#Working directory: }
[ -d "${cwd:=$PWD}" ] || die "working directory $cwd is not a directory"  # else the current directory
if [ "$role" = worker ]; then
  flags=(--yolo --disallowed-tools "web_search,web_fetch,task,search_tool,use_tool" --deny 'MCPTool(*)' --deny 'Bash(git *)')
else
  flags=(--yolo --tools "read_file,grep,list_dir,write,run_terminal_cmd" --disallowed-tools "search_replace,web_search,web_fetch,task,search_tool,use_tool" --deny 'MCPTool(*)' --deny 'Bash(git *)' --deny 'Bash(rm *)' --deny 'Bash(mv *)')
fi
cmd=(grok --prompt-file "$file" --model grok-4.7 --effort xhigh --max-turns 100
  --cwd "$cwd" "${sess[@]}" "${flags[@]}")
"${cmd[@]}" > "$out" 2>&1 < /dev/null
code=$?
last=$(grep -v '^[[:space:]]*$' "$out" | tail -n 1)  # a refusal ends grok's run, so it is the last line
stopped=
case "$last" in *"was not run, as a headless run cannot ask for approval"*) stopped=1 ;; esac
if [ "$code" -eq 0 ] && [ -n "$stopped" ]; then
  code=4; echo "GROK STOPPED (permission required)"
elif [ "$code" -eq 0 ]; then echo "GROK OK"
else echo "GROK FAILED (exit $code)"; fi
echo "session $uuid"
cat "$out"
exit "$code"
