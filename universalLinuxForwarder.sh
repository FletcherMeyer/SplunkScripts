#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "[-] Pretty please run as root."
  exit
fi

PORT = 9997
INDEXER_IP = "0.0.0.0"

if [ INDEXER_IP == "0.0.0.0" ]:
  echo "[o] Pretty please enter the IP address of the Splunk indexer: "
  read INDEXER_IP

GUI_CONNECT_FAILED = 0
FRWD_CONNECT_FAILED = 0

( echo >/dev/udp/172.20.241.20/8000) &>/dev/null && echo "open" || GUI_CONNECT_FAILED = 1
( echo >/dev/udp/172.20.241.20/8000) &>/dev/null && echo "open" || FRWD_CONNECT_FAILED = 1

# Should some servers be able to reach the GUI? Maybe.
# Should some servers not be able to reach the GUI? Maybe.
if [ GUI_CONNECT_FAILED == 1 ]; then
  echo "[-] Unable to reach webpage. Non-fatal. Continuing."
else
  echo "[+] Able to reach webpage. Is this necessary?"
fi
  
if [ FRWD_CONNECT_FAILED == 1 ]; then
  # We should end this and ensure proper connections are in place.
  echo "[-] Unable to forward. Fatal! Ending..."
  exit(1)
else
  echo "[+] Able to forward. Continuing."
fi

read -s -p "[o] Pretty please enter the password for this server's Splunk instance, splunkadmin. (Your choice): " pswd

if command -v apt-get &> /dev/null; then
  echo "[+] Package Manager detected: apt-get"
  echo "[+] Ensuring packages are up to date."
  sudo apt-get install -f

  cd ~
  
  echo "[+] Retrieving universal forwarder."
  wget -O splunk_forwarder.deb wget "https://download.splunk.com/products/universalforwarder/releases/10.0.1/linux/splunkforwarder-10.0.1-c486717c322b-linux-amd64.deb"
  
  echo "[+] Installing universal forwarder."
  sudo dpkg -i splunk_forwarder.deb
fi

echo "[+] Starting universal forwarder with license acceptance."
sudo /opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd $pswd
  
echo "[+] Forwarding is enabled at boot-start."
sudo /opt/splunkforwarder/bin/splunk enable boot-start

echo "[+] Authenticating as admin."
sudo /opt/splunkforwarder/bin/splunk login -auth splunkadmin:$pswd
  
echo "[+] Adding forwarding server over port $PORT to host $INDEXER_IP."
sudo /opt/splunkforwarder/bin/splunk add forward-server $INDEXER_IP:$PORT
  
echo "[+] Adding monitor to '/var/log/syslog'."
sudo /opt/splunkforwarder/bin/splunk add monitor /var/log/syslog
sudo /opt/splunkforwarder/bin/splunk add monitor /var/log/audit.log
