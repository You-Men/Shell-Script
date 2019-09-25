#!/usr/bin/bash
file='Python-3.6.5.tar.xz'
dir=${file%.tar*}
path=/usr/local/src/$dir
if ! ping -c2 www.python.org &>/dev/null
then
	exit
fi

yum -y install gcc gcc-c++ zlib-devel bzip2-devel openssl-devel  sqlite-devel readline-devel wget
wget https://www.python.org/ftp/python/3.6.5/$file
if [ ! -e $file ];then
	wget https://www.python.org/ftp/python/3.6.5/Python-3.6.5.tar.xz --no-check-certificate	
fi

tar xf $file -C /usr/local/src/
cd $path
sed -ri '/^#SSL/,/lcrypto$/ s/^#//;/#readline/ s/^#//' Modules/Setup.dist
./configure --enable-shared && make && make install

if [ $? -eq 0 ];then
	echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib" > /etc/profile.d/python3_lib.sh
	echo "/usr/local/lib" >  /etc/ld.so.conf.d/python3.conf
	ldconfig
fi


