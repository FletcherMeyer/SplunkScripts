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
  echo "[+] Package Manager detected: apt-get"
  echo "[+] Ensuring packages are up to date."
  sudo apt-get install -f
  
  cd ~
  
  echo "[+] Retrieving universal forwarder."
  wget -O splunk_forwarder.deb wget "https://download.splunk.com/products/universalforwarder/releases/10.0.1/linux/splunkforwarder-10.0.1-c486717c322b-linux-amd64.deb"
  
  echo "[+] Installing universal forwarder."
  sudo dpkg -i splunk_forwarder.deb

  echo "[+] Starting universal forwarder with license acceptance."
  sudo /opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd $pswd
  
  echo "[+] Forwarding is enabled at boot-start."
  sudo /opt/splunkforwarder/bin/splunk enable boot-start

  echo "[+] Authenticating as admin."
  sudo /opt/splunkforwarder/bin/splunk login -auth admin:$admPswd
  
  echo "[+] Adding forwarding server over port $PORT to host $INDEXER_IP."
  sudo /opt/splunkforwarder/bin/splunk add forward-server $INDEXER_IP:$PORT
  
  echo "[+] Adding monitor to '/var/log/syslog'."
  sudo /opt/splunkforwarder/bin/splunk add monitor /var/log/syslog
