echo -e "LABEL=cloudimg-rootfs   /    ext4   defaults,discard    0 0\nLABEL=mongo-log   /opt/logs   auto    nofail,nobootwait,noatime   0 0\nLABEL=mongo-data   /opt/data   auto    defaults,auto,noatime,noexec    0 0" > /etc/fstab
e2label /dev/xvdf mongo-data
e2label /dev/xvdb mongo-log
sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/init.d/mongodb
if [[ "$(sed -n '/INIT INFO/p' /etc/init.d/mongodb)" == "" ]]; then
sed -i '1a ### BEGIN INIT INFO\n# Provides:          mongodb\n# Required-Start:    nagios-nrpe-server\n# Required-Stop:     $local_fs $remote_fs $syslog $named $network\n# Should-Start:\n# Should-Stop:\n# Default-Start:     2 3 4 5\n# Default-Stop:      0 1 6\n# Short-Description: Start/Stop the Nagios remote plugin execution daemon\n### END INIT INFO\n' /etc/init.d/mongodb
fi
if [[ "$(sed -n '/INIT INFO/p' /etc/init.d/nagios-register)" == "" ]]; then
sed -i '1a ### BEGIN INIT INFO\n# Provides:          nagios-register\n# Required-Start:    $all\n# Required-Stop:     $local_fs $remote_fs $syslog $named $network\n# Should-Start:\n# Should-Stop:\n# Default-Start:     2 3 4 5\n# Default-Stop:      0 1 6\n# Short-Description: Start/Stop the Nagios remote plugin execution daemon\n### END INIT INFO\n' /etc/init.d/nagios-register
fi
if [[ "$(sed -n '/INIT INFO/p' /etc/init.d/log.io-harvest)" == "" ]]; then
sed -i '1a ### BEGIN INIT INFO\n# Provides:          log-io\n# Required-Start:    nagios-nrpe-server\n# Required-Stop:     $local_fs $remote_fs $syslog $named $network\n# Should-Start:\n# Should-Stop:\n# Default-Start:     2 3 4 5\n# Default-Stop:      0 1 6\n# Short-Description: Start/Stop the Nagios remote plugin execution daemon\n### END INIT INFO\n' /etc/init.d/log.io-harvest
fi
if [[ "$(sed -n '/kernel/p' /etc/init.d/mongodb)" == "" ]]; then
sed -i 's/.*\$prog --config.*/    if \[ -f \/sys\/kernel\/mm\/transparent_hugepage\/enabled \]\; then\n        echo never \> \/sys\/kernel\/mm\/transparent_hugepage\/enabled\n    fi\n    if \[ \-f \/sys\/kernel\/mm\/transparent_hugepage\/defrag \]\; then\n        echo never \> \/sys\/kernel\/mm\/transparent_hugepage\/defrag\n    fi\n    ulimit \-n 65535\n    ulimit \-u 65535\n    su \- ubuntu \-c \"\$prog \-\-config \$config\"\n/' /etc/init.d/mongodb
fi

update-rc.d -f nagios-nrpe-server remove
update-rc.d -f nagios-nrpe-server defaults 25 95
update-rc.d -f mongodb remove
update-rc.d -f mongodb defaults 30 90
update-rc.d -f nagios-register remove
#update-rc.d -f nagios-register defaults 99 99
if [[ "$(sed -n '/^[^#].*nofile/p' /etc/security/limits.conf)" == "" ]]; then
sed -i '/End/a * - nofile 65535\n* - nproc 65535' /etc/security/limits.conf
fi
sed -i 's/^su.*/#&/' /etc/rc.local
apt-get update
apt-get upgrade

mongo
use admin
db.shutdownServer()

do-release-upgrade

e2label /dev/xvda1 cloudimg-rootfs
mv /usr/lib/python2.7/dist-packages/PyYAML* /tmp
pip install --upgrade --force-reinstall awscli botocore boto3

https://www.apriorit.com/dev-blog/596-pros-and-cons-dkms

sed -i 's/.*FSCKFIX.*/FSCKFIX\=yes/' /etc/default/rcS
sed -i 's/\(.*cloudimg-rootfs.* 0 \)0/\11/' /etc/fstab
touch /forcefsck
	
mkdir /tmp/ssm
cd /tmp/ssm
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb
sudo start amazon-ssm-agent

sed -i 's/.*FSCKFIX.*/FSCKFIX\=no/' /etc/default/rcS
rm /forcefsck

sudo sed -i '/^GRUB\_CMDLINE\_LINUX/s/\"$/net\.ifnames\=0 biosdevname\=0\"/' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo update-grub

dd if=/dev/zero of=/var/swapfile bs=1024 count=524288
chown root:root /var/swapfile
chmod 600 /var/swapfile
mkswap /var/swapfile
/var/swapfile swap swap defaults 0 2


echo -e "n\np\n\n\n\np\nw\nq" | fdisk /dev/xvdz
mkfs.ext4 /dev/xvdz1
mount /dev/xvdz1 /mnt/
rsync -aHAXxS --partial --exclude '/dev/*' --exclude '/proc/*' --exclude '/sys/*' --exclude '/run/*' --exclude '/mnt/*' / /mnt/
e2label /dev/xvdz1 cloudimg-rootfs
for x in 'dev' 'proc' 'sys' 'run'; do mount --bind /$x /mnt/$x; done
chroot /mnt/
grub-install /dev/nvme1n1
update-grub

sudo /etc/init.d/monit stop
sudo /etc/init.d/opsworks-agent stop
sudo rm -rf /etc/aws/opsworks/ /opt/aws/opsworks/ /var/log/aws/opsworks/ /var/lib/aws/opsworks/ /etc/monit.d/opsworks-agent.monitrc /etc/monit/conf.d/opsworks-agent.monitrc /var/lib/cloud/ /var/chef /opt/chef /etc/chef
sudo apt-get -y remove chef
sudo dpkg -r opsworks-agent-ruby
