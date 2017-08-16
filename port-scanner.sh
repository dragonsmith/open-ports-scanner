#!/bin/bash

set -e

_nodes=''

if [ -f ./projects ]; then
  while read _row; do
    if [ ! -d $_row -o ! -f $_row/.chef/knife.rb ]; then
      echo 'ERROR: you have an error:'
      echo "       \`$_row\` is not a valid chef dir"
      exit 2
    fi

    # Checking if we have a chef account
    if bash -c "(cd $_row && knife status > /dev/null 2> /dev/null)"; then
      _nodes="$_nodes $(bash -c "(cd $_row && knife node list)")"
    fi

    if [ -d $_row/nodes ]; then
      _nodes="$_nodes $(ls -1 $_row/nodes | sed -E 's/^(.*)\.json$/\1/g')"
    fi
  done < <(grep -vE '^[ \t]*(#.*){0,1}$' ./projects)
else
  echo 'INFO: No "./projects" file found. Skipping.'
fi

if [ -f ./nodes ]; then
  echo 'INFO: Found separate list for nodes to scan.'
  _nodes="$_nodes $(grep -vE '^[ \t]*(#.*){0,1}$' ./nodes)"
fi

echo 'Nodes to scan'
echo $_nodes

nmap -n \
     -sT \
     --open \
     --unprivileged \
     --defeat-rst-ratelimit \
     -p- \
     -oN new-results.txt \
     $_nodes | \
       grep -vE '(Starting Nmap|Nmap done|Host is up|Not shown|Some closed ports may)'

# if [ -f new-results.txt ]; then
#   mv new-results.txt results.txt
#   git add results.txt
#   git commit -m "Hosts scan $(date +%F)"
#   git --no-pager -c color.diff=always diff HEAD~1
# fi