#!/usr/bin/env bash
# Author: ZhouJian
# Mail: 18621048481@163.com
# Time: 2019-9-3
# Describe: CentOS 7 Initialization Script
clear
echo -ne "\\033[0;33m"
cat<<EOT
                                  _oo0oo_
                                 088888880
                                 88" . "88
                                 (| -_- |)
                                  0\\ = /0
                               ___/'---'\\___
                             .' \\\\\\\\|     |// '.
                            / \\\\\\\\|||  :  |||// \\\\
                           /_ ||||| -:- |||||- \\\\
                          |   | \\\\\\\\\\\\  -  /// |   |
                          | \\_|  ''\\---/''  |_/ |
                          \\  .-\\__  '-'  __/-.  /
                        ___'. .'  /--.--\\  '. .'___
                     ."" '<  '.___\\_<|>_/___.' >'  "".
                    | | : '-  \\'.;'\\ _ /';.'/ - ' : | |
                    \\  \\ '_.   \\_ __\\ /__ _/   .-' /  /
                ====='-.____'.___ \\_____/___.-'____.-'=====
                                  '=---='


              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                建议系统                    CentOS7
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
             PS：请尽量使用纯净的CentOS7系统，我们会在服务器安装
    [python3.6、Node、Openresty、MySQL57、Redis3、Dnsmasq、Docker、RabbitMQ]
EOT
echo -ne "\\033[m"

init_hostname() {
while read -p "请输入您想设定的主机名：" name
do
	if [ -z "$name" ];then
		echo -e "\033[31m 您没有输入内容，请重新输入 \033[0m"
		continue
	fi
	read -p "您确认使用该主机名吗？[y/n]: " var

	if [ $var == 'y' -o $var == 'yes' ];then
		hostnamectl set-hostname $name
		break
	fi
done
}


init_security() {
systemctl stop firewalld
systemctl disable firewalld &>/dev/null
setenforce 0
sed -i '/^SELINUX=/ s/enforcing/disabled/'  /etc/selinux/config
sed -i '/^GSSAPIAu/ s/yes/no/' /etc/ssh/sshd_config
sed -i '/^#UseDNS/ {s/^#//;s/yes/no/}' /etc/ssh/sshd_config
systemctl enable sshd crond &> /dev/null
echo -e "\033[32m [安全配置] ==> OK \033[0m"
}

init_yumsource() {
if [ ! -d /etc/yum.repos.d/backup ];then
	mkdir /etc/yum.repos.d/backup
fi
mv /etc/yum.repos.d/* /etc/yum.repos.d/backup 2>/dev/null

if ! ping -c2 www.baidu.com &>/dev/null	
then
	echo "您无法上外网，不能配置yum源"
	exit	
fi
	curl -o /etc/yum.repos.d/163.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo &>/dev/null 
	curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo &>/dev/null
timedatectl set-timezone Asia/Shanghai
echo "nameserver 114.114.114.114" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
chattr +i /etc/resolv.conf

echo -e "\033[32m [YUM　Source] ==> OK \033[0m"
}

init_install_package() {
echo -e "\033[32m 安装系统需要的软件，请稍等~ ~ ~ \033[0m"
yum -y install lsof tree wget vim  bash-completion lftp bind-utils  &>/dev/null 
yum -y install atop htop nethogs net-tools libcurl-devel libxml2-devel openssl-devel unzip  psmisc ntpdate nslookup &>/dev/null 
echo -e "\033[32m [安装常用工具] ==> OK \033[0m"
}

init_kernel_parameter() {
cat > /etc/sysctl.conf <<EOF
fs.file-max = 999999
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
vm.swappiness = 10
EOF
sysctl -p /etc/sysctl.conf >/dev/null 2>&1
echo -e "\033[32m [内核 优化] ==> OK \033[0m"
}

# **************************************************
init_system_limit() {
cat >> /etc/security/limits.conf <<EOF
* soft nproc 65530
* hard nproc 65530
* soft nofile 65530
* hard nofile 65530
EOF
ulimit -n 65535
ulimit -u 20480
echo -e "\033[32m [ulimits 配置] ==> OK \033[0m"
cat >> /etc/profile <<EOF
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
EOF
source /etc/profile
}

main() {
init_hostname
init_security
init_yumsource
init_install_package
init_kernel_parameter
init_system_limit
}
#main
