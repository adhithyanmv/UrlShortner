#!/bin/bash
URL=$1
content=$(curl https://api.shrtco.de/v2/shorten?url=$1)
stringed="'$content'"
IFS=','
read -ra arr<<<"$stringed"
declare -a datas

function handleError {
    declare -A allPossibleErrors=([1]="No URL specified('url' parameter is empty)" [2]="invalid URL submitted" [3]="Rate limit reached" [4]="ip address has been blocked" [5]="shrtcode code (slug) already taken/in use" [6]="unknown error" [7]="node code specified ('code parameter is empty')" [8]="invalid code submitted" [9]="missing required parameters" [10]="trying to shorten a disallowed link")
    error_code=""
    for i in "${arr[@]}"; do
        if [[ $i == *"error_code"* ]]; then
            errCode=$(findIndex $i ":")
            let "errCode+=1"
            error_code=${i:errCode}
            break
        fi
    done
    echo "ERROR CODE : "$error_code
    echo "ERROR : ""${allPossibleErrors[$error_code]}"
}

function findIndex() {
    x="${1%%$2*}"
    [[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}

function extractData {
    for i in "${arr[@]}"; do
        if [[ "$i" == *"short_link"* && "$i" != *"full"* ]]; then
            index="$(findIndex $i ':')"
            let "index+=2"
            data="${i:index}"
            data=${data::-1}
            datas+=($data)
        fi
    done
}

function check {
    ok='"ok":true'
    if [[ "$1" == *$ok* ]]; then
        extractData
        echo "url shortened!, do you want to store it in a file ? (y/n) : "
        read opt
        if [[ $opt == "y" || $opt == "Y" || $opt == "YES" || $opt == "yes" || $opt == "Yes" ]]; then
            if [[ -f shorturls.txt ]]; then
                rm shorturls.txt
            fi

            touch shorturls.txt
            for a in "${datas[@]}"; do
                echo $a >> shorturls.txt
            done
            echo "saved in shorturls.txt!"
        elif [[ $opt == "n" || $opt == "N" || $opt == "no" || $opt == "NO" || $opt == "No" ]]; then
            echo ""
            echo "ORIGINAL URL : $URL"
            echo
            echo "SHORT URLS: "
            for a in "${!datas[@]}"; do
                echo "url `expr $a + 1`" : ${datas[a]}
            done
        else 
            echo "Invalid option!"
        fi
    else 
        handleError
    fi
}
check "${arr[0]}"
