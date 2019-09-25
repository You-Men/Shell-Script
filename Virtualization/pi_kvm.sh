#!/bin/bash
#by zkl
vm_path1=/var/lib/libvirt/images/
vm_path2=/etc/libvirt/qemu/
read_vm() {
	read -p "输入虚拟机名字: " newname
	read -p "输入虚拟机内存大小(G): " newmem
	read -p "输入虚拟机cpu个数: " newcpu
	read -p "输入创建虚拟机个数: " num
	newmem=`echo $newmem |awk "{print $newmem * 1000000}"`
}

create_vm() {
	if ! [ -f ${vm_path1}original.qcow2 ];then
		cp -r ./original.qcow2 ${vm_path1}original.qcow2
	fi
	qemu-img create -f qcow2 -b ${vm_path1}original.qcow2 ${vm_path1}${newname}.qcow2
	cp ./original.xml ${vm_path2}${newname}.xml
	newuuid=`uuidgen`
	newmac=`uuidgen |cut -c 1-6 |sed -r 's/(..)/\1:/g' |sed 's/.$//'`
	sed -ri "s#vm_name#${newname}#;s#vm_uuid#${newuuid}#;s#vm_mem#${newmem}#;s#vm_cpu#${newcpu}#;s#vm_mac#${newmac}#;s#vm_path#${vm_path1}${newname}.qcow2#" ${vm_path2}${newname}.xml
	virsh define ${vm_path2}${newname}.xml
	virsh autostart $newname 
}

while :
do
echo "***********
1、创建虚拟机
2、删除虚拟机
q、退出
************"
read -p "输入操作: " option
case $option in
1)
	read_vm
	if virsh list --all |egrep "\<$newname\>" &>/dev/null;then
		echo "虚拟机名字重复!"
		continue
	fi
	if [ $num -eq 1 ];then
		create_vm
	elif [ $num -gt 1 ];then
		for((i=1;i<=$num;i++))
		do
			a_name=${newname}
			newname=${newname}$i
			create_vm
			newname=$a_name
		done
	fi
	;;
2)
	read -p "输入名字: " delete_name
	if virsh list --all |egrep "\<$delete_name\>" &>/dev/null;then
		virsh destroy $delete_name &>/dev/null
		virsh undefine $delete_name
		rm -rf  ${vm_path1}${delete_name}.qcow2
	else
		echo "没有这个虚拟机"
	fi
	;;
q)
	break;;
*)
	echo "输入错误,重新输入"
esac
done
