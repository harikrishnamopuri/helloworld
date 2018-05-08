#!/bin/bash
exec > >(tee -i /var/log/post-installation-log.txt)


cat /dev/null > /etc/apt/sources.list
echo 'deb http://httpredir.debian.org/debian jessie main'  > /etc/apt/sources.list
echo 'deb http://httpredir.debian.org/debian jessie-updates main' >>  /etc/apt/sources.list
echo 'deb http://security.debian.org/ jessie/updates main' >> /etc/apt/sources.list

count=0
for ((i=0; $i < 2 ;i++))
do
apt-get update
if [ $? -ne 0 ] ; then
  count=$count+1
fi
done
if [ ${count}  -eq 2 ] ; then
  echo "apt-get  update not working please check"
fi


while read name
do
  echo "$name installation"
  apt-get install -y $name
  if [ $? -ne 0 ] ; then
  echo "$name installation has some problem"
  else
  echo "$name installation completed"
  fi 
  
done < /tmp/onie-packages.txt 

#-----------------------------------------
echo "valgrind installation"
#-----------------------------------------
dpkg --add-architecture i386;
dpkg -r valgrind-dbg valgrind libc6-dbg; 
dpkg -r  libc6-dbg:amd64; 
dpkg -r libc6-dbg:i386; 
apt-get install -y  libc6-dbg:i386; 
apt-get update; 
apt-get install -y valgrind-dbg;
if [ $? -ne 0 ] ; then
  echo "ERROR: apt-get install valgrind-dbg Failed\n"
fi


#-----------------------------------------
echo "disable apache2"
#-----------------------------------------
systemctl disable apache2

#-----------------------------------------
echo "Copy those scripts under usr/bin/ocnos*"
#-----------------------------------------
#pending
#-----------------------------------------
echo "For License manager flexnet"
#-----------------------------------------
#pending
#Enable access via ttyS0 and ttyS1
#start on runlevel [!12345]
#Add additional copyright statements /usr/share/doc/*

#-----------------------------------------
echo "/etc/hosts modification"
#-----------------------------------------
sed -i  '1s/.*/127.0.0.1 localhost OcNOS/' /etc/hosts
#-----------------------------------------
echo "/etc/default/rcS modification "
#-----------------------------------------
sed -i  's/FSCKFIX=no/FSCKFIX=yes/' /etc/default/rcS
#-----------------------------------------
echo "removing entries in 70-persistent-net.rules "
#-----------------------------------------
cat /dev/null/  > etc/udev/rules.d/70-persistent-net.rules

#-----------------------------------------
echo "Rename /usr/sbin/update-grub2 and update-grub"
#-----------------------------------------
mv /usr/sbin/update-grub /usr/sbin/update-grub.donotuse

#-----------------------------------------
echo "Edit the issue and motd files"
#-----------------------------------------
cat /dev/null > /etc/issue.net   
echo "OcNOS" > /etc/issue     
cat /dev/null > /etc/motd

#-----------------------------------------
echo "Add /lib/systemd/system/rc-local.service    StandardInput=tty"
#-----------------------------------------
sed -i  "s/StandardInput=.*/StandardInput=tty/" /lib/systemd/system/rc-local.service


#-----------------------------------------
echo "Ensure nfs disable"
#-----------------------------------------
sed -i  's/=yes/=no/g' /etc/default/nfs-common


#-----------------------------------------
echo "cleaning /var/log  usr/lib/debug , root/.ssh/known_hosts var/log/crash/* files "
#-----------------------------------------
rm -rf  /usr/lib/debug /root/.ssh/known_hosts /var/log/crash/*  /root/.bash_history ; 
rm -rf  /root/.gem
rm -rf  /etc/os-build-info /etc/os-install-info
rm -rf  /var/lib/apt/lists/partial/*
rm -rf  /root/rc/*.deb
rm -rf  /usr/src/*
rm -rf /etc/rc5.d/S03rsync /etc/rc5.d/S02autofs
rm -rf /etc/rcS.d/S15rpcbind /etc/rcS.d/S13rpcbind
rm -rf /var/lib/gems
rm -rf /var/cache/debconf/*old


find /usr/share/doc -depth -type f ! -name copyright|xargs rm || true
find /usr/share/doc -empty|xargs rmdir || true

rm -rf /usr/share/man/* /usr/share/groff/* /usr/share/info/*
rm -rf /var/cache/apt /var/lib/apt/lists

find /var/log/ -type f -regex '.*\.[0-9]+\.gz$' -delete
for I in `ls /var/log/*.log` ; do cat /dev/null > $I ; done


if [ -d /usr/share/locale ]; then
cd /usr/share/locale
for lan in  `find .  -type d -name "*"  ! -path "./e*"`
do
rm -rf $lan
done
fi


#-----------------------------------------
echo "creating OpenYuma,brodcom,cfg,debug directories"
#-----------------------------------------
mkdir -p /usr/lib/yuma
mkdir -p /usr/share/yuma
mkdir -p /broadcom /cfg
mkdir -p /usr/lib/debug
#-----------------------------------------


#-----------------------------------------
echo "sqliteodbc installation"
#-----------------------------------------
apt-get update
apt-get install -y  build-essential libc6-dbg:i386  valgrind-dbg
apt-get install -y  make 
apt-get install -y  unixodbc-dev unixodbc-bin unixodbc libsqlite3-dev
apt-get install -y  autotools-dev libsqlite-dev cdbs debhelper
cd /tmp
mkdir workings
wget http://www.ch-werner.de/sqliteodbc/sqliteodbc-0.9993.tar.gz
if [ $? -ne 0 ] ; then
  echo "ERROR: sqliteodbc-0.9993.tar.gz downloading Failed\n"
  echo "INFO: Please keep download sqliteodbc-0.9993.tar.gz and keep in internel http server for better usage"
  
fi
tar -zxvf sqliteodbc-0.9993.tar.gz
if [ $? -ne 0 ] ; then
  echo "ERROR:  sqliteodbc-0.9993.tar.gz extraction Failed\n"
  
fi
cd sqliteodbc-0.9993
./configure
if [ $? -ne 0 ] ; then
  echo "ERROR:  sqliteodbc-0.9993 ./configure Failed\n"
  
fi
make deb
if [ $? -ne 0 ] ; then
  echo "ERROR:  sqliteodbc-0.9993 make deb Failed\n"
  
fi
dpkg -i ../libsqliteodbc*.deb
if [ $? -ne 0 ] ; then
  echo "ERROR:  sqliteodbc-0.9993 make deb Failed\n"
  
fi
apt-get remove -y  unixodbc-dev unixodbc-bin libsqlite3-dev build-essential make autotools-dev libsqlite-dev cdbs debhelper
apt-get -y  autoremove
rm -rf /tmp/workings
#-----------------------------------------
echo "remove history and cache files"
#-----------------------------------------
apt-get -y  autoremove
apt-get clean
cat /dev/null > /etc/resolv.conf
rm -rf /root/.bash_history
history -c
exit 0
