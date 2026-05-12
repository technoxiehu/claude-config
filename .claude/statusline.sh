#!/bin/bash
# Claude Code status line: user@host:/path [model] XX%
# Derived from PS1: \u@\h:\w\$  styled as green user@host + blue path

input=$(cat)

# 1. user@host:/current/dir (green/blue, same as PS1 from .bashrc)
user=$(whoami)
host=$(hostname -s)
dir=$(echo "$input" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('workspace',{}).get('current_dir','') or '')" 2>/dev/null)
dir=${dir:-$(pwd)}

# 2. Model name
model=$(echo "$input" | python3 -c "
import json,sys
d=json.load(sys.stdin)
m=d.get('model',{})
if isinstance(m, dict):
    print(m.get('display_name','') or m.get('id','') or '')
else:
    print(m or '')
" 2>/dev/null)

# 3. Context remaining percentage
remaining=$(echo "$input" | python3 -c "
import json,sys
d=json.load(sys.stdin)
cw=d.get('context_window',{})
if isinstance(cw, dict):
    print(cw.get('remaining_percentage','') or '')
else:
    print('')
" 2>/dev/null)

# Build output: user@host:/path in green:blue (like PS1)
printf '\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m' "$user" "$host" "$dir"

# Append [model] in yellow if available
if [ -n "$model" ]; then
    printf ' \033[01;33m[%s]\033[00m' "$model"
fi

# Append percentage with color coding
if [ -n "$remaining" ]; then
    pct=$(printf '%.0f' "$remaining" 2>/dev/null || echo "0")
    if [ "$pct" -ge 50 ]; then
        color='01;32'   # green
    elif [ "$pct" -ge 25 ]; then
        color='01;33'   # yellow
    else
        color='01;31'   # red
    fi
    printf ' \033[%sm%s%%\033[00m' "$color" "$pct"
fi
