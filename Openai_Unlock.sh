#!/bin/bash

# 定义颜色变量
Font_Red='\033[31m'
Font_Green='\033[32m'
Font_Suffix='\033[0m'

# 定义函数：检查OpenAI服务可用性
function Openai_UnlockTest() {
    echo "==============[ Openai ]==============="

    # 发送HTTP请求到OpenAI的网站
    local tmpresult=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsLI --max-time 10 "https://chat.openai.com" 2>&1)

    # 检查是否存在网络连接错误
    if [[ "$tmpresult" == "curl"* ]]; then
        echo -n -e "\r Openai:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        return
    fi

    # 检查是否存在'location'信息
    local result1=$(echo "$tmpresult" | grep 'location' )
    if [ ! -n "$result1" ]; then
        echo -n -e "\r Openai:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
    else
        # 发送HTTP请求获取区域信息
        local region1=$(curl $curlArgs -${1} --user-agent "${UA_Browser}" -SsL --max-time 10 "https://chat.openai.com/cdn-cgi/trace" 2>&1 | grep "loc=" | awk -F= '{print $2}')
        echo -n -e "\r Openai:\t\t\t\t${Font_Green}Yes (Region: ${region1})${Font_Suffix}\n"
    fi

    echo "======================================="
}

# 清空屏幕
clear

# 调用脚本标题函数（假设已经在其他地方定义）
# ScriptTitle

# 检查IPv4连接性
CheckV4
if [[ "$isv4" -eq 1 ]]; then
    Openai_UnlockTest 4
fi

# 检查IPv6连接性
CheckV6
if [[ "$isv6" -eq 1 ]]; then
    Openai_UnlockTest 6
fi

# 打印结束消息
echo "Goodbye"
