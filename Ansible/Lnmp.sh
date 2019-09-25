#!/usr/bin/env bash
systemctl stop firewalld
echo "firewalld stop" 
echo "shut SELinux"
sed -r '/^SELINUX/c\SELINUX=disabled' /etc/selinux/config
setenforce 0
if [ ! -d /etc/yum.repos.d/backup ];
then
	mkdir /etc/yum.repos.d/backup -p
fi
if ! ping -c2 www.baidu.com &>/dev/null
then
	echo "You can't get on the net"
	exit
fi
echo "Download 163 source ..."
echo "Download nginx Source package ..."
yum -y install wget
wget -O /etc/yum.repos.d/163.repo   http://mirrors.163.com/.help/CentOS7-Base-163.repo
yum repolist
if [ ! -f /etc/yum.repos.d/nginx.repo ];then
cat > /etc/yum.repos.d/nginx.repo <<EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
EOF
fi

rpm -qa |grep nginx  &> /dev/null
if [ ! $? -eq 0 ] ;then
	echo "dafew"
	yum -y install nginx
fi
sed -ri '/ *# *proxy *the *PHP/,/ *# *proxy_pass/ d' /etc/nginx/conf.d/default.conf
sed -ri '/ *#location/,/ *#\}/   s/( *)#/\1/' /etc/nginx/conf.d/default.conf
sed -ri s/" "*root" "*html\;/\\troot"\t"\\/usr\\/share\\/nginx\\/html\;/ /etc/nginx/conf.d/default.conf
sed -ri s/" "*index" "*index.html" "*index.htm\;/"\t\t"index" "index.php" "index.html" "index.htm\;/  /etc/nginx/conf.d/default.conf
sed -ri '/SCRIPT_FILENAME/c\\t\t fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name\;' /etc/nginx/conf.d/default.conf
sed -i '/ *location *~ * \/\\\.ht/,/ *}/ d' default.conf

systemctl start nginx


##################  安装PHP ########################
yum -y install php php-fpm php-mysql php-gd gd
echo "switch to the PHP terminal..."
systemctl start php-fpm
######################  安装Mysql #####################
yum -y install mariadb-server
systemctl start mariadb
systemctl enable mariadb
mysqladmin password '123456'
mysql -uroot -p123456 -e "grant all on *.* to root@'%' identified by '123456;"

cd /usr/share/nginx/html
 cat >index.php <<EOF
<?php
        phpinfo();
?>
EOF
