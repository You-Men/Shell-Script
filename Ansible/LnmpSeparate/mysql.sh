#!/usr/bin/env bash
id mysql > /dev/null
if [ $? -eq 0 ];then
	echo "mysql user exist"
else
	groupadd mysql
	useradd -M -s /sbin/nologin -g  mysql mysql
fi

if [ ! -d /usr/local/mysqld ];then
	tar xf mysql-5.7.26-bin.tar.xz -C /usr/local/
	chown -R mysql.mysql /usr/local/mysqld/
fi

echo "export PATH=$PATH:/usr/local/mysqld/mysql/bin" >> /etc/profile
source /etc/profile

cat >/etc/my.cnf <<EOF
[mysqld]
basedir = /usr/local/mysqld/mysql
datadir = /usr/local/mysqld/data
tmpdir = /usr/local/mysqld/tmp
socket = /usr/local/mysqld/tmp/mysql.sock
pid_file = /usr/local/mysqld/tmp/mysqld.pid
log_error = /usr/local/mysqld/log/mysql_error.log
slow_query_log_file = /usr/local/mysqld/log/slow_warn.log  

server_id = 10
user = mysql
port = 3306
bind-address = 0.0.0.0      
character-set-server = utf8
default_storage_engine = InnoDB
EOF

ln -s /usr/local/mysqld/mysql/support-files/mysql.server /usr/bin/mysqldctl
mysqldctl start
ln -s /usr/local/mysqld/tmp/mysql.sock /tmp/mysql.sock
mysqldctl restart

sed -i '/\[mysqld]/ a skip-grant-tables' /etc/my.cnf
mysqldctl restart 
mysql <<EOF
        update mysql.user set authentication_string='' where user='root' and Host='localhost';
        flush privileges;
EOF

sed -i '/skip/ s/^/#/' /etc/my.cnf
#mysql -uroot -e "set password=password('ZHOUjian.22')"
#sed -i '/skip/ s/^/#/' /etc/my.cnf
mysqladmin -uroot -p password "ZHOUjian.22"
mysqld restart
###################### 修改密码并授权mysqlfrom ##################
sed -i '$a[mysql]'  /etc/my.cnf
sed -i '$ahost=localhost' /etc/my.cnf
sed -i '$auser=root'  /etc/my.cnf
sed -i '$apassword=ZHOUjian.22' /etc/my.cnf
mysqldctl restart
mysql -uroot <<EOF
	grant all on bbs.* to phptest@'192.168.122.%' identified by 'ZHOUjian.22';
	flush privileges;
EOF

