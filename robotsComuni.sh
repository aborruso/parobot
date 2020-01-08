#!/bin/bash

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -x

mkdir -p "$folder"/comuni

# scarica eventuali file robots.txt
parallel --colsep "\t" 'curl --max-time 60 -k -sL https://{1}/robots.txt >./comuni/{2}.txt' :::: source.tsv
