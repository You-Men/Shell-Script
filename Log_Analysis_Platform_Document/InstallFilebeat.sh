#!/usr/bin/env bash # *************************************************************
# Author: ZhouJian
# Mail: 18621048481@163.com
# Data: 2019-9-7
# Describe: CentOS 7 Deploy Filebeat7.2 Script

# *************************************************************

Init_Yumsource() 
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
	yum -y install ntpdate
	ntpdate -b ntp1.aliyun.com
	fi
}

Init_SElinux() 
{
	echo "关闭防火墙"
	systemctl stop firewalld
	systemctl disable firewalld
	echo "关闭selinux"
	setenforce 0
	sed -i '/^SELINUX=/ s/enforcing/disabled/'  /etc/selinux/config
	echo "解决sshd远程连接慢的问题"
	sed -i '/^GSSAPIAu/ s/yes/no/' /etc/ssh/sshd_config
	sed -i '/^#UseDNS/ {s/^#//;s/yes/no/}' /etc/ssh/sshd_config
	systemctl enable sshd crond &> /dev/null
}


Install_Filebeat() 
{
	yum -y install ntpdate
	ntpdate -b ntp1.aliyun.com
	rpm -ivh /root/filebeat-7.2.0-x86_64.rpm
	rm -rf /root/filebeat-7.2.0-x86_64.rpm
}

Init_Yumsource
Init_SElinux
Install_Filebeat
