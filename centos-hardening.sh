#!/bin/bash

#######################################
# Hardening script for CentOS by headintheclouds
# Date 21/03/2023
#######################################

# Step 1: Document the host information
echo -e "\e[33mDocumenting host information...\e[0m"
echo "Hostname: $(hostname)"
echo "IP Address: $(hostname -I)"
echo "Operating System: $(cat /etc/redhat-release)"
echo

# Step 2: BIOS protection
echo -e "\e[33mEnabling BIOS protection...\e[0m"
dmidecode -t 0 | grep -i "security status: enabled" || echo "BIOS protection not enabled"
echo

# Step 3: Hard disk encryption
echo -e "\e[33mEncrypting hard disk...\e[0m"
echo "Please enter the encryption passphrase:"
read -s passphrase
yum install -y cryptsetup
modprobe dm-crypt
dd if=/dev/zero of=/root/crypt.img bs=1M count=512
echo -n "$passphrase" | cryptsetup -q luksFormat /root/crypt.img
echo -n "$passphrase" | cryptsetup luksOpen /root/crypt.img crypt
mkfs.ext4 /dev/mapper/crypt
mount /dev/mapper/crypt /mnt
echo "/dev/mapper/crypt /mnt ext4 defaults 0 0" >> /etc/fstab
echo

# Step 4: Disk partitioning
echo -e "\e[33mPartitioning disk...\e[0m"
parted /dev/sda mklabel msdos
parted -a opt /dev/sda mkpart primary ext4 0% 100%
mkfs.ext4 /dev/sda1
echo "/dev/sda1 /mnt ext4 defaults 0 0" >> /etc/fstab
echo

# Step 5: Lock the boot directory
echo -e "\e[33mLocking boot directory...\e[0m"
chattr +i /boot/grub2/grub.cfg
chattr +i /boot/grub2/user.cfg
chattr +i /boot/grub2/device.map
echo

# Step 6: Disable USB usage
echo -e "\e[33mDisabling USB usage...\e[0m"
echo "install usb-storage /bin/true" > /etc/modprobe.d/usb-storage.conf
echo

# Step 7: Update your system
echo -e "\e[33mUpdating system...\e[0m"
yum update -y
echo

# Step 8: Check the installed packages
echo -e "\e[33mChecking installed packages...\e[0m"
yum list installed
echo

# Step 9: Check for open ports
echo -e "\e[33mChecking for open ports...\e[0m"
netstat -tulnp
echo

# Step 10: Secure SSH
echo -e "\e[33mSecuring SSH...\e[0m"
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
systemctl restart sshd
echo

# Step 11: Enable SELinux
echo -e "\e[33mEnabling SELinux...\e[0m"
yum install -y selinux-policy-targeted
sed -i 's/SELINUX=disabled/SELINUX=enforcing/' /etc/selinux/config
setenforce 1
echo

# Step 12: Set network parameters
echo -e "\e[33mSetting network parameters...\e[0m"
sysctl -w net.ipv4.ip_forward=0
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.default.send_redirects=0
sysctl -w net.ipv4.tcp_syncookies=1
echo "NETWORKING_IPV6=no" >> /etc/sysconfig/network
echo "IPV6INIT=no" >> /etc/sysconfig/network
echo

# Step 13: Manage password policies
echo -e "\e[33mManaging password policies...\e[0m"
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/g' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/g' /etc/login.defs
sed -i 's/sha512/sha512 rounds=65536/g' /etc/pam.d/system-auth-ac
echo

# Step 14: Permissions and verifications
echo -e "\e[33mPerforming permissions and verifications...\e[0m"
chmod 644 /etc/passwd /etc/group /etc/shadow /etc/gshadow
chown root:root /etc/passwd /etc/shadow
chown root:shadow /etc/shadow
chown root:root /etc/group /etc/gshadow
chown root:shadow /etc/gshadow
chown root:root /boot/grub2/grub.cfg
chmod og-rwx /boot/grub2/grub.cfg
chmod 700 /root
echo

# Step 15: Additional distro process hardening
echo -e "\e[33mHardening additional distro processes...\e[0m"
echo "kernel.randomize_va_space = 2" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
echo

# Step 16: Remove unnecessary services
echo -e "\e[33mRemoving unnecessary services...\e[0m"
systemctl disable avahi-daemon.service
systemctl disable cups.service
systemctl disable dhcpd.service
systemctl disable slapd.service
systemctl disable named.service
systemctl disable xinetd.service
systemctl disable avahi-daemon.service
echo

# Step 17: Check for security on key files
echo -e "\e[33mChecking security on key files...\e[0m"
chmod 600 /root/.ssh/authorized_keys
chmod 700 /root/.ssh/
chown root:root /root/.ssh/
ls -al /root/.ssh
echo

# Step 18: Limit root access using SUDO
echo -e "\e[33mLimiting root access using SUDO...\e[0m"
echo "root ALL=(ALL) ALL" >> /etc/sudoers.d/root
echo

# Step 19: Only allow root to access CRON
echo -e "\e[33mLimiting CRON access to root only...\e[0m"
touch /etc/cron.allow
echo "root" > /etc/cron.allow
chmod 400 /etc/cron.allow
chown root:root /etc/cron.allow
echo

# Step 20: Remote access and SSH basic settings
echo -e "\e[33mSetting up remote access and SSH basic settings...\e[0m"
sed -i 's/^#LogLevel.*/LogLevel VERBOSE/g' /etc/ssh/sshd_config
sed -i 's/^#MaxAuthTries.*/MaxAuthTries 4/g' /etc/ssh/sshd_config
systemctl restart sshd
echo

# Step 21: Disable Xwindow
echo -e "\e[33mDisabling Xwindow...\e[0m"
systemctl set-default multi-user.target
systemctl isolate multi-user.target
echo

# Step 22: Minimize Package Installation
echo -e "\e[33mMinimizing package installation...\e[0m"
yum install -y yum-utils
yum-config-manager --disable \* &> /dev/null
yum-config-manager --enable base &> /dev/null
yum-config-manager --enable updates &> /dev/null
yum-config-manager --enable extras &> /dev/null
yum-config-manager --enable epel &> /dev/null
echo

# Step 23: Checking accounts for empty passwords
echo -e "\e[33mChecking accounts for empty passwords...\e[0m"
awk -F: '($2 == "" ) {print $1}' /etc/shadow
echo

# Step 24: Monitor user activities
echo -e "\e[33mMonitoring user activities...\e[0m"
yum install -y audit
sed -i 's/^active.*/active = yes/' /etc/audit/auditd.conf
systemctl enable auditd.service
systemctl start auditd.service
echo

# Step 25: Install and configure fail2ban
echo -e "\e[33mInstalling and configuring fail2ban...\e[0m"
yum install epel-release -y
yum install fail2ban -y
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i 's/^# bantime =.*/bantime = 3600/g' /etc/fail2ban/jail.local
sed -i 's/^# maxretry =.*/maxretry = 3/g' /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban
echo

# Step 26: Rootkit detection
echo -e "\e[33mDetecting rootkits...\e[0m"
yum install rkhunter -y
rkhunter --update
rkhunter --propupd
rkhunter --check
echo

# Step 27: Monitor system logs
echo -e "\e[33mMonitoring system logs...\e[0m"
echo "auth,user.* /var/log/user.log" >> /etc/rsyslog.conf
echo "*.emerg /var/log/emergency.log" >> /etc/rsyslog.conf
systemctl restart rsyslog
echo

# Step 28: Enable 2-factor authentication
echo -e "\e[33mEnabling 2-factor authentication...\e[0m"
yum install -y google-authenticator
google-authenticator
sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd.service
echo

echo -e "\e[32mHardening complete!\e[0m"