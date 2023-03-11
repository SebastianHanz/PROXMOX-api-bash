#!/bin/bash

PROXMOX_NODE_IP=your-proxmox-ip-here #without port
PROXMOX_NODE_NAME=your-node-name-here
PROXMOX_STORAGE=put-here-storage-name

# Comment out next two lines if you use credential file like below
API_USER=api-user-here
API_USER_PASSWORD=api-password-here 

# Uncomment next three lines if you want to store your credentials in a file
#CREDENTIAL_FILE="/root/.proxmoxcredentials"                                #Customize your path
#API_USER=$(sed -n 's/^API_USER=//p' $CREDENTIAL_FILE)                      #Get API_USER from file
#API_USER_PASSWORD=$(sed -n 's/^API_USER_PASSWORD=//p' $CREDENTIAL_FILE)    #Get API_USER_PASSWORD from file

# Manage ticket & token handling
curl --silent --insecure -k -d  "username=$API_USER@pve" --data-urlencode "password=$API_USER_PASSWORD" https://$PROXMOX_NODE_IP:8006/api2/json/access/ticket > message
jq --raw-output '.data.ticket' message | sed 's/^/PVEAuthCookie=/' > cookie
jq --raw-output '.data.CSRFPreventionToken' message | sed 's/^/CSRFPreventionToken:/' > token

# Standard container config

CPU=1
CPUUNITS=512
MEMORY=512
DISK=4G
SWAP=0
OS_TEMPLATE="local:vztmpl/debian-10-standard_10.7-1_amd64.tar.gz"


# Available script functions

case $1 in

start | stop | reboot | resume | shutdown | suspend)
    if [ $2 == lxc ]; then
        curl --silent --insecure --cookie "$(<cookie)" --header "$(<token)" -X POST https://$PROXMOX_NODE_IP:8006/api2/json/nodes/$PROXMOX_NODE_NAME/lxc/$3/status/$1
        echo "  done."
    elif [[ $2 == vm || $2 == qemu ]]; then
        curl --silent --insecure --cookie "$(<cookie)" --header "$(<token)" -X POST https://$PROXMOX_NODE_IP:8006/api2/json/nodes/$PROXMOX_NODE_NAME/qemu/$3/status/$1
        echo "  done."
    fi
    ;;

custom)
    curl --silent --insecure --cookie "$(<cookie)" --header "$(<token)" -X $2 "https://$PROXMOX_NODE_IP:8006/api2/json/nodes/$3"
    echo "  done."
    ;;

create)
    curl --insecure --cookie "$(<cookie)" --header "$(<token)" -X POST --data-urlencode net0="name=tnet$2,bridge=vmbr0" --data ostemplate=$OS_TEMPLATE --data storage=$PROXMOX_STORAGE --data vmid=$2 --data cores=$CPU --data cpuunits=$CPUUNITS --data memory=$MEMORY --data swap=$SWAP --data hostname=$3 https://$PROXMOX_NODE_IP:8006/api2/json/nodes/$PROXMOX_NODE_NAME/lxc
    echo "  done."
    ;;

delete)
    curl --silent --insecure --cookie "$(<cookie)" --header "$(<token)" -X DELETE https://$PROXMOX_NODE_IP:8006/api2/json/nodes/$PROXMOX_NODE_NAME/lxc/$2
    echo "  done."
    ;;

*)
    echo ""
    echo "Here are some methods to use this script: "
    echo ""
    echo "1.Simply start,stop,reboot.. your lxc or vm"
    echo " Syntax: start|stop|reboot|resume|shutdown|suspend lxc|vm <vmid>"
    echo " Example: ./proxmox_api.sh start vm 180"
    echo ""
    echo "2.Use custom commands without retyping static URL part (https://$PROXMOX_NODE_IP:8006/api2/json/nodes/*)"
    echo " Syntax: custom GET|POST|PUT your/command/extending/static/url"
    echo " Example: ./proxmox_api.sh custom PUT node3/lxc/100/config?memory=1024"
    echo ""
    echo "3.Create or delete LXC's from own config:  create|delete <vmid> hostname"
    echo ""
    ;;

esac

# Remove temporary files
rm cookie message token
