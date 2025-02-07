#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-07 11:34:50 +0700 (Fri, 07 Feb 2025)
#
#  https///github.com/HariSekhon/HariSekhon
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$srcdir"

local_config="../../bash-tools/setup/repos.txt"

if [ -f "$local_config" ]; then
    cat "$local_config"
else
    curl -sSf https://raw.githubusercontent.com/HariSekhon/DevOps-Bash-tools/refs/heads/master/setup/repos.txt
fi |
sed '
  s/#.*//;
  s/:/ /;
  s/^[[:space:]]*//;
  s/[[:space:]]*$//;
  /^[[:space:]]*$/d
' |
grep -v harisekhon$ |
tail -r |
while read -r repo dir; do
    if [ -z "$dir" ]; then
        dir="$repo"
    fi
    cat <<EOF
<tr>
<td> <img src="https://img.shields.io/badge/HariSekhon-${repo//-/--}-blue?logo=github&link=https%3A%2F%2Fgithub.com%2FHariSekhon%2F$repo#readme" /> </td>
<td> <img src="https://img.shields.io/github/stars/HariSekhon/$repo?logo=github&link=https://github.com/HariSekhon/DevOps-Bash-tools/stargazers" /> </td>
<td> <img src="https://img.shields.io/github/forks/harisekhon/$repo?logo=github&link=https://github.com/HariSekhon/DevOps-Bash-tools/network" /> </td>
<td> <a href="https://github.com/HariSekhon/$repo"> <img src="https://sloc.xyz/github/HariSekhon/$repo/?badge-bg-color=2081C2" /> </a> </td>
<td> <a href="https://github.com/HariSekhon/$repo"> <img src="https://sloc.xyz/github/HariSekhon/$repo/?badge-bg-color=2081C2&category=cocomo" /> </a> </td>
</tr>
EOF
done |
tee /dev/stderr |
copy_to_clipboard.sh  # from DevOps-Bash-tools which should be in the $PATH
