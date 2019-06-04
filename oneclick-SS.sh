#!/bin/bash

#check user account
user_name=`whoami`
if [ "$user_name" != "root" ]; then
	echo "Suggest use root account to run this script,exit"
	exit
fi

#python-setuptools status
easy_install --version > /dev/null 2>&1
if [ $? != 0 ]; then
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
fi

#install qrencode with source code
qrencode --version > /dev/null 2>&1
if [ $? != 0 ]; then
	echo "Try installing qrencode with source code"
	yum update -y > /dev/null 2>&1
	yum install wget -y > /dev/null 2>&1
	yum install gcc -y > /dev/null 2>&1
	yum install libpng* -y > /dev/null 2>&1
	wget -q -c --no-check-certificate 'https://fukuchi.org/works/qrencode/qrencode-3.4.4.tar.gz'
	tar zxf qrencode-3.4.4.tar.gz
	cd qrencode-3.4.4
	./configure > /dev/null 2>&1
	make > /dev/null 2>&1
	make install > /dev/null 2>&1
fi
#
qrencode --version > /dev/null 2>&1
if [ $? != 0 ]; then
	echo "Installing qrencode with source code failed"
	qrencode_status=1
else
        echo "qrencode:ok"
	qrencode_status=0
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
iptables -I INPUT -p tcp --dport 8388 -j ACCEPT  > /dev/null 2>&1
#restart Shadowsocks Server
ssserver -c /etc/shadowsocks.json -d stop > /dev/null 2>&1
ssserver -c /etc/shadowsocks.json -d start 
if [ $? != 0 ]; then
	echo  "ShadowServer start failed,please check"
	exit
else
	echo  "ShadowServer start Success"
fi
#Install Over
clear
echo "-------------------------------------------------------------------"
echo "-Server install Over,client info:[服务端安装完成，客户端信息如下:]-"
echo ""
echo "--------------------------------------------------------------------------------------------------------------------------------------------------------"
echo "- ClientDownloadUrl[客户端下载地址]:                                                                                                                   -"
echo "- https://github.com/shadowsocks/shadowsocks-windows/wiki/Shadowsocks-Windows-%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E                                     -"
echo "--------------------------------------------------------------------------------------------------------------------------------------------------------"
echo "- If client can't work,try install Microsoft .NET Framework 4.5[若客户端无法正常运行请安装 Microsoft .NET Framework 4.5]:                              -"
echo "- https://www.microsoft.com/zh-CN/download/details.aspx?id=30653                                                                                       -"
echo "--------------------------------------------------------------------------------------------------------------------------------------------------------"

if [ ${qrencode_status} != 1 ]; then
	echo "QR Code:"
	echo ""
	client_base64=`echo -n "aes-256-cfb:$client_password@$server_ip:8388"|base64`
	ss_encode_str="ss://$client_base64"
	echo -n "${ss_encode_str}"| qrencode -o - -t UTF8
fi
echo ""
echo "Server_IP[服务器IP]:$server_ip"
echo "Server_Port[服务器端口]:8388"
echo "Password[密码]:$client_password"
echo "encrypt_methmod[加密]:aes-256-cfb"
echo "proxy_port[代理端口]:1082"
