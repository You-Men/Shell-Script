#!/usr/bin/env bash
# *****************
# Author: ZhouJian
# Time: 2019-9-3
# Describe: CentOS 7 Initialization Script

# *************************************************************
init_hostname() {
while read -p "请输入您想设定的主机名：" name
do
	if [ -z "$name" ];then
		echo "您没有输入内容，请重新输入"
		continue
	fi
	read -p "您确认使用该主机名吗？[y/n]: " var

	if [ $var == 'y' -o $var == 'yes' ];then
		hostnamectl set-hostname $name
		break
	fi
done
}


# ************************************************************
init_service() {
# Close Filewalld
echo "关闭防火墙"
systemctl stop firewalld
systemctl disable firewalld

# Close SELinux
echo "关闭selinux"
setenforce 0
sed -ri '/^SELINUX=/ s/enforcing/disabled/'  /etc/selinux/config

echo "解决sshd远程连接慢的问题"
sed -ri '/^GSSAPIAu/ s/yes/no/' /etc/ssh/sshd_config
sed -ri '/^#UseDNS/ {s/^#//;s/yes/no/}' /etc/ssh/sshd_config

systemctl enable sshd crond &> /dev/null
}


# ***********************************************************
init_yumsource() {
echo "配置yum源"
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
}

# ***********************************************************
init_install_package() {
echo "安装系统需要的软件，请稍等~ ~ ~"
yum -y install lsof tree wget bash-completion vim lftp bind-utils  &>/dev/null
yum -y install atop htop nethogs net-tools psmisc ntpdate nslookup &>/dev/null
}

# **********************************************************
init_dns() {
	timedatectl set-timezone Asia/Shanghai
	echo "nameserver 114.114.114.114" > /etc/resolv.conf	
	echo "nameserver 8.8.8.8" >> /etc/resolv.conf
	chattr +i /etc/resolv.conf
}

# **********************************************************

set_kernel_parameter() {
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
}

# **************************************************
set_system_limit() {
cat >> /etc/security/limits.conf <<EOF
* soft nproc 65530
* hard nproc 65530
* soft nofile 65530
* hard nofile 65530
EOF

cat >> /etc/profile <<EOF
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
EOF
source /etc/profile
}


init_hostname
init_service
init_source
init_install_package
init_dns
init_kernel-parameter
init_system_limit
