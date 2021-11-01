# wireguard

for installation instructions, se original repo: https://github.com/MartineauUK/wireguard

Wireguard Session Manager (2nd) thread: https://www.snbforums.com/threads/session-manager-discussion-2nd-thread.75129/

Wireguard Session Manager: https://www.snbforums.com/threads/session-manager-discussion-thread-closed-expired-oct-2021-use-http-www-snbforums-com-threads-session-manager-discussion-2nd-thread-75129.70787/

Original thread: https://www.snbforums.com/threads/experimental-wireguard-for-rt-ac86u-gt-ac2900-rt-ax88u-rt-ax86u.46164/

## Table of content
[Setup wgm](#setup-wgm)  
 -[Import Client](#import-client)  
 -[Add persistentKeepalive](#add-persistentkeepalive)  
 -[Change DNS/mtu/Name](#change-dnsmtuname)  
 -[Check connection](#check-connection)  
 -[ipv6](#ipv6)  
 -[Default or Policy routing](#default-or-policy-routing)  
 -[Create rules in WGM](#create-rules-in-wgm)  
 -[Manage/Setup IPSETs for policy based routing](#managesetup-ipsets-for-policy-based-routing)  
 -[Route WG Server to internet via WG Client](#route-wg-server-to-internet-via-wg-client)  

[Using Yazfi and WGM to route different SSIDs to different VPNs](#using-yazfi-and-wgm-to-route-different-ssids-to-different-vpns)  
[Setup a reverse policy based routing](#setup-a-reverse-policy-based-routing)  
[Setup Transmission and/or Unbound to use WG Client](#setup-transmission-andor-unbound-to-use-wg-client)  

# Setup wgm

## Import Client
First make sure to obtain a client file from your favorite wireguard vpn provided. Once you have obtained your .conf file, copy it to router here:
```sh
/opt/etc/wireguard.d/
```
You can name the file whatever you want but it needs to end with .conf. I will assume you name the file filename.conf  

We could import this file in wgm, it is designed to work just that easy. 

Depending om which version of wgm you are running the syntax could be abit different.  
Starting with listing possible imports:
```sh
E:Option ==> import ?
```
In the filelist displayed by wgm hopefully our "filename.conf" is there. If not the file is either in the wrong directory or wrong filename.

When you have manage to get wgm to display you file we could import it. There have been a couple of different command variations depending on which version you use:
```sh
E:Option ==> import filename name=wg11
```
Starting with version 4.12b2 there is no need to use name=wg11 since wgm will automatically import it to the first available client wg1x slot.

You can force an arbitrary name instead of wg11, wg12 a.s.o but some function would not work correctly in wgm so I dont recommend it.

Now you can use 2 command to look at your import:
```sh
E:Option ==> list
```
And
```sh
E:Option ==> peer
```
And you can start the client peer:
```sh
E:Option ==> start wg11
```
Still however the client will not autostart... keep reading...

## Add persistentKeepalive
It is usually recommended to add some kind of pinging to keep the sockets from closing and keep conntrack happy and nat tunnels open. There are no support for this in wgm so:
```sh
E:Option ==> stop wg11
E:Option ==> exit
```
Then edit the active config file:
```sh
nano /opt/etc/wireguard.d/wg11.conf
```
And add this in a new line at the end of the file:
```sh
PersistentKeepalive = 25
```
Save and exit

Look at the client so it is working:
```sh
E:Option ==> start wg11
E:Option ==> list
```
It should now say PeristentKeepalive 25.

## Change DNS/mtu/name
Dns:
```sh
E:Option ==> peer wg11 dns=8.8.8.8
```
Mtu:
```sh
E:Option ==> peer wg11 mtu=1420
```
Name:
```sh
E:Option ==> peer wg11 tag=My1stVPNClient
```

## check connection

## ipv6
  
## Default or Policy routing?
  
## Create rules in WGM

## Manage/Setup IPSETs for policy based routing
- cooming soon

## Route WG Server to internet via WG Client

# Using Yazfi and WGM to route different SSIDs to different VPNs
source: https://github.com/jackyaz/YazFi

Yazfi is an extremely useful tool to manage guestnetworks on asuswrt-merlin. It allows you to setup 6 different SSIDs where each SSID typically gets its own subnet and you get to individually control their DNS. 

Prerequsites: Having YazFi installed and the wireguard client you want to use imported (and working) in wgm.

I'm using one guest network to go out WAN (as a failsafe) so I dont have to do any more than set this up in the GUI provided. Asus interfaces for the guest networks 2.4GHz guest 1, 2, 3 is: wl0.1, wl0.2, wl0.3 and for 5GHz guest 4, 5, 6 is: wl1.1, wl1.2, wl1.3

so in order to setup Guest Network 4 (192.168.5.x) to access internet via wg12, we need to start with YazFi and create a custom script:
```sh
nano /jffs/addons/YazFi.d/userscripts.d/wg-yazfi.sh
```

Now we need to add firewall rules to allow this guest network to create new connections out to the internet on this interface and also only accept replies to our packages back, nothing else. 

populate the file with:
```sh
#!/bin/sh
iptables -I YazFiFORWARD -i wl1.1 -o wg12 -j ACCEPT
iptables -I YazFiFORWARD -i wg12 -o wl1.1 -m state --state RELATED,ESTABLISHED -j ACCEPT
#iptables -I YazFiINPUT -i wl1.1 -j ACCEPT #only needed for Guest network to access router itself(GUI or samba shares et.c.)
```
Now, if you use 2 or more guest network to get access to wg12 just duplicate the 3 lines and change wlx.x and if you use another wg interface just replace wg12 with your wireguard interface.

If you require your guest network to access the router itslef (like GUI, samba shares and such) then you just remove the # on the last line.

if you also want the guest network to have access to you local/main network, use the GUI for enable "2-way to guest"

When you are done, save and exit.

make the script executable:
```sh
chmod +x /jffs/addons/YazFi.d/userscripts.d/wg-yazfi.sh
```

If you want you can run the script manually once to get the rules added immediately. 
```sh
/jffs/addons/YazFi.d/userscripts.d/wg-yazfi.sh
```
it will run automatically from now on.

Thats it for YazFi, now heading over to wgm, but before starting it we create the custom scripts:
```sh
nano /jffs/addons/wireguard/Scripts/wg12-up.sh
```
Replace the name with your wg interface name, but the scripts must be named like this in order for it to start as the wireguard interface is started.

Populate with
```sh
#!/bin/sh

iptables -t nat -I POSTROUTING -s 192.168.5.1/24 -o wg12 -j MASQUERADE
```
Use your guest network ip range and change wg12 interface according to your needs. if you have more guest networks you can dublicate the line and change the ipadress accordingly.

save & exit.

make the file executable:
```sh
chmod +x /jffs/addons/wireguard/Scripts/wg12-up.sh
```

then we also need to make a script that removes the rule if the interface it shut down:
```sh
nano /jffs/addons/wireguard/Scripts/wg12-down.sh
```
Populate with:
```sh
#!/bin/sh

iptables -t nat -D POSTROUTING -s 192.168.5.1/24 -o wg12 -j MASQUERADE
```
Again, you need to duplicate this line if you have more guest networks going out wg12. note that it needs to be the same as the lines put in wg12-up.sh with the only change that -I becomes -D

Save & exit, make the file executable:
```sh
chmod +x /jffs/addons/wireguard/Scripts/wg12-down.sh
```

Thats it for scripting! now lets head into wgm:
```sh
wgm
```

YazFi has a tendency to restart the firewall when it starts after everything else has started. In order for wgm to cope with this we issue:
```sh
E:Option ==> firewallstart
```

Inside wgm we will setup the routing rules so that the guest network will be routed out wg12. 

however, there is a snag... the routing table used for wg12 (which we are about to redirect guest network packages to) does only contain routes to internet via wg12 and to our local/main network. this means that there are no information there back to our guest network for packages destined TO our guest networks. that leaves us with 2 options:
* 1) Add routes for our guest network in that table
* 2) redirect packages TO our guest network to main table.

I have choosen to use option 2 because it is easier, since it does not require scripting. 

so in wgm we issue (one by one):
```sh
E:Option ==> peer wg12 rule add wan 0.0.0.0/0 192.168.5.1/24 comment ToGuest4UseMain
E:Option ==> peer wg12 rule add vpn 192.168.5.1/24 comment Guest2VPN
E:Option ==> peer wg12 auto=p
E:Option ==> restart wg12
```
This works because WAN rules have higher priority than VPN routes in wgm. The "auto=p" line could be omitted if the peer is already in policy mode.

If you need the guest network to access other subnets than your main network you might need to broaden the range of the "ToGuest4UseMain" rule. For example I used:
```sh
E:Option ==> peer wg12 rule add wan 0.0.0.0/0 192.168.1.1/16 comment ToLocalUseMain
```
If you have a wireguard server which shall be able to communicate with the guest network, replies from the guest network will need to find its way back. So then something like this may be needed:
```sh
E:Option ==> peer wg12 rule add wan 0.0.0.0/0 10.50.1.1/24 comment ToWg21UseMain
```
Ofcourse these rules will not provide any access to other subnets since we have not allowed anything in the firewall more than Guest 4 to wg12, but it will allow the packages to be routed but might still be BLOCKED by firewall.  
Add more rules if you have more subnets.

checking the rules in wg12:
```sh
E:Option ==> peer wg12
...
        Selective Routing RPDB rules
ID  Peer  Interface  Source          Destination     Description
1   wg12  WAN        0.0.0.0/0       192.168.5.1/24  ToGuest4UseMain
2   wg12  VPN        192.168.5.1/24  Any             Guest2VPN
```

one last thing... the DNS used in YazFi for this network will for now on be overridden by wgm and the dns put into wg12 peer (or imported into). if you fore some reason are unhappy with using the DNS from your imported file, you could just change it (to 8.8.8.8 in this example):
```sh
E:Option ==> peer wg12 dns=8.8.8.8
E:Option ==> restart wg12
```

Thats it! it should now be working... if the rules did not come out correct, delete them and add them again.


# Setup a reverse policy based routing
why would anyone ever need to do this?

well, for one thing, if you want/need ALL local processes on router to access internet via VPN. it could be that your specific program does not have the ability to bind to a specific socket/adress and does not use a specific port or anything else that could be used to identify and re-route the package and you really want/need this process to access internet via VPN, then using default routing is pretty much the only way. I would however recommend trying other solutions instead, since this is not very scalable.

when should I not use this?

since you need to handle everything manually, via scripting, it works best if you dont ever need to change it too much and there are not too many rules. prefferably only one interface or one ip adress that should go outside VPN.

is has also been proven difficult to get a WG server working properly (since these packages want to go out VPN and not WAN as they should). I will however present a solution that should work, but has not been properly tested.

ok, here we go... assuming the use of wg11 (set in auto=y, default mode), we create a wgm custom script:
```sh
nano /jffs/addons/wireguard/Scripts/wg11-up.sh
```
and populate the file with:
```sh
#!/bin/sh
#
#################################
# Create ip table 117 without VPN
#################################
ip route flush table 117 2>/dev/null # Clear table 117
ip route show table main | while read ROUTE # Copy all routes from main table to table 117 except wg11 routes
do
    {
        if ! echo "$ROUTE" | grep 'wg11' ; then
                ip route add table 117 $ROUTE
        fi
    } 1> /dev/null
done
###############################

#################################
# Add rules for which to use this table
#################################
ip rule add from 192.168.50.150 table 117 prio 9990 #Send single ip through WAN
#ip rule add iif wl1.1 table 117 prio 9991 #Send guest wifi 4 through WAN (interface way)
#ip rule add 192.168.5.1/24 table 117 prio 9992 #Send guest wifi 4 through WAN (ip way)
#ip rule add fwmark 0x8000 table 117 prio 9993
# More rules for ip's or ipset marks or interfaces could be added here if needed....
#################################

#################################
# Clear route cache so routing will start over
#################################
ip route flush cache
#################################
```
The comments in the scripts are quite self-explainatory. the first section makes a complete copy of the main routing table except for routes that contain wg11 (change this interface if you have set another wg interface to default routing).

in the next section you will have to add rules for everything that should be using this new table (and access internet through WAN). follow the axample and create as many rules as needed.

Save & Exit.

Create a new file to delete all this when the wg client is brought down:
```sh
nano /jffs/addons/wireguard/Scripts/wg11-down.sh
```
Populate with:
```sh
#!/bin/sh

# Delete rules:
ip rule del prio 9990
#ip rule del prio 9991
#ip rule del prio 9992
#ip rule del prio 9993
#...

# Delete table 117:
ip route flush table 117 2>/dev/null
```
make the files executable
```sh
chmod +x /jffs/addons/wireguard/Scripts/wg11-up.sh
chmod +x /jffs/addons/wireguard/Scripts/wg11-down.sh
```
run the -up script once manually to apply changes immediately, it will run automatically from now on:
```sh
/jffs/addons/wireguard/Scripts/wg11-up.sh
```

Thats it! now your system should be default route via VPN for everything except for what you have created rules for.

now the problem with running a wg server, it should be possible by adding these rules:
```sh
iptables -t mangle -I OUTPUT -p udp --sport 51820 -j MARK --set-mark 0x8000
ip rule add fwmark 0x8000 table 117 prio 9997
echo 2 > /proc/sys/net/ipv4/conf/eth0/rp_filter
```
change the --sport to your wireguard server port. test by executing the commands directly at the prompt. if you find that they are working:

add the commands to wg21-up.sh, make it executable.

create wg21-down.sh where you remove the rules, make it executable.

# Setup Transmission and/or Unbound to use WG Client
- cooming soon
