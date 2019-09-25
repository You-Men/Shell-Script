#!/usr/bin/bash
version="nginx-1.12.2.tar.gz"
user="nginx"
nginx=${version%.tar*}
path=/usr/local/src/$nginx
echo $path
if ! ping -c2 www.baidu.com &>/dev/null
then
	echo "网络不通，无法安装"
	exit
fi

yum install -y gcc gcc-c++ openssl-devel pcre-devel make zlib-devel wget psmisc
if [ ! -e $version ];then
	wget http://nginx.org/download/$version
fi
if ! id $user &>/dev/null
then
	useradd $user -M -s /sbin/nologin
fi

if [ ! -d /var/tmp/nginx ];then
	mkdir -p /var/tmp/nginx/{client,proxy,fastcgi,uwsgi,scgi}
fi
tar xf $version -C /usr/local/src
cd $path
./configure \
--prefix=/usr/local/nginx \
--user=nginx \
--group=nginx \
--with-http_ssl_module \
--with-http_flv_module \
--with-http_stub_status_module \
--with-http_sub_module \
--with-http_gzip_static_module \
--with-http_auth_request_module \
--with-http_random_index_module \
--with-http_realip_module \
--http-client-body-temp-path=/var/tmp/nginx/client \
--http-proxy-temp-path=/var/tmp/nginx/proxy \
--http-fastcgi-temp-path=/var/tmp/nginx/fastcgi \
--http-uwsgi-temp-path=/var/tmp/nginx/uwsgi \
--http-scgi-temp-path=/var/tmp/nginx/scgi \
--with-pcre \
--with-file-aio \
--with-http_secure_link_module && make && make install
if [ $? -ne 0 ];then
	echo "nginx未安装成功"
	exit
fi

killall nginx
/usr/local/nginx/sbin/nginx
#echo "/usr/local/nginx/sbin/nginx" >> /etc/rc.local
#chmod +x /etc/rc.local
#systemctl start rc-local
#systemctl enable rc-local
ss -antp |grep nginx
