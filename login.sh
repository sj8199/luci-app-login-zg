#!/bin/sh

# Copyright 2020 BlackYau <blackyau426@gmail.com>
# GNU General Public License v3.0

enable=$(uci get suselogin.@login[0].enable)
[ $enable -eq 0 ] && exit 0

interval=$(($(uci get suselogin.@login[0].interval)*60))

if [ -f /tmp/log/suselogin/last_time ]; then
	differ=$(($(date +%s) - $(cat /tmp/log/suselogin/last_time)))
	if [ $differ -le $interval ];then
		exit 0
	fi
else
	echo -n "$(date +%s)" > /tmp/log/suselogin/last_time
fi

username=$(uci get suselogin.@login[0].username)
password=$(uci get suselogin.@login[0].password)
isp=$(uci get suselogin.@login[0].isp)

# check the online status
captiveReturnCode=`curl -s -I -m 10 -o /dev/null -s -w %{http_code} http://www.google.cn/generate_204`
if [ "$captiveReturnCode" = "204" ]; then
	echo "$(date "+%Y-%m-%d %H:%M:%S"): 您已连接到网络!" >> /tmp/log/suselogin/suselogin.log
	echo -n "$(date +%s)" > /tmp/log/suselogin/last_time
	exit 0
fi

# Get referer page
refererPage=`curl -s "http://www.google.cn/generate_204" | awk -F \' '{print $2}'`

# Structure loginURL
loginURL=`echo $refererPage | awk -F \? '{print $1}'`
loginURL="${loginURL/index.jsp/InterFace.do?method=login}"

# Structure queryString
queryString=`echo $refererPage | awk -F \? '{print $2}'`
queryString="${queryString//&/%2526}"
queryString="${queryString//=/%253D}"

# Login
if [ -n "$loginURL" ]; then
	curl -s -A "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36" \
		-e "$refererPage" \
		-b "EPORTAL_COOKIE_OPERATORPWD=; EPORTAL_AUTO_LAND=; EPORTAL_COOKIE_USERNAME=; EPORTAL_COOKIE_PASSWORD=; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_SERVER_NAME=; EPORTAL_COOKIE_DOMAIN=; EPORTAL_COOKIE_SAVEPASSWORD=false; EPORTAL_COOKIE_DOMAIN=false;" \
		-d "userId=$username&password=$password&service=$isp&queryString=$queryString&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=false" \
		-H "Accept: */*" \
		-H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
		"$loginURL" > /tmp/log/suselogin/login.log
fi

# check the online status
captiveReturnCode=`curl -s -I -m 10 -o /dev/null -s -w %{http_code} http://www.google.cn/generate_204`
if [ "$captiveReturnCode" = "204" ]; then
	echo "$(date "+%Y-%m-%d %H:%M:%S"): 登录成功!" >> /tmp/log/suselogin/suselogin.log
	echo -n "$(date +%s)" > /tmp/log/suselogin/last_time
	exit 0
else
	echo -n "$(date "+%Y-%m-%d %H:%M:%S"): 登录失败,错误信息: " >> /tmp/log/suselogin/suselogin.log
	echo "$(cat /tmp/log/suselogin/login.log)" >> /tmp/log/suselogin/suselogin.log
	echo -n "$(date +%s)" > /tmp/log/suselogin/last_time
fi

exit 0