#! /bin/bash
# Developed by Mohamed Magdy

# Cleaning
rm -f /root/user-pass.txt

# Install expect
yum install expect -y

# List all users and set random strong passwords
ls -1 /var/cpanel/users | grep -v system | while read user; do
pass=`mkpasswd -l 18 -s 3`
echo "$user $pass" >> /root/user-pass.txt

# Change the password & update FTP login database
whmapi1 passwd user="$user" password="$pass"
done

# Info
echo "Passwords are located in /root/user-pass.txt"