
<p align="left">
  <img title="proxmox-api" width=200 height=200 src='https://github.com/SebastianHanz/PROXMOX-api-bash/blob/main/img/logo.png?raw=true?raw=true' />
</p>


# Easy to use SHELL-script to manage your Proxmox-Host via API
## Use Proxmox-API without complicated token/cookie handling, this script will do this for you!
_Tested on Proxmox 7.1-12_   
## What do I need?
- Customize the script in the upper section with your own settings
- The script on your system made executable with __chmod +x ./proxmox_api.sh__
- A Proxmox user with the correct permissions for that specific command you want to execute  
    _(Note: User has to be created on __Proxmox VE authentication server__ NOT Linux PAM )_

## What is possible?
- __Standard functions__    
'Syntax: start|stop|reboot|resume|shutdown|suspend lxc|vm <vmid'>'


- __Use any possible API command available (see official documentation https://pve.proxmox.com/wiki/Proxmox_VE_API)__   
Custom commands without retyping __static URL__ part (https://$PROXMOX_NODE_IP:8006/api2/json/nodes/)"   
Syntax: custom GET|POST|PUT your/command/extending/static/url
- Create/Delete LXCs with preconfigured settings with one command    
'Syntax: create|delete <vmid>'
        
## Examples?
### Let's restart a VM, vmid 180 in this case:
    /path/to/script/proxmox_api.sh restart vm 180
        
### Now let's change the amount of RAM for LXC with ID __177__ on our node called __node3__:   
_(Note: Use PUT, GET or POST like described in documentation)_   

    /path/to/script/proxmox_api.sh custom PUT node3/lxc/177/config?memory=1024


### Create a LXC like preconfigured in your script named "AdGuard-LXC" with vmid 189:

    /path/to/script/proxmox_api.sh create 189 AdGuard-LXC

 