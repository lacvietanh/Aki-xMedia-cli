#!/bin/bash
declare opt args
clear
cd "$(dirname $0)"/source

MERGE(){
    type=$1
    if [ -z $1 ]; then echo "provide TYPE as arg 1"; exit 1; fi
    local i=1
    for viPath in */*.mp4; do
        echo -e "\n===  Video $i: $viPath  ==="
        DIR=$(dirname "$viPath")    ;    echo "DIR: $DIR"
        VID=$(basename "$viPath")   ;    echo "VID: $VID"
        img=$(echo "$DIR"/Frame/*${type}.png)   ;    echo "img: $img"
        echo "out: output/$DIR/"
        # ls ../../downloaded/$VID #check available
        ../run.sh -i ../downloaded/$VID -i "source/$img" -m3 -o "output/$DIR/"
        ((i++))
    done
}

while getopts t: args
do
    case "${args}" in
        t) opt=${OPTARG}    ;;
    esac
done

MERGE $opt

