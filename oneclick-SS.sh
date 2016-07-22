#!/bin/bash

#check user account
user_name=`whoami`
if [ "$user_name" != "root" ]; then
	echo "Suggest use root account to run this script,exit"
	exit
fi

#Support Centos 6.x
Support_OS=`cat /etc/issue|grep -E 6\.[0-9]`
if [ "$Support_OS" != "" ] ;then
        echo "System version:ok"
else
        echo "System Not Support"
        exit
fi

#python-setuptools status
Pythonsetuptools_Status=`yum list python-setuptools|grep "Error"`
if [ "$Pythonsetuptools_Status" != "" ] ;then
	echo "Installing python-setuptools"
        yum -y install python-setuptools > /dev/null 2>&1
else
        echo "Python-setuptools:ok"
fi

#qrencode status
qrencode --version > /dev/null 2>&1
if [ $? != 0 ]; then
        echo "Installing qrencode"
	yum -y install qrencode > /dev/null 2>&1
else
        echo "qrencode:ok"
fi


#pip status
pip --version > /dev/null 2>&1
if [ $? != 0 ]; then
	echo "Installing pip"
	easy_install pip > /dev/null 2>&1
else
        echo "Pip:ok"
fi

#shadowsocks status
ssserver --version > /dev/null 2>&1
if [ $? != 0 ]; then
        echo "Installing shadowsocks"
       pip install shadowsocks > /dev/null 2>&1
else
        echo "shadowsocks:ok"
fi

#Get ipv4 from public API
server_ip=`curl  -s http://ipecho.net/plain`

if [ "$server_ip" ==  "" ] ; then
	echo "Can't get your public ipv4 address,please check your network or Manual input."
	server_ip="Manual input your VPS's ipv4 address[获取公网ip失败，请手动输入]"
fi
#Generate a password
client_password=`< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-12};echo;`

#Make a backup of Shadowsocks config
time_stamp=`date +%Y%m%d%H%M%S`
if [ -f /etc/shadowsocks.json ] ; then
	echo "/etc/shadowsocks.json file exits,rename to shadowsocks.json.bak${time_stamp}"
	mv /etc/shadowsocks.json /etc/shadowsocks.json.bak${time_stamp}
fi
#Generate Shadowsocks config
echo  "{">/etc/shadowsocks.json
echo "    \"server\":\"0.0.0.0\",">>/etc/shadowsocks.json
echo "    \"server_port\":8388,">>/etc/shadowsocks.json
echo "    \"local_address\": \"127.0.0.1\",">>/etc/shadowsocks.json
echo "    \"local_port\":1080,">>/etc/shadowsocks.json
echo "    \"password\":\"$client_password\",">>/etc/shadowsocks.json
echo "    \"timeout\":300,">>/etc/shadowsocks.json
echo "    \"method\":\"aes-256-cfb\",">>/etc/shadowsocks.json
echo "    \"fast_open\": false">>/etc/shadowsocks.json
echo  "}">>/etc/shadowsocks.json
#iptabels allow 8388 port
iptables -I INPUT -p tcp --dport 8388 -j ACCEPT
#restart Shadowsocks Server
ssserver -c /etc/shadowsocks.json -d stop
ssserver -c /etc/shadowsocks.json -d start
if [ $? != 0 ]; then
	echo  "ShadowServer start failed,please check"
	exit
else
	echo  "ShadowServer start Success"
fi

#Install Over
echo "ClientDownloadUrl[客户端下载地址]:[https://github.com/shadowsocks/shadowsocks-windows/wiki/Shadowsocks-Windows-%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E]"
echo "If client can't work,try install 'Microsoft .NET Framework 4.5' DownloadUrl[https://www.microsoft.com/zh-CN/download/details.aspx?id=30653]"
echo ""
echo 'Install Over,client info'
echo ""
echo "客户端配置信息:"
echo "Server_IP[服务器IP]:$server_ip"
echo "Server_Port[服务器端口]:8388"
echo "Password[密码]:$client_password"
echo "encrypt_methmod[加密]:aes-256-cfb"
echo "proxy_port[代理端口]:1082"

echo "Use QR Code:"
echo ""
client_base64=`echo "aes-256-cfb:$client_password@$server_ip:8388"|base64`
echo "ss://$client_base64"| qrencode -o - -t UTF8
echo ""
