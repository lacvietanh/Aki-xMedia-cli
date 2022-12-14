#!/bin/bash
# Script Author: Lac Viet Anh
# Version: 2022.11.17
# To do: 1. input folder  
# clear
###################  init  ########################
declare os args mode inp out="output/" enc m inp=() quietflag="-v quiet -stats -loglevel warning"
declare WELCOME_MESSAGE="==== Aki ffmpeg tool for Video - Image - Audio ===="

##############  Core Functions  ###################
check_ffmpeg(){
    local v=$(ffmpeg -version $q)
    if [ $? == 1 ]; then
        clear
        echo "NEED FFMPEG INSTALLED TO RUN!"
        exit 1
    fi
}
menu(){
    echo -e "${WELCOME_MESSAGE}"
    echo "Select Tool:"
    echo "  1: Convert Image to Video"
    echo "  2: Join Audio to Video [ -i AUDIO -i VIDEO ]"
    echo "  3: Join Image to Video [ -i VIDEO -i IMAGE ]"
    echo "  4: Convert Media Type (Extension) [default: mp4]"
    echo "  5: Check MetaInfo"
    echo "  s: Show System Info (Encoder/HardwareAccel)"
    echo "  g: Show Default Encoder (GPU)"
    echo "  h: Show help"
    echo "  e: Exit"
}
ask(){
    if [ -z $m ]; then menu; read -p "You select: " m; fi
    case $m in
        1) ImgToVid             ;;
        2) JoinAudToVid         ;;
        3) JoinImgToVid         ;;
        4) ConvertExt           ;;
        5) CheckMetaInfo        ;;
        s) ShowSysInfo          ;;
        g) GetDefault_Encoder   ;;
        h) _help                ;;
        e) exit 0               ;;
        *) echo "Invalid option"; unset m; sleep 1; clear; _help ;;
    esac
}
askInput(){ # $1 define total of input
    local f
    echo " This function require $1 input!"
    echo " Tip: MacOS can drag & drop file/folder to this terminal window instead of typing keyboard"
    echo " Type path to file/folder"
    for (( i=0; i<$1; i++ )); do
        while [ "$f" == "" ]; do
            read -p "Input $((i+1)): " f
            ls -a "$f" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                inp+=("${f}")
            else
                echo "Not found! ($f)"; f=""
            fi
        done
    done
    declare -p inp
    check_input
}
check_input(){
    # echo "input length: ${#inp[@]}"
    for (( i=0; i<${#inp[@]};i++ )); do
        ls -a "${inp[$i]}" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "   INPUT $((i+1)):\t ${inp[$i]}\t....... OK"
        else
            echo -e "   INPUT $((i+1)):\t ${inp[$i]}\t....... Not Found!"; unset inp[$i]
        fi
    done
}
##############  Menu Functions  ###################
ImgToVid(){ #1
    [ -z "$inp" ] && askInput 1
    local outfile="${out}"${FUNCNAME[0]}-$(basename "${inp[0]}").mp4
    ffmpeg -y -i "${inp[0]}" -c:v $enc -tune stillimage $quietflag "$outfile"
}
JoinAudToVid(){ #2
    [ -z "$inp" ] && askInput 2
    local outfile="${out}"${FUNCNAME[0]}_$(basename "${inp[0]}")-$(basename "${inp[1]}").mp4
    ffmpeg -y -i "${inp[0]}" -i "${inp[1]}" -c:v copy -map 1:v:0 -map 0:a:0 -shortest $quietflag "$outfile"
}
JoinImgToVid(){ #3
    [ -z "$inp" ] && askInput 2
    local outfile="${out}"vertical-$(basename "${inp[0]}")-$(basename "${inp[1]}").mp4
    size_i=$(ffprobe -v error -select_streams v -show_entries stream=width,height -of csv=p=0:s=x "${inp[0]}")
    size_h=$(echo $size_i | cut -d x -f 2)
    echo "input 1 size: $size_i | heigh=$size_h"
    ffmpeg -y -i "${inp[0]}" -i "${inp[1]}" -c:v $enc \
    -filter_complex " 
    nullsrc=size=720x1280 [b]; \
    [0]     scale=-1:$size_h    [v]; \
    [1]     scale=-1:$size_h    [i]; \
    [b][v] overlay=:x=0:y=0:shortest=1     [x]; \
    [x][i] overlay=:x=0:y=0   [o]  \
    " -map [o] -map 0:a \
     $quietflag  "$outfile"
    echo -e "\t Orginal: \t" $(CheckMetaInfo  "${inp[0]}" v)
    echo -e "\t Output:  \t" $(CheckMetaInfo  "$outfile"  v)
}
ConvertExt(){ #4
    [ -z "$inp" ] && askInput 1
    local outfile="${out}"${FUNCNAME[0]}-$(basename "${inp[0]}").mp4
    ffmpeg -y -i "${inp[0]}" $quietflag "$outfile"
}
CheckMetaInfo(){ #5
    local a b opt _type
    [ -z "$1" ] && a="${inp[0]}" || a="$1"
    ! [ -z $2 ] && b=" -select_streams $2"
    ls -a "$a" # >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        _type=$(ffprobe -v error -select_streams v -show_entries stream=codec_type -of csv=p=0:s=x "$a")
        echo $_type 
        case $_type in
            video) opt="codec_name,width,height,bit_rate,sample_rate" ;;
            image) opt="codec_name,width,height" ;;
            audio) opt="codec_name,bit_rate,sample_rate" ;;
            *) echo "error | $_type" ;;
        esac
        ffprobe -show_streams "$a" -v error $b -show_entries stream="$opt" -of default=nw=1 |grep -vE "DISPOSITION|TAG"|tr "\n" " "
        echo ""
    fi
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
_help(){ #h
    echo "You can run script with directly arguments or select option when no arguments passed"
    echo "   $(basename $0) -m MODE [number] -i INPUT -o OUTPUT -e ENCODER "
    echo "   Remember: the first input will be the bottom layer!"
    echo "   Hardware Accels: h264_nvenc for linux with Nvidia, h264_videotoolbox with AMD"
    echo -e "   \tExample: $(basename $0) -m 3 -i videoInput.mp4 -i frame.png -o output/output.mp4 -e libx264|h264_nvenc|h264_videotoolbox\n"
    unset m; ask
}
GetDefault_Encoder() { #e
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
cd $(dirname "$0")
pwd
while getopts m:i:o:e: args
do
    case "${args}" in
        m) mode=${OPTARG}     ;;
        i) inp+=("${OPTARG}") ;;
        o) out="${OPTARG}"    ;;
        e) enc=${OPTARG}      ;;
    esac
done
[ -z "$enc" ]  && GetDefault_Encoder
echo -e "   ENCODER: \t $enc"
[ -z "$out" ]  && out="output/"
echo -e "   OUTPUT: \t $out"; mkdir -p "$out"
! [ -z "$inp" ] && check_input ||  echo "Warning! No input file specified! "
if [ -z "$mode" ]; then ask; else m=$mode; ask; fi

# for i in ./source/*/Frame/*.png; do
#     f=$(basename "$i"); d=$(dirname "$i"); num=$(echo "$f"|head -c 1)
#     [[ "$f" =~ "+" ]] && mv "$i" "${d}/${num}-ver.png" || mv "$i" "${d}/${num}-sqr.png"
# done
