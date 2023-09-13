function Openai_UnlockTest() {
    echo "==============[ Openai ]==============="
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

    echo "======================================="
}


function ScriptTitle() {
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
ScriptTitle

function RunScript() {
    clear
    ScriptTitle
    CheckV4
    if [[ "$isv4" -eq 1 ]]; then
        Openai_UnlockTest 4
    fi
        CheckV6
    if [[ "$isv6" -eq 1 ]]; then
        Openai_UnlockTest 6
    fi

}
wait
RunScript
