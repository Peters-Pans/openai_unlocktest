#!/bin/bash
shopt -s expand_aliases

# 颜色定义
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

# 函数：测试OpenAI解锁情况
function TestOpenaiUnlock() {
    echo "==============[ OpenAI ]==============="
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsLI --max-time 10 "https://chat.openai.com" 2>&1)

    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r OpenAI:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    local result1=$(echo "$tmpresult" | grep 'location' )

    if [ ! -n "$result1" ]; then
        echo -n -e "\r OpenAI:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        local region1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsL --max-time 10 "https://chat.openai.com/cdn-cgi/trace" 2>&1 | grep "loc=" | awk -F= '{print $2}')
        echo -n -e "\r OpenAI:\t\t\t\t${Font_Green}Yes (Region: ${region1})${Font_Suffix}\n"
    fi

    echo "======================================="
}

# 函数：检查IPv4解锁情况
function CheckV4() {
    echo -e " ${Font_SkyBlue}** 正在测试IPv4解锁情况${Font_Suffix}"
    check4=$(curl $curlArgs cloudflare.com/cdn-cgi/trace -4 -s 2>&1)
    echo "--------------------------------"
    echo -e " ${Font_SkyBlue}** 您的网络为: ${local_isp4} (${local_ipv4_asterisk})${Font_Suffix}"
    
    if [ -n  "$check4"  ]; then
        isv4=1
    else
        echo -e "${Font_SkyBlue}当前网络不支持IPv4,跳过...${Font_Suffix}"
        isv4=0
    fi

    echo ""
}

# 函数：检查IPv6解锁情况
function CheckV6() {
    check6=$(curl $curlArgs cloudflare.com/cdn-cgi/trace -6 -s 2>&1)

    if [ -n  "$check6"  ]; then
        echo ""
        echo ""
        echo -e " ${Font_SkyBlue}** 正在测试IPv6解锁情况${Font_Suffix}"
        echo "--------------------------------"
        echo -e " ${Font_SkyBlue}** 您的网络为: ${local_isp6} (${local_ipv6_asterisk})${Font_Suffix}"
        isv6=1
    else
        echo -e "${Font_SkyBlue}当前主机不支持IPv6,跳过...${Font_Suffix}"
        isv6=0
    fi

    echo -e ""
}

# 函数：显示脚本标题
function DisplayScriptTitle() {
    if [[ "$language" == "e" ]]; then
        echo -e " [Stream Platform & Game Region Restriction Test]"
        echo ""
        echo -e "${Font_Green}Github Repository:${Font_Suffix} ${Font_Yellow} https://github.com/1-stream/RegionRestrictionCheck ${Font_Suffix}"
        echo -e "${Font_Purple}Supporting OS: CentOS 6+, Ubuntu 14.04+, Debian 8+, MacOS, Android (Termux), iOS (iSH)${Font_Suffix}"
        echo ""
        echo -e " ** Test Starts At: $(date)"
        echo ""
    else
        # echo -e "${Font_Purple}脚本适配OS: IDK${Font_Suffix}"
        echo ""
        echo -e " ** 测试时间: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo ""
    fi
}

# 清空屏幕
clear

# 显示脚本标题
DisplayScriptTitle

# 执行IPv4和IPv6解锁测试
CheckV4
if [[ "$isv4" -eq 1 ]]; then
    TestOpenaiUnlock 4
fi

CheckV6
if [[ "$isv6" -eq 1 ]]; then
    TestOpenaiUnlock 6
fi
