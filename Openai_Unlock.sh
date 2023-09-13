#!/bin/bash

# 设置颜色变量
Font_Red='\033[31m'
Font_Green='\033[32m'
Font_Suffix='\033[0m'

# 定义函数：检查OpenAI服务可用性
function CheckOpenAI() {
    echo "==============[ OpenAI ]==============="

    # 使用curl测试OpenAI网站连接
    local response=$(curl -Is https://chat.openai.com | head -n 1)

    if [[ "$response" == *"200 OK"* ]]; then
        echo -e "\r OpenAI:\t\t\t${Font_Green}可用${Font_Suffix}"
    else
        echo -e "\r OpenAI:\t\t\t${Font_Red}不可用${Font_Suffix}"
    fi

    echo "======================================="
}

# 清空屏幕
clear

# 调用函数检查OpenAI服务可用性
CheckOpenAI

