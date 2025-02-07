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

if uname | grep -q Darwin; then
    awk(){
        command gawk "$@"
    }
fi

die(){
    echo "ERROR: $*"
    exit 1
}

echo "Getting Name -> Stars" >&2
repo_stars="$(
    gh repo list HariSekhon \
        --limit 1000 \
        --source \
        --json name,stargazerCount \
        --jq '
            .[] |
            "\(.name) \(.stargazerCount)"
        '
)"

repo_dirs="$(
    if [ -f "$local_config" ]; then
        echo "Reading $local_config" >&2
        cat "$local_config"
    else
        echo "Fetching repo list from DevOps-Bash-tools setup/repos.txt" >&2
        curl -sSf https://raw.githubusercontent.com/HariSekhon/DevOps-Bash-tools/refs/heads/master/setup/repos.txt
    fi |
    sed '
      s/#.*//;
      s/:/ /;
      s/^[[:space:]]*//;
      s/[[:space:]]*$//;
      /^[[:space:]]*$/d;
    ' |
    grep -v \
         -e 'harisekhon$' \
         -e 'lib-java' |

    while read -r repo dir; do
        if [ -z "$dir" ]; then
            dir="$repo"
        fi
        echo "$repo $dir"
    done
)"

tmp="/tmp/github_clean_checkouts"

mkdir -p -v "$tmp"

pushd "$tmp"

echo "Checking out repos" >&2
while read -r repo dir; do
    echo "Repo: $repo" >&2
    if [ -d "$dir" ]; then
        echo "Pulling Repo: $repo" >&2
        pushd "$dir"
        git pull
        popd
    else
        echo "Cloning Repo: $repo" >&2
        git clone "https://github.com/HariSekhon/$repo" "$dir"
    fi
done <<< "$repo_dirs"

echo "Running scc on clean repo checkouts" >&2
echo >&2
# --json doesn't output totals
#scc="$(scc . --format json | jq -M | tee /dev/stderr)"
scc="$(scc . | tee /dev/stderr)"
echo >&2

echo "Parsing and Calculating SCC stats" >&2
total_cost="$(awk '/^Estimated Cost to Develop/{print $NF}' <<< "$scc")"
echo "Total Cost: $total_cost"
total_months="$(
    awk '/^Estimated Schedule Effort/ {print $0}' <<< "$scc" |
    grep -Eo '[[:digit:].]+ months' |
    sed 's/ months//; s/[[:space:]]*//' ||
    die "FAILED to parse man months from SCC output"
)"
echo "Total Months: $total_months"
total_people="$(awk '/^Estimated People Required/ {print $NF}' <<< "$scc")"
echo "Total People Required: $total_people"
total_man_months="$(bc -l <<< "$total_people * $total_months" | sed 's/\..*$//')" # discard partial month for simplicity
echo "Total Man Months: $total_man_months"
total_man_years_months="$((total_man_months / 12)) years $((total_man_months % 12)) months"
echo "Total Man Years and Months: $total_man_years_months"
if ! awk '{print $3}' <<< "$scc" | head -n2 | grep -qi Lines; then
    die "Lines no longer column 3 in scc output"
fi
total_lines="$(awk '/^Total /{print $3}' <<< "$scc")"
echo "Total Lines: $total_lines"
echo >&2
popd
echo >&2

{
echo "<table>"
while read -r repo dir; do
    #echo "Parsing Stars for repo: $repo" >&2
    stars="$(awk "BEGIN { IGNORECASE = 1 } /^$repo / {print \$2; exit}" <<< "$repo_stars")"
    if [ -z "$stars" ]; then
        echo "WARNING: no stars parsed for repo: $repo" >&2
    fi
    echo "${stars:-0} $repo $dir"
done <<< "$repo_dirs" |
sort -nr |
while read -r stars repo dir; do
    #echo "Generating repo: $repo" >&2
    cat <<EOF
    <tr>
        <td>
            <a href="https://github.com/HariSekhon/$repo#readme">
                <img src="https://img.shields.io/badge/HariSekhon-${repo//-/--}-blue?logo=github" />
            </a>
        </td>
        <td>
            <a href="https://github.com/HariSekhon/$repo/stargazers">
                <img src="https://img.shields.io/github/stars/HariSekhon/$repo?logo=github" />
            </a>
        </td>
        <td>
            <a href="https://github.com/HariSekhon/$repo/network">
                <img src="https://img.shields.io/github/forks/harisekhon/$repo?logo=github" />
            </a>
        </td>
        <td>
            <a href="https://github.com/HariSekhon/$repo">
                <img src="https://sloc.xyz/github/HariSekhon/$repo/?badge-bg-color=2081C2" />
            </a>
        </td>
        <td>
            <a href="https://github.com/HariSekhon/$repo">
                <img src="https://sloc.xyz/github/HariSekhon/$repo/?badge-bg-color=2081C2&category=cocomo" />
            </a>
        </td>
    </tr>
EOF
done
cat <<EOF

![Total Lines](https://img.shields.io/badge/Total%20Lines-$total_lines-blue)
![Total Man Years](https://img.shields.io/badge/Total%20Man%20Years-${total_man_years_months// /%20}-blue)
![Total COCOMO Cost Estimate](https://img.shields.io/badge/Total%20COCOMO%20Cost%20Estimate-$total_cost-blue)

EOF
} |
tee /dev/stderr |
copy_to_clipboard.sh  # from DevOps-Bash-tools which should be in the $PATH
