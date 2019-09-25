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
ng=nginx-1.15.12.tar.gz
yum -y install wget
if [ ! -e $ng ];then
	wget http://nginx.org/download/nginx-1.15.12.tar.gz &>/dev/null
fi
if [ -e nginx-1.15.12.tar.gz ];
then
	echo "Download nginx finish"
else
	echo "There is something wrong with your network"
fi
if [ ! -e /usr/local/src/nginx-1.15.12 ];then
	tar -xf nginx-1.15.12.tar.gz -C /usr/local/src/ 
	echo "in the decompression..."
fi
echo "The complier is about to be installed , Wait five minutes ......"
yum -y install zlib-devel openssl-devel gcc gcc-c++ pcre-devel
	useradd -s /sbin/nologin -M  www
if [ ! -d /usr/local/nginx ];then
cd /usr/local/src/nginx-1.15.12/ 
   ./configure --user=www --group=www --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-pcre
 make&&make install

echo "/usr/local/nginx/sbin/nginx"  >> /etc/rc.d/rc.local
chmod a+x /etc/rc.d/rc.local
fi
/usr/local/nginx/sbin/nginx -s stop 
/usr/local/nginx/sbin/nginx 
echo "nginx starting ,please walt ..."
port1=$(ss -antp |grep nginx |awk '{print $4}'|awk -F: '{print $2}')
if [ "$port1" -eq "80" ];then
	echo "nginx Has started"
else
	echo "nginx server abnormal"
fi

sed -ri '1c user  www\;' /usr/local/nginx/conf/nginx.conf
sed -ri '/ *# *proxy *the *PHP/,/ *# *proxy_pass/ d' /usr/local/nginx/conf/nginx.conf
sed -ri '/ *#location/,/ *#\}/   s/( *)#/\1/' /usr/local/nginx/conf/nginx.conf

sed -ri s/" "*index" "*index.html" "*index.htm\;/"\t\t"index" "index.php" "index.html" "index.htm\;/ /usr/local/nginx/conf/nginx.conf
sed -ri s/" "*root" "*html\;/\\troot"\t"\\/nginx\;/  /usr/local/nginx/conf/nginx.conf
sed -ri '/SCRIPT_FILENAME/c\\t\t fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name\;' /usr/local/nginx/conf/nginx.conf
sed -ri '/fastcgi_pass/c\fastcgi_pass\t192.168.122.49:9000\;' /usr/local/nginx/conf/nginx.conf
sed -i '/ *location *~ * \/\\\.ht/,/ *}/ d' /usr/local/nginx/conf/nginx.conf
/usr/local/nginx/sbin/nginx -s stop
/usr/local/nginx/sbin/nginx
#############################安装php###########################
echo "Download the php-related package ....."

yunpassword=flying
if [ ! -f /usr/bin/expect ];then
        yum -y install expect
fi

sed -i 's/# *StrictHostKeyChecking *ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
systemctl restart sshd

if [ ! -f /root/.ssh/id_rsa.pub ];then
        cd /root/.ssh/
        ssh-keygen -t rsa -N '' -f id_rsa -q
fi

/usr/bin/expect <<-EOF
        spawn ssh-copy-id 192.168.122.49
        expect {
                "password:" { send "$yunpassword\r" }
        }
        expect eof
EOF


ssh root@192.168.122.49 '
if [ ! -d /php ];then
	mkdir /php
fi
'
scp php.sh 192.168.122.49:/php/
ssh root@192.168.122.49 '
	sh /php/php.sh
'

###########################install Mysql #####################
echo "Download the mysql-related package ...."
/usr/bin/expect <<-EOF
	spawn ssh-copy-id 192.168.122.180
	expect {
		"password:" { send "$yunpassword\r" }
	}
	expect eof
EOF

ssh root@192.168.122.180 '
if [ ! -d /mysql ];then
	mkdir /mysql
fi
'

scp ./mysql-5.7.26-bin.tar.xz ./mysql.sh  192.168.122.180:/mysql
ssh root@192.168.122.180 '
	sh /mysql/mysql.sh
'

