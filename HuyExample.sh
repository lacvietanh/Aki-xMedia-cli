#!/bin/bash
clear
cd "$(dirname $0)"/source
_I=1
for viPath in */*.mp4; do
    echo -e "\n===  Video $_I: $viPath  ==="
    DIR=$(dirname "$viPath")    ;    echo "DIR: $DIR"
    img=$(echo "$DIR"/Frame/*ver.png)   ;    echo "img: $img"
    echo "out: output/$DIR/"
    ../run.sh -i "source/$viPath" -i "source/$img" -m3 -o "output/$DIR/"
    ((_I++))
done
