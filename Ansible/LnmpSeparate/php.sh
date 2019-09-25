yum -y install php php-fpm php-mysql php-gd gd
echo "switch to the PHP terminal..."
systemctl stop firewalld
setenforce 0
sed -r '/^SELINUX/c\SELINUX=disabled' /etc/selinux/config
if [ ! -d /nginx ];then
        mkdir /nginx
        cd /nginx
        cat >index.php <<EOF
<?php
        phpinfo();
?>
EOF
fi

if [ $? -eq 0 ];then
        echo "start php-fpm module ....."
        sed -ri 's/listen *= *127.0.0.1\:9000/listen = 192.168.122.49\:9000/'  /etc/php-fpm.d/www.conf
        sed -ri 's/listen\.allowed\_clients *= *127.0.0.1/listen.allowed_clients = 192.168.122.183/' /etc/php-fpm.d/www.conf
else
        echo "you possible package conflicts ..."
fi
yum -y install elinks
systemctl restart php-fpm
elinks --dump 192.168.122.183/index.php

