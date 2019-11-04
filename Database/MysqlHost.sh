#/usr/bin/bash env
# Author: ZhouJian
# Mail: 18621048481@163.com
# Time: 2019-9-3
# Describe: CentOS 7 Install Mysql.tar Script
#cd /root/.ssh/
#if [ ! -e id_rsa.pub ];then
#        ssh-keygen -t rsa -N '' -f id_rsa -q
#        yum -y install expect &>/dev/null
#fi
#/usr/bin/expect <<-EOF
#        spawn ssh-copy-id  192.168.25.133
#        expect {
#                "yes/no" { send "yes\r"; exp_continue }
#                "password:" { send "ZHOUjian.22\r" }
#}
#        expect eof
#EOF
#ssh root@192.168.25.133 '
#if [ -f /mysql.sh ];then
#      bash /mysqlhost/mysql.sh
#fi '
Deplay(){
rpm -e mariadb-libs --nodeps
setenforce 0
systemctl stop firewalld
systemctl enable firewalld
sed -i '/^SELINUX=/ s/enforcing/disabled' /etc/ssh/sshd_config
sed -i '/^GSSAPIAu/ s/yes/no/' /etc/ssh/sshd_config
sed -i '/^#UseDNS/ {s/^#//;s/yes/no}' /etc/ssh/sshd_config
yum -y install wget
# wget ftp://192.168.25.128/download_rpm/mysql-5.7.26-bin.tar.xz

id mysql > /dev/null
if [ $? -eq 0 ];then
	echo "mysql user exist"
else
	groupadd mysql
	useradd -M -s /sbin/nologin  mysql -g mysql
fi

if [ ! -d /usr/local/mysqld ];then
	tar xf mysql-5.7.26-bin.tar.xz -C /usr/local/
	chown  mysql.mysql /usr/local/mysqld/ -R
fi

echo "export PATH=$PATH:/usr/local/mysqld/mysql/bin" >> /etc/profile
source /etc/profile

cat > /etc/my.cnf <<EOF
[mysqld]
basedir = /usr/local/mysqld/mysql
datadir = /usr/local/mysqld/data
tmpdir = /usr/local/mysqld/tmp
socket = /usr/local/mysqld/tmp/mysql.sock
pid_file = /usr/local/mysqld/tmp/mysqld.pid
log_error = /usr/local/mysqld/log/mysql_error.log
slow_query_log_file = /usr/local/mysqld/log/slow_warn.log

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
sed -i '/skip-grant/d' /etc/my.cnf
mysqldctl restart
yum -y install expect ntp
cat  > /etc/ntp.conf << EOF
restrict default nomodify
server 127.127.1.0
fudge 127.127.1.0 stratum 10
EOF
systemctl start ntpd ; systemctl enable ntpd

expect <<-EOF
spawn  mysqladmin -uroot -p password "ZHOUjian.20"
        expect {
                "password" { send "\r"  }
}
        expect eof
EOF
mysqldctl restart
}

Deplay

mysql -uroot -pZHOUjian.20 -e "select uuid() as uuid" | awk -F"uuid" '{print $NF}' | tail -n1 > /tmp/uuid.txt

u=$(cat /tmp/uuid.txt)
sed -i "/auto/ a server-uuid=$u" /usr/local/mysqld/data/auto.cnf
sed -i '$d' /usr/local/mysqld/data/auto.cnf
mysqldctl restart

mysqldump  -uroot -pZHOUjian.20 --all-databases  > /tmp/all.sql

sed -i 's/# *StrictHostKeyChecking *ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config

cd /root/.ssh/
if [ ! -e id_rsa.pub ];then
        ssh-keygen -t rsa -N '' -f id_rsa -q
        yum -y install expect &>/dev/null
fi

/usr/bin/expect <<-EOF
        spawn ssh-copy-id  192.168.144.128
        expect {
                "yes/no" { send "yes\r"; exp_continue }
                "password:" { send "flying\r" }
}
        expect eof
EOF

scp /tmp/all.sql 192.168.144.128:/tmp
scp mysql-5.7.26-bin.tar.xz 192.168.144.128:

mysql -uroot -pZHOUjian.20  <<EOF
	grant replication slave on *.* to 'slave'@'192.168.144.%' identified by 'ZHOUjian.20';
EOF

if [ ! -d /back ];then
	mkdir /back
	chown  mysql.mysql /back
	chmod -R 775 /usr/local/mysqld/data
fi
sed -i '/default/ a log-bin=/back/master' /etc/my.cnf
sed -i '/default/ a server_id=133' /etc/my.cnf
sed -i '/default/ a gtid_mode=ON' /etc/my.cnf
sed -i '/default/ a enforce_gtid_consistency=true' /etc/my.cnf
mysqldctl restart

mysql -uroot -pZHOUjian.20 <<EOF
	grant all on bbs.* to phptest@'192.168.144.%' identified by 'ZHOUjian.20';
EOF

