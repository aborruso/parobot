#!/bin/bash

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#set -x

mkdir -p "$folder"/comuni

rm "$folder"/comuni/*

# scarica eventuali file robots.txt e la risosta del server
parallel --colsep "\t" 'curl --max-time 60 -k -sL {1}/robots.txt -o ./comuni/{2}.txt -w "%{http_code}" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36" -H "Sec-Fetch-User: ?1" --compressed >./comuni/{2}_code' :::: source.tsv

# imposta il fine linea come line feed
dos2unix "$folder"/comuni/*.txt

# rimuovi spazi bianchi inziali e finali e doppi spazi
sed -i -r 's/ +$//g;s/^ +//g;s/ +/ /g' "$folder"/comuni/*.txt

# cancella tutti i file che non sono robots
cd "$folder"/comuni/
rm -r $(grep -riL 'User-Agent:' ./*txt)

# risposta server
mlr --n2c put -S '$CF=gsub(FILENAME,"_code","")' then label code then unsparsify "$folder"/comuni/*_code >"$folder"/comuni/robotsComuniRisposte.csv
