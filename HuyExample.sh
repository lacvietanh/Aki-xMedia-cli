#!/bin/bash
clear
cd "$(dirname $0)"
_I=1
for viPath in source/*/*.mp4; do
    echo -e "\n===  Video $_I: $viPath  ==="
    DIR=$(dirname "$viPath")    ;    echo "DIR: $DIR"
    img=$(echo "$DIR"/Frame/*ver.png)   ;    echo "img: $img"
    echo "out: output/$DIR/"
    ./run.sh -i "$viPath" -i "$img" -m 3 -o "output/$DIR/"
    ((_I++))
done
