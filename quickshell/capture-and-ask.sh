#!/usr/bin/env sh
set -eu

fail() {
    printf '%s\n' "$1"
    exit 0
}

command -v grim >/dev/null 2>&1 || fail "grim is required"
command -v codex >/dev/null 2>&1 || fail "Codex CLI is required"

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/moodcq.XXXXXX") || fail "Could not create temporary files"
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

image="$tmp_dir/screen.png"
answer="$tmp_dir/answer.txt"
codex_stderr="$tmp_dir/codex.stderr"
diagnostic_dir="${XDG_CACHE_HOME:-$HOME/.cache}/moodcq"

grim "$image" || fail "Screenshot failed"
printf '%s\n' '__MOODCQ_CAPTURED__'

codex exec --ephemeral --skip-git-repo-check --color never \
    -c 'model_reasoning_effort="low"' --image "$image" \
    --output-last-message "$answer" \
    'Read the visible multiple-choice question in this screenshot. Reply with only the correct answer choices. If choices have letters, return their letters (for example: A, C). Otherwise return the 1-based positions of the correct choices (for example: 1, 3). If you cannot confidently read a multiple-choice question, reply exactly UNCLEAR. If there is no multiple-choice question, reply exactly NO MCQ. Do not explain.' \
    >/dev/null 2>"$codex_stderr" &
codex_pid=$!
elapsed=0
codex_status=0

while [ "$elapsed" -lt 180 ]; do
    if [ -s "$answer" ]; then
        sleep 0.25
        if [ -s "$answer" ]; then
            if kill -0 "$codex_pid" 2>/dev/null; then
                kill -TERM "$codex_pid" 2>/dev/null || true
            fi
            wait "$codex_pid" 2>/dev/null || true
            break
        fi
    fi

    if ! kill -0 "$codex_pid" 2>/dev/null; then
        if wait "$codex_pid"; then
            codex_status=0
        else
            codex_status=$?
        fi
        break
    fi

    sleep 1
    elapsed=$((elapsed + 1))
done

if [ -s "$answer" ]; then
    tr '\n' ' ' < "$answer" | sed 's/[[:space:]]*$//'
    printf '\n'
    exit 0
fi

if kill -0 "$codex_pid" 2>/dev/null; then
    kill -TERM "$codex_pid" 2>/dev/null || true
    wait "$codex_pid" 2>/dev/null || true
fi

mkdir -p "$diagnostic_dir"
{
    printf 'Codex exit status: %s\n' "$codex_status"
    rg -v '^hook:' "$codex_stderr" 2>/dev/null | tail -n 12 | sed -E 's/(sk-[A-Za-z0-9_-]{12,})/<REDACTED>/g; s/(Bearer )[A-Za-z0-9._-]+/\1<REDACTED>/g'
} > "$diagnostic_dir/last-error.log"
chmod 600 "$diagnostic_dir/last-error.log"

if [ "$elapsed" -ge 180 ]; then
    fail "Codex request timed out"
fi
if [ "$codex_status" -ne 0 ]; then
    fail "Codex could not read the screenshot"
fi
fail "No answer returned"
