#!/bin/bash

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -x

mkdir -p "$folder"/comuni

# scarica eventuali file robots.txt
parallel --colsep "\t" 'curl --max-time 60 -k -sL {1}/robots.txt >./comuni/{2}.txt -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36" -H "Sec-Fetch-User: ?1" --compressed' :::: source.tsv
