#### ELKB部署文档

##### 环境要求：

​	*CentOS7

​	*Javaa 1.8

​	软件包及版本

| IP            | hostname | 软件                    | 内存要求 |
| ------------- | -------- | ----------------------- | -------- |
| 192.168.122.3 | elk-1    | Elasticsearch、Logstash | 2G及以上 |
| 192.168.122.4 | Kibana   | Kibana                  | 1G及以上 |
| 192.168.122.5 | Filebeat | Filebeat                | 1G及以上 |

​		注意事项：  

​			1.一定要对时，时间校正，不然日志出不来；

​			2.java包最好用openjdk；

​			3.启动Elasticsearch必须切换成所创建的ELK用户启动，不然ES出于安全目的，会启动报错；

​			4.日志从Filebeat到Logstash再到ES检索到Kibana的读取速度取决于机器配置，注意用

​					cat  日志文件*  |  wc  -l   统计日志数量，然后到Elasticsearch去看总数量，确保日志都过来了在进行分析；



##### Elasticsearch安装

###### 	1.初始化：

```
curl -o /etc/yum.repos.d/163.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo &>/dev/null
curl  -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo 
	yum -y install ntpdate
	ntpdate -b  ntp1.aliyun.com
```



###### 	2.设置Hostname解析

```
		hostnamectl set-hostname elk-1
		## 修改/etc/hosts 增加如下内容
		192.168.122.3     elk-1
```

###### 	3.java安装

```
		# 安装java 1.8
		yum -y install java-1.8.0-openjdk.x86_64
```

###### 	4.关闭防火墙，SeLinux

```
		setenforce 0
		sed -i '/^SELINUX=/ s/enforcing/disabled/'  /etc/selinux/config
		systemctl stop firewalld
		systemctl disable firewalld
		sed -i '/^GSSAPIAu/ s/yes/no/' /etc/ssh/sshd_config
		sed -i '/^#UseDNS/ {s/^#//;s/yes/no/}' /etc/ssh/sshd_config
```

###### 	5.创建用户和组

```
		# create  user elk
		groupadd  elk
		useradd  elk  -g  elk
```

###### 	6.创建数据及日志文件并授权

```
		mkdir  -pv  /data/elk/{data,logs}
		chown  -R  elk:elk  /data/elk/
```

###### 	7.软件包解压、授权

```
		× 上传软件包
			通过scp 或者FTP方式上传到/opt下
		× 解压软件包到/opt目录
		tar xvf elasticsearch-7.2.0-linux-x86_64.tar.gz -C  /opt/
		× 授权
		chown  -R  elk:elk   软件包名
```

###### 	8.elk-1配置文件

```
		# 集群名
		cluster.name:  elk
		# 节点名
		node.name: node-1
		# 存储数据
		path.data:  /data/elk/data
		# 存放日志
		path.logs:  /data/elk/logs
		# 锁内存，尽量不使用交换内存
		bootstrap.memory_locak:  false
		# 网络地址
		network.host: 0.0.0.0
		http.port: 9200
		# 发现集群hosts
		discovery.sead_hosts: ["elk-1"]
		# 设置集群master节点
		cluster.inital_master_nodes: ["node-1"]
```

###### 	9.修改/etc/security/limits.conf

```
		# *号不是注释
		* soft nofile 65536
		* hard nofile 131072
		* soft nproc 2048
		* hard nproc 4096
```

###### 	10.修改/etc/sysctl.conf

```
		echo "vm.max_map_count=262144" >> /etc/sysctl.conf
		sysctl -p
```

###### 	11.ES启动

```
		nohup runuser -l elk -c '/bin/bash /opt/elasticsearch-7.2.0/bin/elasticsearch' &
```

###### 	12.检查集群健康状态

```
		curl -XGET 'elk-1:9200/_cluster/health?pretty'
```



##### Kibana安装使用

###### 	1.解压Kibana安装包

```
		tar xvf kibana-7.2.0-linux-x86_64.tar.gz  -C /opt/
```

###### 	2.修改Kibana配置文件

```
		vim /opt/kibana-7.2.0-linux-x86_64/config/kibana.yml
			server.port:  5601   # Port
			server.host:  0.0.0.0   # 访问限制
			elasticsearch.hosts: ["http://ESHostIP:9200"]
```

###### 	3.启动命令

```
		/opt/kibana-7.2.0-linux-x86_64/bin/kibana --allow-root
		nohup  /opt/kibana-7.2.0-linux-x86_64/bin/kibana --allow-root  &  放入后台使用
		tailf  nohup.out   # 实时查看服务运行状态
```



##### Filebeat 安装使用

###### 	1.下载安装

###### 	2.修改配置文件(修改/etc/filebeat/filebeat.yml)

```
		filebeat.inputs:
		- type: log
		  enabled: true
		  paths:
		    - /var/log/*.log		# 抓取文件日志路径
```

```
		# output.elasticsearch:
		#  hosts: ["ESHostIP:9200"]		# 输出到ES
```





##### Filebeat到Lostash

###### 	Filebeat配置 

​		（vim  /etc/filebeat/filebeat.yml）	shift  +  ：    输入set nu   显示行号

```
			24:   enabled:  true				更改为true以启用输入配置
			28:   - /var/log/*.log              替换为要抓取的日志文件路径
			73：  reload.enabled:  true			启动Filebeat模块
			148： output.elasticsearch:   	    加上注释；
			150:  hosts: ["localhost:9200"]      加上注释；
			158： output.logstash:				去掉注释；
			160： hosts: ["localhost:5044"]		去掉注释，并修改localhost为logstash机器IP及对应端口号；
```

###### 	测试配置文件并启动：

```
			filebeat  test  config  -e
			systemctl  start filebeat
			systemctl  enable filebeat
```

​			

##### Logstash 安装使用

###### 	1.解压安装

​		上传包

​		tar xvf logstash-7.2.0.tar.gz -C /opt/

###### 	2.启动

```
	/opt/logstash-7.2.0/bin/logstash -f /opt/配置文件名.yml
	## 后台运行
	nohup  /opt/logstash-7.2.0/bin/logstash -f /opt/配置文件名.yml  &
```



##### Logstash到Elasticsearch

​	主要看配置文件，配置文件对了，直接按照上面命令启动就可以了；

```
# Sample Logstash configuration for creating a simple
# Beats -> Logstash -> Elasticsearch pipeline.

input {
  beats {
    port => 5044
  }
}

filter {
        grok {
                match => {
               "message" => " %{DATA:log_date} %{TIME:log_localtime} %{JAVAFILE:name_file} %{WORD:workd}\[%{WORD:ls}\]\: %{DATA:log_date2} %{TIME:log_localtime2} %{WORD:year_tmp}\: %{WORD:name_2}\: %{WORD:} %{WORD:}\, %{JAVAFILE:}\: %{JAVAFILE:app_id}\, %{WORD}\: %{IP:ip}\, %{WORD:}\: %{INT}\, %{WORD}\: %{USERNAME:device_id}"
                }
        }
}

output {
   elasticsearch {
      hosts => ["http://ElasticsearchHostIP:9200"]
      index => "nginx_log-%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
   }
}
```

