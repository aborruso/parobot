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
mlr --n2c put -S '$CF=regextract(FILENAME,"[0-9]{6,}")' then label code then unsparsify "$folder"/comuni/*_code >"$folder"/comuni/robotsComuniRisposte.csv

# produzione file di report
mlr --tsv --implicit-csv-header then label url,cf "$folder"/source.tsv >"$folder"/tmp_source.tsv
mlr --t2c join --ul -j cf -l cf -r Cf -f "$folder"/tmp_source.tsv then unsparsify "$folder"/amministrazioni.tsv >"$folder"/tmp_report.csv
mlr --csv join --ul -j cf -l cf -r CF -f "$folder"/tmp_report.csv then unsparsify then rename code,HTTPreply "$folder"/comuni/robotsComuniRisposte.csv >"$folder"/tmp_report01.csv

ls -1a "$folder"/comuni/*txt | mlr --csv --implicit-csv-header then put '$1=regextract($1,"[0-9]{6,}")' then label cf then put '$robots="x"' >"$folder"/tmp_robots.csv

mlr --csv join --ul -j cf -f "$folder"/tmp_report01.csv \
  then unsparsify \
  then sort -f cf \
  then put -S 'if( $robots == "x") {$URLrobots=("https://raw.githubusercontent.com/aborruso/parobot/master/comuni/".$cf.".txt")} else {$URLrobots=""}' \
  then reorder -f cf,Regione,Provincia,des_amm,URLrobots then cut -x -f url "$folder"/tmp_robots.csv >"$folder"/report.csv

rm "$folder"/tmp*

# genera alert
grep -o -E 'Disallow:.+(amministraz|trasparen|contratt|selezion|avvis).*' "$folder"/comuni/*.txt |
  sed 's/Disallow://g' |
  mlr --csv --implicit-csv-header --ifs "txt" put 'if ($2=~"amministraz"){$amministraz="x"} elif ($2=~"trasparen") {$trasparen="x"} elif ($2=~"contratt") {$contratt="x"} elif ($2=~"avvis") {$avvis="x"} elif ($2=~"selezion") {$selezion="x"}' \
    then put '$1=regextract($1,"[0-9]{6,}");$2=gsub($2," ?: ","")' \
    then unsparsify then label cf,stringa >"$folder"/comuni/alert.csv

mlr --csv cut -x -f stringa \
  then uniq -a \
  then reshape -r "[^(cf)]" -o item,value \
  then filter -x '$value==""' \
  then reshape -s item,value \
  then unsparsify "$folder"/comuni/alert.csv >"$folder"/comuni/alertReport.csv
