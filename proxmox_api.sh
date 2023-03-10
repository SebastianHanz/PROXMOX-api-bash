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
OS_TEMPLATE="IMAGES:vztmpl/centos-8-default_20191016_amd64.tar.xz"


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
    curl --silent --insecure --cookie "$(<cookie)" --header "$(<token)" -X POST https://$PROXMOX_NODE_IP:8006/api2/json/nodes/$2
    echo "  done."
    ;;

create)
    curl --insecure --cookie "$(<cookie)" --header "$(<token)" -X POST --data-urlencode net0="name=tnet$2,bridge=vmbr0" --data ostemplate=$OS_TEMPLATE --data storage=$PROXMOX_STORAGE --data vmid=$2 --data cores=$CPU --data cpuunits=$CPUUNITS --data memory=$MEMORY --data swap=$SWAP --data hostname=ctnode$2 https://$PROXMOX_NODE_IP:8006/api2/json/nodes/$PROXMOX_NODE_NAME/lxc
    echo "  done."
    ;;

delete)
    curl --silent --insecure --cookie "$(<cookie)" --header "$(<token)" -X DELETE https://$PROXMOX_NODE_IP:8006/api2/json/nodes/$PROXMOX_NODE_NAME/lxc/$2
    echo "  done."
    ;;

*)
    echo ""
    echo " usage:  start|stop|reboot|resume|shutdown|suspend lxc|vm <vmid> #Simply start,stop,reboot.. your lxc or vm"
    echo " usage:  custom node3/lxc/155/status/reboot #Adding custom commands without typing static URL parts (https://$PROXMOX_NODE_IP:8006/api2/json/nodes/)"
    echo " usage:  create|delete <vmid> "
    echo ""
    ;;

esac

# Remove temporary files
rm cookie message token
rm cookie message token
