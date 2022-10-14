#!/bin/bash
#Script Author: Lac Viet Anh
#Version: 2022.10.14.1751
#need: 1. input folder      2. scale/move input     3. Map select audio (function 2)
clear;
##################  init  ########################
declare os mode inp out enc m inp=() quietflag="-v quiet -stats -loglevel warning"
declare WELCOME_MESSAGE="==== Aki ffmpeg tool for Video - Image - Audio ===="

################  Function  ######################
menu(){
    echo -e "${WELCOME_MESSAGE}"
    echo "Select Tool:"
    echo "  1: Convert Image to Video"
    echo "  2: Join Audio to Video [ -i AUDIO -i VIDEO ]"
    echo "  3: Join Image to Video [ -i VIDEO -i IMAGE ]"
    echo "  4: Convert Media Type (Extension)"
    echo "  5: Check MetaInfo"
    echo "  s: Show System Info (Encoder/HardwareAccel)"
    echo "  g: Show GPU supported Encoder"
    echo "  h: Show help"
    echo "  e: Exit"
}
ask(){
    if [ -z $m ]; then menu; read -p "You select: " m; fi
    case $m in
        1) ImgToVid      ;;
        2) JoinAudToVid  ;;
        3) JoinImgToVid  ;;
        4) ConvertExt    ;;
        5) CheckMetaInfo ;;
        s) ShowSysInfo   ;;
        g) GPU_Encoder   ;;
        h) _help         ;;
        e) exit 0        ;;
        *) echo "Invalid option"; unset m; sleep 1; clear; _help ;;
    esac
}
check_input(){
    for (( i=0; i<${#inp[@]};i++ )); do
        if [[ -f ${inp[$i]} ]] || [[ -d ${inp[$i]} ]]; then
            echo -e "   INPUT \t $i: ${inp[$i]} ....... OK"
        else
            echo -e "   INPUT \t $i: ${inp[$i]} ....... Not Found!"; exit 1
        fi
    done
}

ImgToVid(){ #1
    local outfile=output/"${FUNCNAME[0]}_${out}-${inp[0]}".mp4
    ffmpeg -y -i "${inp[0]}" -c:v $enc -tune stillimage $quietflag "$outfile"
}
JoinAudToVid(){ #2
    local outfile=output/"${FUNCNAME[0]}_${out}-${inp[0]}-${inp[1]}".mp4
    ffmpeg -y -i "${inp[0]}" -i "${inp[1]}" -c:v copy $quietflag "$outfile"
}
JoinImgToVid(){ #3
    local outfile=output/"${FUNCNAME[0]}_${out}-${inp[0]}-${inp[1]}".mp4
    # echo $(realpath ${inp[0]}); echo $(realpath ${inp[1]})
    ffmpeg -y -i "${inp[0]}" -i "${inp[1]}" -c:v $enc \
    -filter_complex [0]overlay=x=0:y=0[out] -map [out] -map 0:a \
    $quietflag  "$outfile"
    echo -e "\t Orginal: \t" $(CheckMetaInfo  "${inp[0]}" v)
    echo -e "\t Output:  \t" $(CheckMetaInfo  "$outfile"  v)
}
ConvertExt(){ #4
    ffmpeg -y -i "${inp[0]}" $quietflag output/"ConvertExt-$out"
}
CheckMetaInfo(){ #5
    local a b opt type
    [ -z $1 ] && a="${inp[0]}" || a="$1"
    ! [ -z $2 ] && b=" -select_streams $2"
    type=$(ffprobe -show_streams "$a" -v error -show_entries stream=codec_type -of default=nw=1|grep -v DISPOSITION)
    case $type in
        video) opt="codec_name,codec_long_name,width,height,bit_rate,sample_rate" ;;
        image) opt="codec_name,codec_long_name,width,height" ;;
        audio) opt="codec_name,codec_long_name,bit_rate,sample_rate" ;;
        *) echo "error when get codec_type"
    esac
    ffprobe -show_streams "$a" -v error $b -show_entries stream=$opt -of default=nw=1 |grep -Ev "DISPOSITION|N/A"
    #ffprobe -show_streams "$a" -v error $b -show_entries stream=$opt |sed 's/\/STREAM/__/g'|grep -E "__|$(echo $opt|tr , '|')"|sed 's/$/; /g'
    echo ""
}
ShowSysInfo(){ #s
    local p
    echo "--Select info:"
    echo "    1: List Encoders"
    echo "    2: List HardwareAccel"
    echo "    3: List Encoder with hwaccel supported"
    echo "    4: CheckMetaInfo (of input)"
    echo "    e: Exit to Menu"
    read -p "Select: " p
    case $p in
        1) ffmpeg -encoders          ;;
        2) ffmpeg -hwaccels          ;;
        3) for i in "$(ffmpeg -hwaccels -v quiet|sed '1d')"; do ffmpeg -encoders $quietflag| grep "$i"; done ;;
        4) CheckMetaInfo "${inp[0]}" v ;;
        e) ask ;;
        *) echo "Invalid Option!"; unset p; sleep 1; clear; ShowSysInfo ::
    esac
}
convertAny(){
    ffmpeg -i "${inp[0]}" $quietflag $out
}
_help(){ #h
    echo "You can run script with directly arguments or select option when no arguments passed"
    echo "   $(basename $0) -m MODE [number] -i INPUT -o OUTPUT -e ENCODER "
    echo "   Remember: the first input will be the bottom layer!"
    echo "   Hardware Accels: h264_nvenc for linux with Nvidia, h264_videotoolbox with AMD"
    echo -e "   \tExample: $(basename $0) -m 3 -i videoInput.mp4 -i frame.png -o output.mp4 -e libx264|h264_nvenc|h264_videotoolbox\n"
    unset m; ask
}
GPU_Encoder() { #e
    local r pre
    os="$(uname|xargs)"; pre="   OS: \t\t $os | Default ENCODER: "
    [ "$os" == "Linux" ]  && r="$(lspci -vnnn | perl -lne 'print if /^\d+\:.+(\[\S+\:\S+\])/' | grep VGA)"
    [ "$os" == "Darwin" ] && r="$(system_profiler SPDisplaysDataType|grep Vendor)"
    if [[ $r =~ NVIDIA ]];       then enc="h264_nvenc"       ; echo -e "$pre $enc | NVIDIA"
        elif [[ $r =~ AMD ]];    then enc="h264_videotoolbox"; echo -e "$pre $enc | AMD"
        elif [[ $r =~ Intel ]];  then enc="h264_qsv"         ; echo -e "$pre $enc | Intel"
    fi
}

##################  run   ########################
cd $(dirname "$0"); mkdir -p ./output
while getopts m:i:o:e: flag
do
    case "${flag}" in
        m) mode=${OPTARG}   ;;
        i) inp+=(${OPTARG}) ;;
        o) out=${OPTARG}    ;;
        e) enc=${OPTARG}    ;;
    esac
done
! [ -z "$inp" ] && check_input
[ -z $enc ]  && GPU_Encoder
echo -e "   ENCODER: \t $enc"
[ -z $out ]  && out="output"
echo -e "   OUTPUT: \t $out"
[ -z $mode ] && ask ||  m=$mode; ask #ask will run directly with mode selected


# for i in ./source/*/Frame/*.png; do
#     f=$(basename "$i"); d=$(dirname "$i")

#     [[ "$f" =~ "+" ]] && mv "$i" "${d}/$(echo $f|head -c 1)-ver.png" || mv "$i" "${d}/$(echo $f|head -c 1)-sqr.png"
# done
