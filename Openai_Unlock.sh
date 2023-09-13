#!/bin/bash
shopt -s expand_aliases
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

while getopts ":I:M:E:X:P:F:S:" optname; do
    case "$optname" in
        "I")
            iface="$OPTARG"
            useNIC="--interface $iface"
        ;;
        "M")
            if [[ "$OPTARG" == "4" ]]; then
                NetworkType=4
                elif [[ "$OPTARG" == "6" ]]; then
                NetworkType=6
            fi
        ;;
        "E")
            language="e"
        ;;
        "X")
            XIP="$OPTARG"
            xForward="--header X-Forwarded-For:$XIP"
        ;;
        "P")
            proxy="$OPTARG"
            usePROXY="-x $proxy"
        ;;
        "F")
            func="$OPTARG"
        ;;
        "S")
            Stype="$OPTARG"
        ;;
        ":")
            echo "Unknown error while processing options"
            exit 1
        ;;
    esac
    
done

if [ -z "$iface" ]; then
    useNIC=""
fi

if [ -z "$XIP" ]; then
    xForward=""
fi

if [ -z "$proxy" ]; then
    usePROXY=""
fi

if ! mktemp -u --suffix=RRC &>/dev/null; then
    is_busybox=1
fi
curlArgs="$useNIC $usePROXY $xForward"
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1722.64"
UA_Dalvik="Dalvik/2.1.0 (Linux; U; Android 9; ALP-AL00 Build/HUAWEIALP-AL00)"
Media_Cookie=$(curl -s --retry 3 --max-time 10 "https://raw.githubusercontent.com/1-stream/RegionRestrictionCheck/main/cookies")
IATACode=$(curl -s --retry 3 --max-time 10 "https://raw.githubusercontent.com/1-stream/RegionRestrictionCheck/main/reference/IATACode.txt")

countRunTimes() {
    if [ "$is_busybox" == 1 ]; then
        count_file=$(mktemp)
    else
        count_file=$(mktemp --suffix=RRC)
    fi
    RunTimes=$(curl -s --max-time 10 "https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2F1-stream%2FRegionRestrictionCheck&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false" >"${count_file}")
    TodayRunTimes=$(cat "${count_file}" | tail -3 | head -n 1 | awk '{print $5}')
    TotalRunTimes=$(($(cat "${count_file}" | tail -3 | head -n 1 | awk '{print $7}') + 0))
}
countRunTimes

checkOS() {
    ifTermux=$(echo $PWD | grep termux)
    ifMacOS=$(uname -a | grep Darwin)
    if [ -n "$ifTermux" ]; then
        os_version=Termux
        is_termux=1
        elif [ -n "$ifMacOS" ]; then
        os_version=MacOS
        is_macos=1
    else
        os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
    fi
    
    if [[ "$os_version" == "2004" ]] || [[ "$os_version" == "10" ]] || [[ "$os_version" == "11" ]]; then
        is_windows=1
        ssll="-k --ciphers DEFAULT@SECLEVEL=1"
    fi
    
    if [ "$(which apt 2>/dev/null)" ]; then
        InstallMethod="apt"
        is_debian=1
        elif [ "$(which dnf 2>/dev/null)" ] || [ "$(which yum 2>/dev/null)" ]; then
        InstallMethod="yum"
        is_redhat=1
        elif [[ "$os_version" == "Termux" ]]; then
        InstallMethod="pkg"
        elif [[ "$os_version" == "MacOS" ]]; then
        InstallMethod="brew"
    fi
}
checkOS

checkCPU() {
    CPUArch=$(uname -m)
    if [[ "$CPUArch" == "aarch64" ]]; then
        arch=_arm64
        elif [[ "$CPUArch" == "i686" ]]; then
        arch=_i686
        elif [[ "$CPUArch" == "arm" ]]; then
        arch=_arm
        elif [[ "$CPUArch" == "x86_64" ]] && [ -n "$ifMacOS" ]; then
        arch=_darwin
    fi
}
checkCPU

checkDependencies() {
    
    # os_detail=$(cat /etc/os-release 2> /dev/null)
    
    if ! command -v python &>/dev/null; then
        if command -v python3 &>/dev/null; then
            alias python="python3"
        else
            if [ "$is_debian" == 1 ]; then
                echo -e "${Font_Green}Installing python3${Font_Suffix}"
                $InstallMethod update >/dev/null 2>&1
                $InstallMethod install python3 -y >/dev/null 2>&1
                alias python="python3"
                elif [ "$is_redhat" == 1 ]; then
                echo -e "${Font_Green}Installing python3${Font_Suffix}"
                if [[ "$os_version" -gt 7 ]]; then
                    $InstallMethod makecache >/dev/null 2>&1
                    $InstallMethod install python3 -y >/dev/null 2>&1
                    alias python="python3"
                else
                    $InstallMethod makecache >/dev/null 2>&1
                    $InstallMethod install python3 -y >/dev/null 2>&1
                fi
                
                elif [ "$is_termux" == 1 ]; then
                echo -e "${Font_Green}Installing python3${Font_Suffix}"
                $InstallMethod update -y >/dev/null 2>&1
                $InstallMethod install python3 -y >/dev/null 2>&1
                alias python="python3"
                
                elif [ "$is_macos" == 1 ]; then
                echo -e "${Font_Green}Installing python3${Font_Suffix}"
                $InstallMethod install python3
                alias python="python3"
            fi
        fi
    fi
    
    if ! command -v dig &>/dev/null; then
        if [ "$is_debian" == 1 ]; then
            echo -e "${Font_Green}Installing dnsutils${Font_Suffix}"
            $InstallMethod update >/dev/null 2>&1
            $InstallMethod install dnsutils -y >/dev/null 2>&1
            elif [ "$is_redhat" == 1 ]; then
            echo -e "${Font_Green}Installing bind-utils${Font_Suffix}"
            $InstallMethod makecache >/dev/null 2>&1
            $InstallMethod install bind-utils -y >/dev/null 2>&1
            elif [ "$is_termux" == 1 ]; then
            echo -e "${Font_Green}Installing dnsutils${Font_Suffix}"
            $InstallMethod update -y >/dev/null 2>&1
            $InstallMethod install dnsutils -y >/dev/null 2>&1
            elif [ "$is_macos" == 1 ]; then
            echo -e "${Font_Green}Installing bind${Font_Suffix}"
            $InstallMethod install bind
        fi
    fi
    
    if ! command -v jq &>/dev/null; then
        if [ "$is_debian" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod update >/dev/null 2>&1
            $InstallMethod install jq -y >/dev/null 2>&1
            elif [ "$is_redhat" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod makecache >/dev/null 2>&1
            $InstallMethod install jq -y >/dev/null 2>&1
            elif [ "$is_termux" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod update -y >/dev/null 2>&1
            $InstallMethod install jq -y >/dev/null 2>&1
            elif [ "$is_macos" == 1 ]; then
            echo -e "${Font_Green}Installing jq${Font_Suffix}"
            $InstallMethod install jq
        fi
    fi
    
    if [ "$is_macos" == 1 ]; then
        if ! command -v md5sum &>/dev/null; then
            echo -e "${Font_Green}Installing md5sha1sum${Font_Suffix}"
            $InstallMethod install md5sha1sum
        fi
    fi
    
}
checkDependencies

local_ipv4=$(curl $curlArgs -4 -s --max-time 10 cloudflare.com/cdn-cgi/trace | grep ip | awk -F= '{print $2}')
local_ipv4_asterisk=$(awk -F"." '{print $1"."$2".*.*"}' <<<"${local_ipv4}")
local_ipv6=$(curl $curlArgs -6 -s --max-time 20 cloudflare.com/cdn-cgi/trace | grep ip | awk -F= '{print $2}')
local_ipv6_asterisk=$(awk -F":" '{print $1":"$2":"$3":*:*"}' <<<"${local_ipv6}")
local_isp4=$(curl $curlArgs -s -4 --max-time 10 --user-agent "${UA_Browser}" "https://api.ip.sb/geoip/" | jq '.organization' | tr -d '"' &)
local_isp6=$(curl $curlArgs -s -6 --max-time 10 --user-agent "${UA_Browser}" "https://api.ip.sb/geoip/" | jq '.organization' | tr -d '"' &)

ShowRegion() {
    echo -e "${Font_Yellow} ---${1}---${Font_Suffix}"
}

function detect_isp() {
    local lan_ip=$(echo "$1" | grep -Eo "^(10\.[0-9]{1,3}\.[0-9]{1,3}\.((0\/([89]|1[0-9]|2[0-9]|3[012]))|([0-9]{1,3})))|(172\.(1[6789]|2\[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}(\/(1[6789]|2[0-9]|3[012]))?)|(192\.168\.[0-9]{1,3}\.[0-9]{1,3}(\/(1[6789]|2[0-9]|3[012]))?)$")
    if [ -n "$lan_ip" ]; then
        echo "LAN"
        return
    else
        local res=$(curl $curlArgs --user-agent "${UA_Browser}" -s --max-time 20 "https://api.ip.sb/geoip/$1" | jq ".isp" | tr -d '"' )
        echo "$res"
        return
    fi
}

function GameTest_Steam() {
    local result=$(curl $curlArgs --user-agent "${UA_Browser}" -${1} -fsSL --max-time 10 "https://store.steampowered.com/app/761830" 2>&1 | grep priceCurrency | cut -d '"' -f4)

    if [ ! -n "$result" ]; then
        echo -n -e "\r Steam Currency:\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
    else
        echo -n -e "\r Steam Currency:\t\t\t${Font_Green}${result}${Font_Suffix}\n"
    fi
}

function echo_Result() {
    for((i=0;i<${#array[@]};i++))
    do
        echo "$result" | grep "${array[i]}"
        # sleep 0.03
    done;
}

if [ -n "$func" ]; then
    echo -e "${Font_Green}IPv4:${Font_Suffix}"
    $func 4
    echo -e "${Font_Green}IPv6:${Font_Suffix}"
    $func 6
    exit
fi

function NA_UnlockTest() {
    echo "===========[ North America ]==========="
    local result=$(
    MediaUnlockTest_Fox ${1} &
    #MediaUnlockTest_HuluUS ${1} &
    MediaUnlockTest_NFLPlus ${1} &
    MediaUnlockTest_ESPNPlus ${1} &
    MediaUnlockTest_EPIX ${1} &
    MediaUnlockTest_Starz ${1} &
    MediaUnlockTest_Philo ${1} &
    MediaUnlockTest_FXNOW ${1} &
    MediaUnlockTest_HBOMax ${1} &
    MediaUnlockTest_MaxCom ${1} &
    )
    wait
    local array=("FOX:" "Hulu:" "NFL+" "ESPN+:" "Epix:" "Starz:" "Philo:" "FXNOW:" "Max.com")
    echo_Result ${result} ${array}
    MediaUnlockTest_TLCGO ${1}
    echo "$result" | grep "HBO Max:"
    local result=$(
    MediaUnlockTest_Shudder ${1} &
    MediaUnlockTest_BritBox ${1} &
    MediaUnlockTest_Crackle ${1} &
    MediaUnlockTest_CWTV ${1} &
    MediaUnlockTest_AETV ${1} &
    MediaUnlockTest_NBATV ${1} &
    MediaUnlockTest_FuboTV ${1} &
    MediaUnlockTest_TubiTV ${1} &
    )
    wait
    local array=("Shudder:" "BritBox:" "Crackle:" "CW TV:" "A&E TV:" "NBA TV:")
    echo_Result ${result} ${array}
    MediaUnlockTest_NBCTV ${1}
    echo "$result" | grep "Fubo TV:"
    echo "$result" | grep "Tubi TV:"
    local result=$(
    MediaUnlockTest_SlingTV ${1} &
    MediaUnlockTest_PlutoTV ${1} &
    MediaUnlockTest_AcornTV ${1} &
    MediaUnlockTest_SHOWTIME ${1} &
    MediaUnlockTest_encoreTVB ${1} &
    MediaUnlockTest_Funimation ${1} &
    MediaUnlockTest_DiscoveryPlus ${1} &
    MediaUnlockTest_ParamountPlus ${1} &
    MediaUnlockTest_PeacockTV ${1} &
    MediaUnlockTest_Popcornflix ${1} &
    MediaUnlockTest_Crunchyroll ${1} &
    MediaUnlockTest_ATTNOW ${1} &
    MediaUnlockTest_KBSAmerican ${1} &
    MediaUnlockTest_KOCOWA ${1} &
    MediaUnlockTest_MathsSpot ${1} &
    )
    wait
    local array=("Sling TV:" "Pluto TV:" "Acorn TV:" "SHOWTIME:" "encoreTVB:" "Funimation:" "Discovery" "Paramount+:" "Peacock TV:" "Popcornflix:" "Crunchyroll:" "Directv Stream:" "KBS American:" "KOCOWA:" "Maths Spot:")
    echo_Result ${result} ${array}
    ShowRegion CA
    local result=$(
    MediaUnlockTest_CBCGem ${1} &
    MediaUnlockTest_Crave ${1} &
    )
    wait
    echo "$result" | grep "CBC Gem:"
    echo "$result" | grep "Crave:"
    echo "======================================="
}

function EU_UnlockTest() {
    echo "===============[ Europe ]=============="
    local result=$(
    MediaUnlockTest_RakutenTV ${1} &
    MediaUnlockTest_Funimation ${1} &
    MediaUnlockTest_SkyShowTime ${1} &
    MediaUnlockTest_HBOMax ${1} &
    MediaUnlockTest_MathsSpot ${1} &
    # MediaUnlockTest_HBO_Nordic ${1}
    # MediaUnlockTest_HBOGO_EUROPE ${1}
    )
    wait
    local array=("Rakuten TV:" "Funimation:" "SkyShowTime:" "HBO Max:" "Maths Spot:")
    echo_Result ${result} ${array}
    ShowRegion GB
    local result=$(
    MediaUnlockTest_SkyGo ${1} &
    MediaUnlockTest_BritBox ${1} &
    MediaUnlockTest_ITVHUB ${1} &
    MediaUnlockTest_Channel4 ${1} &
    MediaUnlockTest_Channel5 ${1} &
    MediaUnlockTest_BBCiPLAYER ${1} &
    MediaUnlockTest_DiscoveryPlusUK ${1} &
    )
    wait
    local array=("Sky Go:" "BritBox:" "ITV Hub:" "Channel 4:" "Channel 5" "BBC iPLAYER:" "Discovery+ UK:")
    echo_Result ${result} ${array}
    ShowRegion FR
    local result=$(
    #MediaUnlockTest_Salto ${1} &
    MediaUnlockTest_CanalPlus ${1} &
    MediaUnlockTest_Molotov ${1} &
    MediaUnlockTest_Joyn ${1} &
    MediaUnlockTest_SKY_DE ${1} &
    MediaUnlockTest_ZDF ${1} &
    )
    wait
    local array=("Canal+:" "Molotov:")
    echo_Result ${result} ${array}
    ShowRegion DE
    local array=("Joyn:" "Sky:" "ZDF:")
    echo_Result ${result} ${array}
    ShowRegion NL
    local result=$(
    # MediaUnlockTest_NLZIET ${1} &
    MediaUnlockTest_videoland ${1} &
    MediaUnlockTest_NPO_Start_Plus ${1} &
    # MediaUnlockTest_HBO_Spain ${1}
    # MediaUnlockTest_PANTAYA ${1} &
    MediaUnlockTest_RaiPlay ${1} &
    #MediaUnlockTest_MegogoTV ${1}
    MediaUnlockTest_Amediateka ${1} &
    )
    wait
    local array=("NLZIET:" "videoland:" "NPO Start Plus:")
    echo_Result ${result} ${array}
    # ShowRegion ES
    # echo "$result" | grep "PANTAYA:"
    ShowRegion IT
    echo "$result" | grep "Rai Play:"
    ShowRegion RU
    echo "$result" | grep "Amediateka:"
    echo "======================================="
}

function HK_UnlockTest() {
    echo "=============[ Hong Kong ]============="
       if [[ "$1" == 4 ]] || [[ "$Stype" == "force6" ]];then
	local result=$(
	    MediaUnlockTest_NowE ${1} &
	    MediaUnlockTest_ViuTV ${1} &
	    MediaUnlockTest_MyTVSuper ${1} &
	    MediaUnlockTest_HBOGO_ASIA ${1} &
	    MediaUnlockTest_BilibiliHKMCTW ${1} &
	)
    else
	echo -e "${Font_Green}此区域无IPv6可用流媒体，跳过……${Font_Suffix}"
    fi
    wait
    local array=("Now E:" "Viu.TV:" "MyTVSuper:" "HBO GO Asia:" "BiliBili Hongkong/Macau/Taiwan:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function TW_UnlockTest() {
    echo "==============[ Taiwan ]==============="
    local result=$(
    MediaUnlockTest_KKTV ${1} &
    MediaUnlockTest_LiTV ${1} &
    MediaUnlockTest_MyVideo ${1} &
    MediaUnlockTest_4GTV ${1} &
    MediaUnlockTest_LineTV.TW ${1} &
    MediaUnlockTest_HamiVideo ${1} &
    MediaUnlockTest_Catchplay ${1} &
    MediaUnlockTest_HBOGO_ASIA ${1} &
    MediaUnlockTest_BahamutAnime ${1} &
    #MediaUnlockTest_ElevenSportsTW ${1}
    MediaUnlockTest_BilibiliTW ${1} &
    )
    wait
    local array=("KKTV:" "LiTV:" "MyVideo:" "4GTV.TV:" "LineTV.TW:" "Hami Video:" "CatchPlay+:" "HBO GO Asia:" "Bahamut Anime:" "Bilibili Taiwan Only:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function JP_UnlockTest() {
    echo "===============[ Japan ]==============="
    local result=$(
    MediaUnlockTest_NHKPlus ${1} &
    MediaUnlockTest_DMMTV ${1} &
    MediaUnlockTest_AbemaTV_IPTest ${1} &
    MediaUnlockTest_Niconico ${1} &
    MediaUnlockTest_music.jp ${1} &
    MediaUnlockTest_Telasa ${1} &
    MediaUnlockTest_Paravi ${1} &
    MediaUnlockTest_unext ${1} &
    MediaUnlockTest_HuluJP ${1} &
    )
    wait
    local array=("NHK+" "DMM TV:" "Abema.TV:" "Niconico:" "music.jp:" "Telasa:" "Paravi:" "U-NEXT:" "Hulu Japan:")
    echo_Result ${result} ${array}
    local result=$(
    MediaUnlockTest_TVer ${1} &
    MediaUnlockTest_wowow ${1} &
    MediaUnlockTest_VideoMarket ${1} &
    MediaUnlockTest_FOD ${1} &
    MediaUnlockTest_Radiko ${1} &
    MediaUnlockTest_DAM ${1} &
    MediaUnlockTest_J:COM_ON_DEMAND ${1} &
    )
    wait
    local array=("TVer:" "WOWOW:" "VideoMarket:" "FOD(Fuji TV):" "Radiko:" "Karaoke@DAM:" "J:com On Demand:")
    echo_Result ${result} ${array}
    ShowRegion Game
    local result=$(
    MediaUnlockTest_Kancolle ${1} &
    MediaUnlockTest_UMAJP ${1} &
    MediaUnlockTest_KonosubaFD ${1} &
    MediaUnlockTest_PCRJP ${1} &
    MediaUnlockTest_WFJP ${1} &
    MediaUnlockTest_ProjectSekai ${1} &
    )
    wait
    local array=("Kancolle Japan:" "Pretty Derby Japan:" "Konosuba Fantastic Days:" "Princess Connect Re:Dive Japan:" "World Flipper Japan:" "Project Sekai: Colorful Stage:")
    echo_Result ${result} ${array}
    echo "======================================="

}

function Global_UnlockTest() {
    echo ""
    echo "============[ Multination ]============"
    if [[ "$1" == 4 ]] || [[ "$Stype" == "force6" ]];then
        local result=$(
        MediaUnlockTest_Dazn ${1} &
        MediaUnlockTest_HotStar ${1} &
        MediaUnlockTest_DisneyPlus ${1} &
        MediaUnlockTest_Netflix ${1} &
        MediaUnlockTest_YouTube_Premium ${1} &
        MediaUnlockTest_PrimeVideo_Region ${1} &
        MediaUnlockTest_TVBAnywhere ${1} &
        MediaUnlockTest_iQYI_Region ${1} &
        MediaUnlockTest_Viu.com ${1} &
        MediaUnlockTest_YouTube_CDN ${1} &
        MediaUnlockTest_NetflixCDN ${1} &
        MediaUnlockTest_Spotify ${1} &
        #MediaUnlockTest_Instagram.Music ${1}
        GameTest_Steam ${1} &
        MediaUnlockTest_Google ${1} &
        MediaUnlockTest_Tiktok ${1} &
        )
    else
        local result=$(
        # MediaUnlockTest_Dazn ${1} &
        MediaUnlockTest_HotStar ${1} &
        MediaUnlockTest_DisneyPlus ${1} &
        MediaUnlockTest_Netflix ${1} &
        MediaUnlockTest_YouTube_Premium ${1} &
        # MediaUnlockTest_PrimeVideo_Region ${1} &
        # MediaUnlockTest_TVBAnywhere ${1} &
        # MediaUnlockTest_iQYI_Region ${1} &
        # MediaUnlockTest_Viu.com ${1} &
        MediaUnlockTest_YouTube_CDN ${1} &
        MediaUnlockTest_NetflixCDN ${1} &
        MediaUnlockTest_Spotify ${1} &
        #MediaUnlockTest_Instagram.Music ${1}
        # GameTest_Steam ${1} &
        MediaUnlockTest_Google ${1} &
        )
    fi
    wait
    local array=("Dazn:" "HotStar:" "Disney+:" "Netflix:" "YouTube Premium:" "Amazon Prime Video:" "TVBAnywhere+:" "iQyi Oversea:" "Viu.com:" "Tiktok" "YouTube CDN:" "Google" "YouTube Region:" "Netflix Preferred CDN:" "Spotify Registration:" "Steam Currency:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function SA_UnlockTest() {
    echo "===========[ South America ]==========="
    local result=$(
    MediaUnlockTest_StarPlus ${1} &
    MediaUnlockTest_HBOMax ${1} &
    MediaUnlockTest_DirecTVGO ${1} &
    MediaUnlockTest_Funimation ${1} &
    )
    wait
    local array=("Star+:" "HBO Max:" "DirecTV Go:" "Funimation:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function OA_UnlockTest() {
    echo "==============[ Oceania ]=============="
    local result=$(
    MediaUnlockTest_NBATV ${1} &
    MediaUnlockTest_AcornTV ${1} &
    MediaUnlockTest_SHOWTIME ${1} &
    MediaUnlockTest_BritBox ${1} &
    MediaUnlockTest_Funimation ${1} &
    MediaUnlockTest_ParamountPlus ${1} &
    )
    wait
    local array=("NBA TV:" "Acorn TV:" "SHOWTIME:" "BritBox:" "Funimation:" "Paramount+:")
    echo_Result ${result} ${array}
    ShowRegion AU
    local result=$(
    MediaUnlockTest_Stan ${1} &
    MediaUnlockTest_Binge ${1} &
    MediaUnlockTest_7plus ${1} &
    MediaUnlockTest_Channel9 ${1} &
    MediaUnlockTest_Channel10 ${1} &
    MediaUnlockTest_ABCiView ${1} &
    MediaUnlockTest_OptusSports ${1} &
    MediaUnlockTest_SBSonDemand ${1} &
    )
    wait
    echo "$result" | grep "Stan:"
    echo "$result" | grep "Binge:"
    MediaUnlockTest_Docplay ${1}
    local array=("7plus:" "Channel 9:" "Channel 10:" "ABC iView:")
    echo_Result ${result} ${array}
    MediaUnlockTest_KayoSports ${1}
    echo "$result" | grep "Optus Sports:"
    echo "$result" | grep "SBS on Demand:"
    ShowRegion NZ
    local result=$(
    MediaUnlockTest_NeonTV ${1} &
    MediaUnlockTest_SkyGONZ ${1} &
    MediaUnlockTest_ThreeNow ${1} &
    MediaUnlockTest_MaoriTV ${1} &
    )
    wait
    local array=("Neon TV:" "SkyGo NZ:" "ThreeNow:" "Maori TV:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function KR_UnlockTest() {
    echo "==============[ Korean ]==============="
    local result=$(
    MediaUnlockTest_Wavve ${1} &
    MediaUnlockTest_Tving ${1} &
    MediaUnlockTest_CoupangPlay ${1} &
    MediaUnlockTest_NaverTV ${1} &
    MediaUnlockTest_Afreeca ${1} &
    MediaUnlockTest_KBSDomestic ${1} &
    #MediaUnlockTest_KOCOWA ${1} &
    )
    wait
    local array=("Wavve:" "Tving:" "Coupang Play:" "Naver TV:" "Afreeca TV:" "KBS Domestic:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function SEA_UnlockTest(){
    echo "==========[ SouthEastAsia ]============"
    local result=$(
    MediaUnlockTest_HBOGO_ASIA ${1} &
    MediaUnblockTest_BGlobalSEA ${1} &
    )
    wait
    local array=("HBO GO Asia:" "B-Global SouthEastAsia:")
    echo_Result ${result} ${array}
    ShowRegion SG
    local result=$(
        MediaUnlockTest_Catchplay ${1} &
        MediaUnlockTest_meWATCH ${1} &
        MediaUnlockTest_StarhubTVPlus ${1} &
    )
    wait
    local array=("meWATCH" "Starhub" "CatchPlay+:")
    echo_Result ${result} ${array}
    ShowRegion TH
    local result=$(
    #MediaUnlockTest_TrueID ${1} &
    MediaUnlockTest_AISPlay ${1} &
    MediaUnblockTest_BGlobalTH ${1} &
    )
    wait
    local array=("TrueID" "AIS Play" "B-Global Thailand Only")
    echo_Result ${result} ${array}
    ShowRegion ID
    local result=$(
    MediaUnlockTest_Vidio ${1} &
    MediaUnblockTest_BGlobalID ${1} &
    )
    wait
    local array=("Vidio" "B-Global Indonesia Only")
    echo_Result ${result} ${array}
    ShowRegion VN
    local result=$(
    # MediaUnlockTest_VTVcab ${1} &
    MediaUnlockTest_MYTV ${1} &
    MediaUnlockTest_ClipTV ${1} &
    MediaUnlockTest_GalaxyPlay ${1} &
    MediaUnblockTest_BGlobalVN ${1} &
    )
    wait
    local array=("MYTV" "Clip TV" "Galaxy Play" "B-Global Việt Nam Only" )
    echo_Result ${result} ${array}
    ShowRegion IN
    local result=$(
    MediaUnlockTest_MXPlayer ${1} &
    MediaUnlockTest_TataPlay ${1} &
    )
    wait
    local array=("MXPlayer" "Tata Play" )
    echo_Result ${result} ${array}
    echo "======================================="
}

function Sport_UnlockTest() {
    echo "===============[ Sport ]==============="
    local result=$(
    MediaUnlockTest_Dazn ${1} &
    MediaUnlockTest_StarPlus ${1} &
    MediaUnlockTest_ESPNPlus ${1} &
    MediaUnlockTest_NBATV ${1} &
    MediaUnlockTest_FuboTV ${1} &
    MediaUnlockTest_MolaTV ${1} &
    MediaUnlockTest_SetantaSports ${1} &
    MediaUnlockTest_OptusSports ${1} &
    MediaUnlockTest_BeinConnect ${1} &
    MediaUnlockTest_EurosportRO ${1} &
    )
    wait
    local array=("Dazn:" "Star+:" "ESPN+:" "NBA TV:" "Fubo TV:" "Mola TV:" "Setanta Sports:" "Optus Sports:" "Bein Sports Connect:" "Eurosport RO:")
    echo_Result ${result} ${array}
    echo "======================================="
}

function Openai_UnlockTest() {
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsLI --max-time 10 "https://chat.openai.com" 2>&1)
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Openai:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi
    local result1=$(echo "$tmpresult" | grep 'location' )
    if [ ! -n "$result1" ]; then
    	echo -n -e "\r Openai:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
    	local region1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsL --max-time 10 "https://chat.openai.com/cdn-cgi/trace" 2>&1 | grep "loc=" | awk -F= '{print $2}')
        echo -n -e "\r Openai:\t\t\t\t${Font_Green}Yes (Region: ${region1})${Font_Suffix}\n"
    fi
}

function CheckV4() {
    if [[ "$language" == "e" ]]; then
        if [[ "$NetworkType" == "6" ]]; then
            isv4=0
            echo -e "User Choose to Test Only IPv6 Results, Skipping IPv4 Testing..."
        else
            check4=$(curl $curlArgs cloudflare.com/cdn-cgi/trace -4 -s 2>&1)
            echo -e "Your IPv4 Network Provider: ${local_isp4} (${local_ipv4_asterisk}) "
            if [ -n  "$check4"  ]; then
                isv4=1
            else
                echo -e "No IPv4 Connectivity Found, Abort IPv4 Testing..."
                isv4=0
            fi
        fi
    else
        if [[ "$NetworkType" == "6" ]]; then
            isv4=0
            echo -e "用户选择只检测IPv6结果，跳过IPv4检测..."
        else
            check4=$(curl $curlArgs cloudflare.com/cdn-cgi/trace -4 -s 2>&1)
            echo -e "您的IPv4网络为: ${local_isp4} (${local_ipv4_asterisk})"
            if [ -n  "$check4"  ]; then
                isv4=1
            else
                echo -e "当前网络不支持IPv4,跳过..."
                isv4=0
            fi
        fi
    fi
}

function CheckV6() {
    if [[ "$language" == "e" ]]; then
        if [[ "$NetworkType" == "4" ]]; then
            isv6=0
            if [ -z "$usePROXY" ]; then
                echo -e "User Choose to Test Only IPv4 Results, Skipping IPv6 Testing..."
            fi
        else
            check6=$(curl $curlArgs cloudflare.com/cdn-cgi/trace -6 -s 2>&1)
            if [ -n  "$check6"  ]; then
                echo -e "Your IPv6 Network Provider: ${local_isp6} (${local_ipv6_asterisk})"
                isv6=1
            else
                echo -e "No IPv6 Connectivity Found, Abort IPv6 Testing..."
                isv6=0
            fi
        fi
    else
        if [[ "$NetworkType" == "4" ]]; then
            isv6=0
            if [ -z "$usePROXY" ]; then
                echo -e "用户选择只检测IPv4结果，跳过IPv6检测..."
            fi
        else
            check6=$(curl $curlArgs cloudflare.com/cdn-cgi/trace -6 -s 2>&1)
            if [ -n  "$check6"  ]; then
                echo -e "您的IPv6网络为: ${local_isp6} (${local_ipv6_asterisk})"
                isv6=1
            else
                echo -e "当前主机不支持IPv6,跳过..."
                isv6=0
            fi
        fi
    fi
}


function Goodbye() {
    if [[ "$language" == "e" ]]; then
        echo -e "${Font_Green}Testing Done! Thanks for Using This Script! ${Font_Suffix}"
        echo -e ""
        echo -e "${Font_Yellow}Number of Script Runs for Today: ${TodayRunTimes}; Total Number of Script Runs: ${TotalRunTimes} ${Font_Suffix}"
    else
        echo -e "${Font_Green}本次测试已结束，感谢使用此脚本 ${Font_Suffix}"
        echo -e ""
        echo -e "${Font_Yellow}检测脚本当天运行次数: ${TodayRunTimes}; 共计运行次数: ${TotalRunTimes} ${Font_Suffix}"
    fi
}

clear

function ScriptTitle() {
    if [[ "$language" == "e" ]]; then
        echo -e " [Stream Platform & Game Region Restriction Test]"
        echo ""
        echo ""
        echo -e " ** Test Starts At: $(date)"
        echo ""
    else
        echo -e " [流媒体平台及游戏区域限制测试]"
        echo ""
        echo -e " ** 测试时间: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo ""
    fi
}
ScriptTitle

function Start() {
   if [[ "$language" == "e" ]]; then
        echo -e "${Font_Blue}Please Select Test Region or Press ENTER to Test All Regions${Font_Suffix}"
        # 省略其他菜单选项
        num=10  # 在这里将num设置为10
    else
        echo -e "${Font_Blue}请选择检测项目，直接按回车将进行全区域检测${Font_Suffix}"
        # 省略其他菜单选项
        num=10  # 在这里将num设置为10
    fi
}
Start

function RunScript() {

    if [[ -n "${num}" ]]; then
        if [[ "$num" -eq 1 ]]; then
            clear
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                TW_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                TW_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 2 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                HK_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                HK_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 3 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                JP_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                JP_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 4 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                NA_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                NA_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 5 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                SA_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                SA_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 6 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                EU_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                EU_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 7 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                OA_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                OA_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 8 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                KR_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                KR_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 9 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
                SEA_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
                SEA_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 10 ]]; then
            clear
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Openai_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Openai_UnlockTest 6
            fi

        elif [[ "$num" -eq 99 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Sport_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Sport_UnlockTest 6
            fi
            Goodbye

        elif [[ "$num" -eq 0 ]]; then
            clear
            ScriptTitle
            CheckV4
            if [[ "$isv4" -eq 1 ]]; then
                Global_UnlockTest 4
            fi
            CheckV6
            if [[ "$isv6" -eq 1 ]]; then
                Global_UnlockTest 6
            fi
            Goodbye

        else
            echo -e "${Font_Red}请重新执行脚本并输入正确号码${Font_Suffix}"
            echo -e "${Font_Red}Please Re-run the Script with Correct Number Input${Font_Suffix}"
            return
        fi
    else
        clear
        ScriptTitle
        CheckV4
        if [[ "$isv4" -eq 1 ]]; then
            Global_UnlockTest 4
            TW_UnlockTest 4
            HK_UnlockTest 4
            JP_UnlockTest 4
            NA_UnlockTest 4
            SA_UnlockTest 4
            EU_UnlockTest 4
            OA_UnlockTest 4
            KR_UnlockTest 4
        fi
        CheckV6
        if [[ "$isv6" -eq 1 ]]; then
            Global_UnlockTest 6
            TW_UnlockTest 6
            HK_UnlockTest 6
            JP_UnlockTest 6
            NA_UnlockTest 6
            SA_UnlockTest 6
            EU_UnlockTest 6
            OA_UnlockTest 6
            KR_UnlockTest 6
        fi
    fi
}
wait
RunScript
