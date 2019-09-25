#!/usr/bin/env bash
# *************************************************************************************************************
# Author: ZhouJian
# Mail: 18621048481@163.com
# Data: 2019-9-7
# Describe: CentOS 7 AutoInstall Elasticsearchn-7.2 Deploy Script

# ****************************Elasticsearch Deplay Script******************************************************
clear
ESIP=`ip addr | grep "inet" | grep -v "127.0.0.1" | grep -v "inet6" | awk -F/ '{print $1}' | awk '{print $2}' `

echo -e "\033[32m ############################################################################# \033[0m"
echo -e "\033[32m #                           Auto Install ELK.                              ## \033[0m"
echo -e "\033[32m #                           Press Ctrl + C to cancel                       ## \033[0m"
echo -e "\033[32m #                           Any key to continue                            ## \033[0m"
echo -e "\033[32m # Softwae:elasticsearch-7.2.0/logstash-7.2.0/filebeat-7.2.0/kibana-7.2.0   ## \033[0m"
echo -e "\033[32m ############################################################################# \033[0m"

Read_Input() {
echo -e "\033[32m Please Input You Kibana Pass Key IP: \033[0m"
read -p "Please Input You HOST Pass Key IP:[192.168.244.55]" KibanaIP
read -p "Please Input You HOST Pass Key IP: Password:" KibanaPass

echo -e "\033[32m Please Input You Filebeat Pass Key IP: \033[0m"
read -p "Please Input You HOST Pass Key IP:[192.168.244.56]" FilebeatIP
read -p "Please Input You HOST Pass Key IP: Password:" FilebeatPass
}

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
	fi
}

# *************************************************************************************************************
Init_Hostname() 
{
	hostnamectl set-hostname elk-1
	echo "$ESIP elk-1" >> /etc/hosts	
}


# *************************************************************************************************************
Init_SElinux() 
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

# **************************************************************************************************************
Create_UserLogFile() 
{
	groupadd elk
	useradd elk -g elk
	mkdir -pv /data/elk/{data,logs}
	chown -R elk:elk /data/
}
# **************************************************************************************************************

Unpackaged_Authorization() 
{
	yum -y install  ntpdate
	rpm -ivh  /root/InstallELKB-Shell/jdk-8u121-linux-x64.rpm
	tar xvf /root/InstallELKB-Shell/elasticsearch-7.2.0-linux-x86_64.tar.gz -C /opt/
	chown -R elk:elk /opt/elasticsearch-7.2.0/
	ntpdate -b ntp1.aliyun.com
}

# **************************************************************************************************************
Set_System_Parameter() 
{
cat >> /etc/security/limits.conf <<EOF
* soft nproc 2048
* hard nproc 4096
* soft nofile 65536
* hard nofile 131072
EOF

echo "vm.max_map_count = 262144" >> /etc/sysctl.conf && sysctl -p
cat >> /etc/profile <<EOF
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
EOF
	source /etc/profile

cat >> /opt/elasticsearch-7.2.0/config/elasticsearch.yml <<EOF
cluster.name: elk
node.name: node-1
bootstrap.memory_lock: false
path.data: /data/elk/data
path.logs: /data/elk/logs
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["elk-1"]
cluster.initial_master_nodes: ["node-1"]
EOF
	runuser -l elk -c '/bin/bash /opt/elasticsearch-7.2.0/bin/elasticsearch ' &> /opt/elasticsearch.log  &
}

Test_Service() 
{
	esport=`ss -antp |grep :::9200 | awk -F::: '{print $2}'`
	if [ $esport -eq 9200 ];then
		echo -e  "\033[32m Elasticsearch is OK... \033[0m "
	fi
}

# **********************PublicKeyKibana******************************************************************************


PublicKeyKibana() 
{
if [ ! -f /usr/bin/expect ];then
	yum -y install expect
fi
sed -i 's/# *StrictHostKeyChecking *ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
systemctl restart sshd

cd /root/.ssh/
ssh-keygen -t rsa -N '' -f id_rsa -q
if [ $? -eq 0 ];then
/usr/bin/expect <<-EOF
set timeout 10
spawn ssh-copy-id $KibanaIP
expect {
    "yes/no" { send "yes\r"; exp_continue }
    "password:" { send "$KibanaPass\r"}
}
expect eof
EOF
fi

}

# **********************Kibana Deploy Script********************************************************************
Install_Kibana() 
{
echo $ESIP > /root/InstallELKB-Shell/ESIP.txt
scp /root/InstallELKB-Shell/kibana-7.2.0-linux-x86_64.tar.gz $KibanaIP:
scp /root/InstallELKB-Shell/ESIP.txt $KibanaIP:
scp /root/InstallELKB-Shell/InstallKibana.sh $KibanaIP:
ssh root@$KibanaIP '
bash /root/InstallKibana.sh '
}



# *******************************************Filebeat Deploy Script***************************************************
PublicFilebeat() 
{
if [ ! -f /usr/bin/expect ];then
	yum -y install expect
fi
sed -i 's/# *StrictHostKeyChecking *ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
systemctl restart sshd
cd /root/.ssh/
rm -rf /root/.ssh/*
ssh-keygen -t rsa -N '' -f id_rsa -q
if [ $? -eq 0 ];then
/usr/bin/expect <<-EOF
set timeout 10
spawn ssh-copy-id $FilebeatIP
expect {
    "yes/no" { send "yes\r"; exp_continue }
    "password:" { send "$FilebeatPass\r"}
}
expect eof
EOF
fi
}

Install_Filebeat() 
{
	scp /root/InstallELKB-Shell/filebeat-7.2.0-x86_64.rpm  $FilebeatIP:
	scp /root/InstallELKB-Shell/InstallFilebeat.sh $FilebeatIP:
	ssh root@$FilebeatIP 'bash /root/InstallFilebeat.sh'
	scp /root/InstallELKB-Shell/filebeat.yml $FilebeatIP:/etc/filebeat/ 
	ssh root@$FilebeatIP 'systemctl restart filebeat && systemctl disable filebeat && rm -rf /root/InstallFilebeat.sh' 
}


# ********************************************Logstash******************************************************************
Install_logstash() 
{
	tar xvf /root/InstallELKB-Shell/logstash-7.2.0.tar.gz  -C /opt/
	cp /root/InstallELKB-Shell/nginx.yml  /opt/logstash-7.2.0/
	/opt/logstash-7.2.0/bin/logstash -f /opt/logstash-7.2.0/nginx.yml   &>/opt/logstash.log &	
}


ES-StartUp_SelfStart() 
{
cat >> /etc/init.d/elasticsearch.sh <<EOF
nohup  runuser -l elk -c '/bin/bash /opt/elasticsearch-7.2.0/bin/elasticsearch' &
nohup /opt/logstash-7.2.0/bin/logstash -f /opt/nginx.yml &
EOF
	echo "/etc/init.d/elasticsearch.sh"  >> /etc/rc.d/rc.local
	chmod +x /etc/init.d/elasticsearch.sh
	chmod +x /etc/rc.d/rc.local 
}

main() {
#######Elasticsearch#######
Read_Input
Init_Yumsource
Init_Hostname
Init_SElinux
Create_UserLogFile
Unpackaged_Authorization
Set_System_Parameter
Test_Service
#########Kibana###########
PublicKeyKibana
Install_Kibana

########Filebeat#########
PublicFilebeat
Install_Filebeat

ES-StartUp_SelfStart
Kibana-StartUp_SelfStart
#######Logstash#########
Install_logstash
}
main
