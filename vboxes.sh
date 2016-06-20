#!/bin/bash

# =========================================== #
#
#  Init setup apache virtualboxes on centos
#  ==   run with root user on fresh vps  ==
#
# =========================================== #

set -euf -o pipefail

DOM1="example.pw"
DOM2="example.tech"

if [[ $EUID -ne 0 ]]; then
  echo "Do it as root" 1>&2
  exit 1
fi

function pause(){
   read -p "$*"
}

pause 'At the ready [Enter] ...'

 yum check-update
 yum update
 yum upgrade

# | pv -qL 30

pause 'Fine [Enter]'

echo "Domains: $DOM1, $DOM2" 
echo "Updating .... Installing httpd ..."

sudo yum -y install httpd
sudo systemctl enable httpd.service

pause 'Fine [Enter]'

echo "Creating dir structure ... " 
echo " ... /var/www/$DOM1/public_html, /var/www/$DOM2/public_html"

sudo mkdir -p /var/www/$DOM1/public_html
sudo mkdir -p /var/www/$DOM2/public_html

sudo chown -R $USER:$USER /var/www/$DOM1/public_html
sudo chown -R $USER:$USER /var/www/$DOM2/public_html

sudo chmod -R 755 /var/www

pause 'Fine [Enter]'

echo "Creating default index files ... " 

touch  /var/www/$DOM1/public_html/index.html
echo "$DOM1" > /var/www/$DOM1/public_html/index.html

touch  /var/www/$DOM2/public_html/index.html
echo "$DOM2" > /var/www/$DOM2/public_html/index.html

sudo mkdir /etc/httpd/sites-available
sudo mkdir /etc/httpd/sites-enabled

pause 'Fine [Enter]'

echo "Creating default confs ... (Manually remove ServerAlias if it was subdomains)" 

sudo touch /etc/httpd/sites-available/$DOM1.conf
sudo touch /etc/httpd/sites-available/$DOM2.conf

    echo "<VirtualHost *:80>" >> /etc/httpd/sites-available/$DOM1.conf
    echo "ServerName www.$DOM1" >> /etc/httpd/sites-available/$DOM1.conf
    echo "ServerAlias $DOM1" >> /etc/httpd/sites-available/$DOM1.conf
    echo "DocumentRoot /var/www/$DOM1/public_html" >> /etc/httpd/sites-available/$DOM1.conf
    echo "ErrorLog /var/www/$DOM1/error.log" >> /etc/httpd/sites-available/$DOM1.conf
    echo "CustomLog /var/www/$DOM1/requests.log combined" >> /etc/httpd/sites-available/$DOM1.conf
    echo "</VirtualHost>" >> /etc/httpd/sites-available/$DOM1.conf

    echo "<VirtualHost *:80>" >> /etc/httpd/sites-available/$DOM2.conf
    echo "ServerName www.$DOM2" >> /etc/httpd/sites-available/$DOM2.conf
    echo "ServerAlias $DOM2" >> /etc/httpd/sites-available/$DOM2.conf
    echo "DocumentRoot /var/www/$DOM2/public_html" >> /etc/httpd/sites-available/$DOM2.conf
    echo "ErrorLog /var/www/$DOM2/error.log" >> /etc/httpd
/sites-available/$DOM2.conf
    echo "CustomLog /var/www/$DOM2/requests.log combined" >> /etc/httpd/sites-available/$DOM2.conf
    echo "</VirtualHost>" >> /etc/httpd/sites-available/$DOM2.conf

pause 'Fine [Enter]'

echo "Creating symlink to activate confs ... " 

sudo ln -s /etc/httpd/sites-available/$DOM1.conf /etc/httpd/sites-enabled/$DOM1.conf
sudo ln -s /etc/httpd/sites-available/$DOM2.conf /etc/httpd/sites-enabled/$DOM2.conf

pause 'Fine [Enter]'


echo "Конец фильма. Check ”/etc/httpd/conf/httpd.conf”."

echo "IncludeOptional sites-enabled/*.conf" >> /etc/httpd/conf/httpd.conf

echo "Checking IPTABLES for general REJECT rules: "
sudo cat /etc/sysconfig/iptables | grep 'REJECT'

sudo "Checking opening lines of /etc/sysconfig/iptables to see if they recommend manual edits:"
sudo head -2 /etc/sysconfig/iptables

pause 'IMPORTANT: In the next step, file /etc/sysconfig/iptables will be rewritten. Kill the script now if you do not want that. [Enter / CTRL+C]'

>/etc/sysconfig/iptables cat <<EOF
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
COMMIT
EOF

sudo cat /etc/sysconfig/iptables
echo "Restarting IPTABLES..."
sudo systemctl restart iptables

pause 'All done. Restart apache now. [Enter]'
sudo apachectl restart
