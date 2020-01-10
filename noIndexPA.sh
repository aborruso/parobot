#!/bin/bash

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -x

mkdir -p "$folder"/bussolaPA

URL="http://bussola.magellanopa.it/open-data.html?type=1025&tx_bussola_showcrawler%5Baction%5D=downloadFileElencoAmm&tx_bussola_showcrawler%5Bcontroller%5D=Crawler&IdIndicatore=200&nomeIndicatore=Amministrazione%20Trasparente"

# scarica dati da bussola
#curl -sL "$URL">"$folder"/amministrazionTrasparente.csv

# estrai elenco URL
mlr --n2t --ifs ";" cut -f 7 then filter -x '$7=="" || $7!=~"^htt" || $7=="Link"' \
  then uniq -a then cat -n \
  then rename 7,URL "$folder"/amministrazionTrasparente.csv | tail -n +2 >"$folder"/bussolaPA/amministrazionTrasparenteURL.tsv

# scarica pagina
parallel --colsep "\t" 'curl --max-time 60 -k -sL {2} -o '"$folder"'/bussolaPA/{1}.txt  -D '"$folder"'/bussolaPA/{1}_code -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36" -H "Sec-Fetch-User: ?1" --compressed' :::: "$folder"/bussolaPA/amministrazionTrasparenteURL.tsv
