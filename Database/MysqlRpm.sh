#!/usr/bin/env bash
# Author: ZhouJian
# Mail: 18621048481@163.com
# Time: 2019-9-3
# Describe: CentOS 7 Install Mysql.rpm Script
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
EOT
echo -ne "\\033[m"

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

init_mysql() {
rpm -e mariadb-libs --nodeps
rm -rf /var/lib/mysql
rm -rf /etc/my.cnf
tar xvf /root/mysql-5.7.23-1.el7.x86_64.rpm-bundle.tar -C /usr/local/
cd /usr/local
rpm -ivh mysql-community-server-5.7.23-1.el7.x86_64.rpm mysql-community-client-5.7.23-1.el7.x86_64.rpm mysql-community-common-5.7.23-1.el7.x86_64.rpm mysql-community-libs-5.7.23-1.el7.x86_64.rpm 
rm -rf mysql-community-*
}

changepass() {
sed -i '/\[mysqld]/ a skip-grant-tables' /etc/my.cnf
systemctl restart mysqld
mysql <<EOF
        update mysql.user set authentication_string='' where user='root' and Host='localhost';
        flush privileges;
EOF
sed -i '/skip-grant/d' /etc/my.cnf
systemctl restart mysqld
yum -y install expect ntp
cat  > /etc/ntp.conf << EOF
restrict default nomodify
server 127.127.1.0
fudge 127.127.1.0 stratum 10
EOF
systemctl start ntpd &&  systemctl enable ntpd

expect <<-EOF
spawn  mysqladmin -uroot -p password "ZHOUjian.20"
        expect {
                "password" { send "\r"  }
}
        expect eof
EOF
systemctl restart mysqld
}

main() {
init_hostname
init_security
init_yumsource
init_mysql
changepass
}
main
