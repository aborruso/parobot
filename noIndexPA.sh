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

# scarica body e header delle pagine
parallel --colsep "\t" 'curl --max-time 60 -k -sL {2} -o '"$folder"'/bussolaPA/{1}.txt  -D '"$folder"'/bussolaPA/{1}_code -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36" -H "Sec-Fetch-User: ?1" --compressed' :::: "$folder"/bussolaPA/amministrazionTrasparenteURL.tsv

# check noindex
grep -l -E 'meta.+noindex' "$folder"/bussolaPA/*.txt | grep -oE '[0-9]+' >"$folder"/bussolaPA/alertnoindex.tsv
mlr -I --tsv --implicit-csv-header label n bussolaPA/alertnoindex.tsv

# crea report Amministrazion Trasparente Bussola
mlr -I --icsvlite --ocsv --ifs ";" uniq -a  then clean-whitespace "$folder"/amministrazionTrasparente.csv
mlr --tsv --implicit-csv-header then label n,URL "$folder"/bussolaPA/amministrazionTrasparenteURL.tsv >"$folder"/bussolaPA/tmp_source.tsv
mlr --t2c join --ul -j n -f "$folder"/bussolaPA/alertnoindex.tsv then unsparsify "$folder"/bussolaPA/tmp_source.tsv >"$folder"/bussolaPA/alertnoindexURL.csv
mlr --csv join --ul -j Link -l Link -r URL -f "$folder"/amministrazionTrasparente.csv \
then unsparsify \
then rename n,noindex \
then put -S 'if ($noindex=="") {$noindex=""} else {$noindex="x"}' \
then reorder -e -f Link \
then sort -f Regione,Provincia,Comune,Denominazione "$folder"/bussolaPA/alertnoindexURL.csv >"$folder"/reportAmministrazionTrasparenteBussola.csv

