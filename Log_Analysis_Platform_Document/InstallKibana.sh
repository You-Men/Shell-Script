#!/usr/bin/env bash
# ***************************************************************************************************
# Author: ZhouJian
# MaiBox: 18621048481@163.com
# Data: 2019-9-7
# Describe: CentOS 7 Deploy Kibana Script

elastip=$(cat /root/ESIP.txt )
if [ ! -d /opt/kibana-7.2.0-linux-x86_64 ];then
	tar xvf /root/kibana-7.2.0-linux-x86_64.tar.gz -C /opt/
fi
# ***************************************************************************************************


init_yumsource() 
{
if ! ping -c2 www.baidu.com &>/dev/null
then
        echo "您无法上外网，不能配置yum源"
        exit
fi
echo "配置yum源"
if [ ! -d /etc/yum.repos.d/backup ];then
mkdir /etc/yum.repos.d/backup
	mv /etc/yum.repos.d/* /etc/yum.repos.d/backup 2>/dev/null
	curl -o /etc/yum.repos.d/163.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo &>/dev/null
	curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo &>/dev/null
	yum -y install  ntpdate
    ntpdate -b ntp1.aliyun.com
fi
}

# ***************************************************************************************************
init_SElinux() 
{
	echo "关闭防火墙"
	systemctl stop firewalld
	systemctl disable firewalld
	echo "关闭selinux"
	setenforce 0
	sed -ri '/^SELINUX=/ s/enforcing/disabled/'  /etc/selinux/config
	echo "解决sshd远程连接慢的问题"
	sed -ri '/^GSSAPIAu/ s/yes/no/' /etc/ssh/sshd_config
	sed -ri '/^#UseDNS/ {s/^#//;s/yes/no/}' /etc/ssh/sshd_config
	systemctl enable sshd crond &> /dev/null
}

# ***************************************************************************************************
SetKibanaParameter() 
{
cat >> /opt/kibana-7.2.0-linux-x86_64/config/kibana.yml <<EOF
server.host: "0.0.0.0"
server.port: 5601
elasticsearch.hosts: ["http://$elastip:9200"]
EOF
}

# ***************************************************************************************************
StartKibana() 
{
	/opt/kibana-7.2.0-linux-x86_64/bin/kibana --allow-root &>/opt/kibana.log &
}

Test_Service() 
{
	KibanaPort=` ss -antp | grep 5601 | awk '{print $4}' | awk -F*: '{print $NF}'`
    if [ $KibanaPort -eq 5601 ];then
    	echo -e  "\033[32m Kibana is OK... \033[0m "
    fi
}

DeleteUselessFiles() 
{
	rm -rf /root/kibana-7.2.0-linux-x86_64.tar.gz
	rm -rf /root/InstallKibana.sh
	rm -rf /root/ESIP.txt
}

Kibana-StartUp_SelfStart() 
{
        echo "nohup /opt/kibana-7.2.0-linux-x86_64/bin/kibana --allow-root  &" >> /etc/init.d/kibana.sh
        echo "/bin/bash /etc/init.d/kibana.sh" >> /etc/rc.local
        chmod +x /etc/init.d/kibana.sh
        chmod +x /etc/rc.local
}


init_SElinux
SetKibanaParameter
StartKibana
Test_Service
DeleteUselessFiles
Kibana-StartUp_SelfStart
