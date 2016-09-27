#!/bin/bash

DEFAULT_cellid="02:12:34:56:78:90"
DEFAULT_networkname="meshnet"
DEFAULT_channel=1
DEFAULT_meshinterface="mesh0"
DEFAULT_interface="eth0"
DEFAULT_ipmode="static"
DEFAULT_ip="192.168.3.1"
DEFAULT_mode="802.11s"


function show_help(){

echo "-h show this help"
echo "-c cellid"
echo "-n network name"
echo "-k channel"
echo "-i interface"
echo "-b mesh interface"
echo "-a (ip address , auto)"
echo "-m mode (batman, 802.11s, normal ad-hoc)"

}

start_batman() {
    sudo modprobe batman-adv
    sudo ifconfig $interface mtu 1528
    sudo ifconfig $interface down
    sudo iwconfig $interface mode ad-hoc essid $networkname ap $cellid channel $channel
    sudo batctl if add $interface
    sudo ifconfig $interface up
    sudo ifconfig bat0 up
    
    if [ $ipmode == "auto" ]; then
        sudo avahi-autoipd -D $interface
    else
        sudo ifconfig $interface $ipmode
    fi

}

start_802.11s() {
    sudo iw dev $interface interface add $interface type mp mesh_id $networkname

    renamed=$(dmesg | tail -n 100 | tail -n 1 | grep "renamed from")

    if [[ ! -z "$renamed" ]]; then
        echo "$interface was renamed"
        new=$(echo $renamed | grep -oP "[A-Za-z0-9]*(?=:\srenamed\sfrom\smesh0)")
        echo "$new -> $interface"
        sudo ip link set $new name $interface
    fi

    sudo ifconfig $interface down
    sudo ifconfig mesh0 up
    
    if [ $ipmode == "auto" ]; then
        sudo avahi-autoipd -D $interface
    else
        sudo ifconfig $interface $ipmode
    fi
}


start_ad_hoc() {
    sudo ifconfig $interface down
    sudo iwconfig $interface mode ad-hoc essid my-mesh-network ap $cellid channel $channel
    sudo ifconfig $interface up
    if [ $ipmode == "auto" ]; then
        sudo avahi-autoipd -D $interface
    else
        sudo ifconfig $interface $ipmode
    fi
}



if [ $1 == "-h" ]; then
	show_help
	exit 0
fi

while getopts ":c:n:k:i:b:a:m:" opt; do
	case $opt in
	c)
		cellid=$OPTARG
	;;
	n)
		networkname=$OPTARG
	;;
	k)
		channel=$OPTARG
	;;
	i)
		interface=$OPTARG
	;;
	b)
		meshinterface=$OPTARG
	;;
	a)
		ipmode=$OPTARG
	;;
	m)
		mode=$OPTARG
	;;
	\?)
		show_help
		echo -e "\nInvalid option: -$OPTARG"
		exit 1
	;;
	:)
		show_help
		echo -e "\nOption -$OPTARG requires an argument."
		exit 1
	;;
	esac
done

echo -e "\nsome variables were set to default\n"

if [ -z $cellid ]; then
	cellid=$DEFAULT_cellid
	echo -e "cellid: \e[33m$cellid\e[0m"
else
	echo "cellid: $cellid"
fi

if [ -z $networkname ]; then
	networkname=$DEFAULT_networkname
	echo -e "networkname: \e[33m$networkname\e[0m"
else
	echo "networkname: $networkname"
fi

if [ -z $channel ]; then
	channel=$DEFAULT_channel
	echo -e "channel: \e[33m$channel\e[0m"
else
	echo "channel: $channel"
fi

if [ -z $interface ]; then
	interface=$DEFAULT_interface
	echo -e "interface: \e[33m$interface\e[0m"
else
	echo "interface: $interface"
fi

if [ -z $meshinterface ]; then
	meshinterface=$DEFAULT_meshinterface
	echo -e "meshinterface: \e[33m$meshinterface\e[0m"
else
	echo "meshinterface: $meshinterface"
fi

if [ -z $ipmode ]; then
	ipmode=$DEFAULT_ipmode
	echo -e "ipmode: \e[33m$ipmode\e[0m"
else
	echo "ipmode: $ipmode"
fi

if [ -z $mode ]; then
	mode=$DEFAULT_mode
	echo -e "mode: \e[33m$mode\e[0m"
else
	echo "mode: $mode"
fi


if [ $mode == "batman" ]; then
    start_batman
fi

if [ $mode == "802.11s" ]; then
    start_802.11s
fi

if [ $mode == "ad-hoc" ]; then
    start_ad_hoc
fi





































