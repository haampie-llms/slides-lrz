# Helpers for scripted, real terminal recordings (sourced by each demo script).
# The commands are executed for real; only the typing is simulated.
. "$HOME/lrz-demo/env.sh" >/dev/null 2>&1
export TERM=xterm-256color
PROMPT_DIR="${PROMPT_DIR:-}"

_prompt() { printf '\033[1;32m%s\033[0m\033[1;34m%s\033[0m $ ' "${PROMPT_HOST:-laptop}" "${PROMPT_DIR:+:$PROMPT_DIR}"; }

# type a string with a human-ish rhythm
_type() {
  local s="$1" i
  for ((i = 0; i < ${#s}; i++)); do
    printf '%s' "${s:i:1}"
    sleep 0.025
  done
}

# show a comment line (does not execute)
say() { _prompt; printf '\033[2m'; _type "# $*"; printf '\033[0m\n'; sleep 0.6; }

# type and run a command
run() {
  _prompt; _type "$*"; sleep 0.4; printf '\n'
  eval "$@"
  sleep 1.2
}

# final empty prompt
end() { _prompt; sleep 1.5; printf '\n'; }
