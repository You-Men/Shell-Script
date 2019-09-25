#!/usr/bin/env bash
#*****************************************************************
#Author:flying.com
#FileName: MassTransferOfPublicKey.sh
#FileAddress:	
read -p "please input you pass key IP:[192.168.25]" ip
read -p "please input you pass keyIP password:" youpasswd
if [ ! -f /usr/bin/expect ];then
	yum -y install expect
fi
sed -i 's/# *StrictHostKeyChecking *ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
systemctl restart sshd

if [ ! -f /root/.ssh/id_rsa.pub ];then
	cd /root/.ssh/
	ssh-keygen -t rsa -N '' -f id_rsa -q
fi

for i in `seq 2 254`
do 
	{
	ping -c1 $ip.$i &> /dev/null
	if [ $? -eq 0 ];then
		echo "$ip.$i" >> ip.txt
		/usr/bin/expect <<-EOF
		set timeout 10
		spawn ssh-copy-id $ip.$i
		expect {
			"yes/no" { send "yes\r"; exp_continue }
			"password:" { send "$youpasswd\r"}
		}
		expect eof
		EOF
	fi
	}&
done
wait
