#!/bin/sh

zobraz_nove() {
    CAS_TERAZ=$(date +%s%3N)                                            # + je zaciatok, %s je pocet sekund od 1.1.1970 a %3N su nanosekundy cutnute na 3 desatinne miesta, cize mikro
    CAS_PRED_H=$(( CAS_TERAZ - $1*60*1000 ))                            # odratame potrebny pocet mikrosekund, pricom $1 predstavuje minuty (5 alebo 60)
    N_RIADKOV=0
    NOVE_RIADKY=""
    while read -r line                                                      #citame subor po riadku a kazdy riadok dame do $line
    do
        MS_RIADOK=$(echo "$line" | tr -s " " | cut -d " " -f 1,2 | date -f - +%s%3N)    #prepinac -f - znamena, ze date dostane string zo suboru, pricom - znamena stdin, teda z pajpy
        if [ "$MS_RIADOK" -ge "$CAS_PRED_H" ]                               #ak ms zo spracovaneho riadku >= cas pred 5min, resp 1hod
        then
            NOVE_RIADKY="${NOVE_RIADKY}${line}\n"                       #appendujeme riadok do premennej aj s newline
        fi
        N_RIADKOV=$(( N_RIADKOV + 1 ))
    done < /tmp/templog.txt                                                  #nacitame zvysne riadky z docasneho suboru
    echo "$NOVE_RIADKY" > /tmp/templog.txt                                   #ulozime do docasneho suboru vsetky riadky z premennej
    truncate -s -1 /tmp/templog.txt                                          #pretoze POSIX nepodporuje -n prepinac pri echo, musime este odstranit nadbytocny novy riadok zo suboru
}

zobraz_user() {
    NOVE_RIADKY=""
    while read -r line
    do
        MS_RIADOK=$(echo "$line" | tr -s " " | cut -d " " -f 8 | cut -d ":" -f 1)     #vystrihneme 8. stlpec (kde sa nachadza meno) a este to pajpneme do dalsieho cutu aby sme sa zbavili : na konci
        if [ "$MS_RIADOK" = "$1" ]
        then
            NOVE_RIADKY="${NOVE_RIADKY}${line}\n"
        fi
        N_RIADKOV=$(( N_RIADKOV + 1 ))
    done < /tmp/templog.txt
    echo "$NOVE_RIADKY" > /tmp/templog.txt
    truncate -s -1 /tmp/templog.txt
}

zobraz_hlasku() {
    NOVE_RIADKY=""
    while read -r line
    do
        MS_RIADOK=$(echo "$line" | tr -s " " | cut -d " " -f 9- | grep "$1")        #vyberieme vsetko od 9 stlpca az po koniec, potom to grepneme s hladanym retazcom
        if [ -n "$MS_RIADOK" ]                                    #ak vysledok vyhladavania nie je prazdny
        then
            NOVE_RIADKY="${NOVE_RIADKY}${line}\n"
        fi
        N_RIADKOV=$(( N_RIADKOV + 1 ))
    done < /tmp/templog.txt
    echo "$NOVE_RIADKY" > /tmp/templog.txt
    truncate -s -1 /tmp/templog.txt
}

zobraz_triedu() {
    NOVE_RIADKY=""
    while read -r line
    do
        MS_RIADOK=$(echo "$line" | tr -s " " | cut -d " " -f 6)
        if [ "$MS_RIADOK" = "$1" ]                                 #ak sa class v riadku presne rovna s class v argumente
        then
            NOVE_RIADKY="${NOVE_RIADKY}${line}\n"
        fi
        N_RIADKOV=$(( N_RIADKOV + 1 ))
    done < /tmp/templog.txt
    echo "$NOVE_RIADKY" > /tmp/templog.txt
    truncate -s -1 /tmp/templog.txt                              
}

zobraz_level() {
    ARG=""
    case $1 in
        DEBUG) ARG="DEBUG INFO WARN ERROR";;
        INFO) ARG="INFO WARN ERROR";;
        WARN) ARG="WARN ERROR";;
        ERROR) ARG="ERROR";;
        *) pomoc;;
    esac
    najdi_level "${ARG}"
}

najdi_level() {
    NOVE_RIADKY=""
    while read -r line
    do
        for x in $1
        do
            MS_RIADOK=$(echo "$line" | tr -s " " | cut -d " " -f 3)
            if [ "$MS_RIADOK" = "$x" ]                                 #ak sa class v riadku presne rovna s class v argumente
            then
                NOVE_RIADKY="${NOVE_RIADKY}${line}\n"
            fi
            N_RIADKOV=$(( N_RIADKOV + 1 ))
        done
    done < /tmp/templog.txt
    echo "$NOVE_RIADKY" > /tmp/templog.txt
    truncate -s -1 /tmp/templog.txt
}

pomoc() {
    echo "Pouzitie: $0 [-m|H|u|g|j|l|h]"
    echo ""
    echo "-m                            Vypise zaznamy nie starsie 5 minut"
    echo "-H                            Vypise zaznamy nie starsie ako jednu hodinu"
    echo "-u <user>                     Vypise zaznamy s danym userom"
    echo "-g <string>                   Vypise zaznamy s hlaskou obsahujucou dany string"
    echo "-j <trieda>                   Vypise zaznamy s presne zadanou Java triedou"
    echo "-l <DEBUG|INFO|WARN|ERROR>    Vypise zaznamy s urovnou vacsou alebo rovnou urovnou"
    echo "-h                            Vypise tuto tabulku"
    echo ""
    echo "Prepinace sa daju aj kombinovat. V tomto pripade budu vypisane tie zaznamy, ktore splnaju VSETKY zadane podmienky."
    echo "Vsetky prepinace su dobrovolne. V pripade ziadnych prepinacov sa vypise komplet cely log subor."
    echo "$NOVE_RIADKY" > /tmp/templog.txt
    truncate -s -1 /tmp/templog.txt
}

cat /var/log/filterlog.log 2> /dev/null 1> /tmp/templog.txt || echo "Zadany subor neexistuje"             #skopirujeme cely log do docasneho suboru

while getopts mHu:g:j:l:h vlajka           #ak za pismenom ide dvojbodka, prepinac ocakava argument, pricom sa prepinac ulozi do $vlajka
do
    case "${vlajka}" in
        H) zobraz_nove 60;;
        m) zobraz_nove 5;;
        u) zobraz_user "${OPTARG}";;       # $optarg znamena argument, ktory sa ocakava na vstupe pri prepinaci
        g) zobraz_hlasku "${OPTARG}";;
        j) zobraz_triedu "${OPTARG}";;
        l) zobraz_level "${OPTARG}";;
        h) pomoc;;
        *) pomoc;;
    esac
done

cat /tmp/templog.txt                         #vypiseme vysledok
rm /tmp/templog.txt                          #potom, co bol subor vypisany, nam ho uz netreba