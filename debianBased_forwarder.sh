#!/bin/bash

INDEXER_IP = "0.0.0.0"
PORT = 9997

if [ "$EUID" -ne 0 ]
  then echo "[-] Pretty please run as root."
  exit
fi

read -s -p "[+] Pretty please enter the password for this server's Splunk instance (Your choice): " pswd
read -s -p "[+] Pretty please enter the password for the Splunk server's admin (Splunk admin's choice): " admPswd

if command -v apt-get &> /dev/null; then
  echo "[+] Package Manager: apt-get"
  sudo apt-get install -f
  
  cd ~
  wget -O splunk_forwarder.deb wget "https://download.splunk.com/products/universalforwarder/releases/10.0.1/linux/splunkforwarder-10.0.1-c486717c322b-linux-amd64.deb"
  sudo dpkg -i splunk_forwarder.deb

  sudo /opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd $pswd
  sudo /opt/splunkforwarder/bin/splunk enable boot-start

  sudo /opt/splunkforwarder/bin/splunk login -auth admin:$admPswd
  sudo /opt/splunkforwarder/bin/splunk add forward-server $INDEXER_IP:$PORT
  sudo /opt/splunkforwarder/bin/splunk add monitor /var/log/syslog
