#! /bin/bash
# Coded by NixCP, Modified by Mohamed Magdy

# Install expect
yum install expect -y

# Avoid cPanel warnings
ALLOW_PASSWORD_CHANGE=1
export ALLOW_PASSWORD_CHANGE=1

# List all users and set random strong passwords
ls -1 /var/cpanel/users | while read user; do
pass=`mkpasswd -l 16 -s 0`
echo "$user $pass" >> user-pass.txt

# Change the password & update FTP login database
/scripts/ftpupdate
/scripts/realchpass $user $pass

done
