echo -e "LABEL=cloudimg-rootfs   /    ext4   defaults,discard    0 0\nLABEL=mongo-log   /opt/logs   auto    nofail,nobootwait,noatime   0 0\nLABEL=mongo-data   /opt/data   auto    defaults,auto,noatime,noexec,nofail,nobootwait    0 0" > /etc/fstab
e2label /dev/nvme2n1 mongo-data
e2label /dev/nvme1n1 mongo-log
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
do-release-upgrade



	
mkdir /tmp/ssm
cd /tmp/ssm
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb
sudo start amazon-ssm-agent

e2label /dev/nvme0n1p1 cloudimg-rootfs
mv /usr/lib/python2.7/dist-packages/PyYAML* /tmp
pip install --upgrade --force-reinstall awscli botocore boto3


sudo sed -i '/^GRUB\_CMDLINE\_LINUX/s/\"$/net\.ifnames\=0 biosdevname\=0\"/' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo update-grub

sed -i 's/.*FSCKFIX.*/FSCKFIX\=yes/' /etc/default/rcS
sed -i 's/\(.*cloudimg-rootfs.* 0 \)0/\11/' /etc/fstab
touch /forcefsck

sed -i 's/.*FSCKFIX.*/FSCKFIX\=no/' /etc/default/rcS
rm /forcefsck
ami-01161154331b0bc6b

OpenJDK 64-Bit Server VM warning: INFO: os::commit_memory(0x00000000c0000000, 357892096, 0) failed; error='Cannot allocate memory' (errno=12)

