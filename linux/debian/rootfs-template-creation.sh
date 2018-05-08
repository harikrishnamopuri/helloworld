#!/bin/bash
#set -x
#
#This script create rootfs template from debian 8.9 iso file.                   
#
#############################################################
#Prerequisities:
#
#  1.10GB space is required for this process under WORKSPACE
#  2.Create a rootfs in your http server 
#  3.Download ${ISOFILE}.iso file and keep in \
#    rootfs folder in http server. 
#  4.Copy IPI provided post-installation.sh and rootfsconfig \
#    packages.txt files in rootfs folder in http-server. 
#  5.**Edit config file according to your requirements.**
#
##############################################################
#Parameters:
#  WORKSPACE : directory to perform all operations ex: /tmp
#  PATH      : Location of preseed.cfg,pos-installation.sh \
#              packages.txt 
#              Ex: /home/rootfs or http://<servername>/rootfs/'
##############################################################
#Usage:
#bash rootfs-template-creation.sh WORKSPACE FILE_PATH
#
#Ex:
#bash rootfs-template-creation.sh /tmp 'http://<servername>/rootfs/'
#
################SCRIPT BEGIN##################################
exec > >(tee -i /var/log/rootfs-template-creation.log)
echo "To chekc logs run below command" 
echo "Logs: tail -f /var/log/rootfs-template-creation.log" 
START=$(date +%s.%N) 
#
#
echo ""
echo "Checking for local path or Http server path .." 
#
if [ $# -lt 2 ]; then
cat  << EOF 

INFO: No arguments supplied

USAGE: bash rootfs-template-creation.sh WORKSPACE FILE_PATH 
			( or )
       bash rootfs-template-creation.sh /tmp 'http://<server>/rootfs/'
EOF
exit 1 
else
  export WORKSPACE=${1}
  export FILE_PATH=${2}
fi

echo "${FILE_PATH}" | grep "http.*"
if [ $? -eq 0 ]; then
echo "using httpserver path ${FILE_PATH}"
COPY_METHOD="use_wget"
else
echo "using local path ${FILE_PATH}"
COPY_METHOD="use_cp"
fi

use_cp () {
cp -rpf ${1}  . 
}

use_wget () {
wget -q ${1}  
}

#
#Create a tempory directories under WORKSPACE and download prequisities 
#files
#
rm -rf ${WORKSPACE}/logs/
mkdir -p ${WORKSPACE}/logs/
export WORKSPACE=${WORKSPACE}/logs
cd ${WORKSPACE}
rm -rf iso loopdir isofiles workspace
mkdir -p iso loopdir isofiles workspace 

cd ${WORKSPACE}
${COPY_METHOD}  ${FILE_PATH}/rootfsconfig
if [ $? -ne 0 ]; then
echo "ERROR: rootfsconfig not found in httpserver"
echo "INFO: rootfsconfig  Downloading failed "
exit 1
else
source ${WORKSPACE}/rootfsconfig
fi
cd ${WORKSPACE}

echo ""
echo "Downloading ISO installer file ..." 
cd ${WORKSPACE}
cd iso
${COPY_METHOD}  ${FILE_PATH}/${ISOFILE}.iso
if [ $? -ne 0 ]; then
echo "ERROR: ${ISOFILE}.iso not found in httpserver" 
echo "INFO: ${ISOFILE}.iso  Downloading failed "
exit 1
fi
echo "Done"
echo ""
cd ${WORKSPACE}

#
echo "Mount installer ISO and extract files..." 
#
mount -o loop iso/${ISOFILE}.iso loopdir  
if [ $? -ne 0 ]; then
echo "ERROR: Mounting of iso file failed "
exit 1
fi
rsync  -a -H --exclude=TRANS.TBL loopdir/ isofiles/ 
if [ $? -ne 0 ]; then
echo "ERROR: rsync of iso file failed "
exit 1
fi
umount loopdir
if [ $? -ne 0 ]; then
echo "ERROR: unmount of iso file failed "
exit 1
fi
chmod u+w isofiles 
#
echo "Done"
echo ""


echo "Extracting initrd.gz ..." 
#
cd ${WORKSPACE}/workspace
gzip -d < ../isofiles/install.amd/initrd.gz | cpio \
 --extract  --make-directories --no-absolute-filenames  
if [ $? -ne 0 ]; then
echo "ERROR: Extracting initrd.gz failed "
exit 1
fi
echo "Done"
echo ""
#
echo "Download preseed.cfg file and modify based on rootfsconfig file" 
#
${COPY_METHOD}  ${FILE_PATH}/preseed.cfg 
if [ $? -ne 0 ]; then
echo "ERROR: preseed.cfg not found in httpserver"
echo "INFO: preseed.cfg  Downloading failed "
exit 1
fi
echo "Done"
echo ""
sed -i -e "s/{{ HOSTNAME }}/${ROOTFS_HOSTNAME}/" preseed.cfg
sed -i -e "s/{{ DOMAINNAME }}/${ROOTFS_DOMAINNAME}/" preseed.cfg

if [ "${ROOTFS_DHCP}" == "no" ]; then
sed -i -e 's/#d-i netcfg\/disable_dhcp/d-i netcfg\/disable_dhcp/' preseed.cfg
sed -i -e 's/#d-i netcfg\/get/d-i netcfg\/get/' preseed.cfg
sed -i -e 's/#d-i netcfg\/confirm_static/d-i netcfg\/confirm_static/' preseed.cfg
sed -i -e "s/{{ NAMESERVER }}/${ROOTFS_NAMESERVER}/" preseed.cfg
sed -i -e "s/{{ IPADDRESS }}/${ROOTFS_IPADDRESS}/" preseed.cfg
sed -i -e "s/{{ NETMASK }}/${ROOTFS_NETMASK}/" preseed.cfg
sed -i -e "s/{{ GATEWAY }}/${ROOTFS_GATEWAY}/" preseed.cfg
fi

#
echo "Modification of isolinux.cfg file" 
#
sed -i -e 's/timeout 0/timeout 1/'  ${WORKSPACE}/isofiles/isolinux/isolinux.cfg
echo "Done"
echo ""
#
echo "Create new ISO initrd.gz file ..." 
#
find . | cpio -H newc --create  | gzip -9 > \
${WORKSPACE}/isofiles/install.amd/initrd.gz     
if [ $? -ne 0 ]; then
echo "ERROR: failed "
exit 1
fi
echo "Done"
echo ""


cd ${WORKSPACE}/isofiles
${COPY_METHOD}  ${FILE_PATH}/packages.txt
${COPY_METHOD}  ${FILE_PATH}/post-install.sh
chmod u+w md5sum.txt
md5sum `find -follow -type f` > md5sum.txt

#
echo "creating the new customized automated installer ISO ..." 
#

genisoimage -quiet -o ${ISOFILE}-preseed.iso -r -J \
-no-emul-boot -boot-load-size 4 -boot-info-table \
-b isolinux/isolinux.bin -c isolinux/boot.cat . 

if [ $? -ne 0 ]; then
echo "ERROR: failed "
exit 1
fi
echo "Done"
echo ""

#
#create raw disk under workpace
#
cd ${WORKSPACE}
qemu-img create rootfs.img +3G > /dev/null
if [ $? -ne 0 ]; then
echo "ERROR: raw disk creation file failed "
exit 1
fi

#
echo "creatin bootable image through preseed.cfg" 
#
virt-install --quiet --name  rootfs  --ram 1024 --disk path=${WORKSPACE}/rootfs.img,size=3 --vcpus 1 \
 --network bridge=${ROOTFS_BRIDGE} --graphics vnc --virt-type kvm  --noautoconsole \
 --cdrom ${WORKSPACE}/isofiles/${ISOFILE}-preseed.iso 
for ((i=0; $i < 15 ;i++))
{
virsh list --all | grep rootfs | grep "shut off"
if [ $? -ne 0 ]; then
echo "image installation on going..."
sleep 6m
else
BOOTABLE_IMAGE="READY"
echo "image installation completed"
break
fi
}

echo "creating tar ball" 

if [ "${BOOTABLE_IMAGE}" == "READY" ]; then
mkdir -p  ${WORKSPACE}/rootfs
mount -t auto -o loop,offset=$((512*2048))  ${WORKSPACE}/rootfs.img ${WORKSPACE}/rootfs 
if [ $? -ne 0 ]; then
echo "ERROR: image mounting failed " 
exit 1
else
cd ${WORKSPACE}/rootfs
tar -Jcf ../rootfs-template.tar.xz * 
 if [ $? -ne 0 ]; then
    echo "ERROR: Final rootfs-template.tar.gz tarball creation failed " 
    exit 1
 fi
echo "INFO: rootfs-template.tar.xz tarball creation completed"
sleep 2m
umount -lf ${WORKSPACE}/rootfs 
if [ $? -ne 0 ]; then
    echo "ERROR: unmounting of rootfs failed " 
    exit 1 
fi
fi
else
echo "ERROR: bootable image failed " 
fi
#
#
END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc) 
echo "Time taken by the script ${DIFF} seconds" 
exit 0
