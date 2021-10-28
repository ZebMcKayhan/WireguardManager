# wireguard

for installation instructions, se original repo: https://github.com/MartineauUK/wireguard

Wireguard Session Manager (2nd) thread: https://www.snbforums.com/threads/session-manager-discussion-2nd-thread.75129/
Wireguard Session Manager: https://www.snbforums.com/threads/session-manager-discussion-thread-closed-expired-oct-2021-use-http-www-snbforums-com-threads-session-manager-discussion-2nd-thread-75129.70787/
Original thread: https://www.snbforums.com/threads/experimental-wireguard-for-rt-ac86u-gt-ac2900-rt-ax88u-rt-ax86u.46164/

# WGM tips and various instructions
- cooming soon
Import Client

add persistentKeepalive if not there.

Change DNS/mtu if needed

check connection/import

ipv6
  
Select Default of Policy routing?

why should I choose one or the other?
  
Create rules in WGM

terminology/nomenclature

prioritization

# Manage/Setup IPSETs for policy based routing
- cooming soon

# Using Yazfi and WGM to route different SSIDs to different VPNs
source: https://github.com/jackyaz/YazFi

Yazfi is an extremely useful tool to manage guestnetworks on asuswrt-merlin. It allows you to setup 6 different SSIDs where each SSID typically gets its own subnet and you get to individually control their DNS. 

Prerequsites: Having YazFi installed and the wireguard client you want to use imported (and working) in wgm.

I'm using one guest network to go out WAN (as a failsafe) so I dont have to do any more than set this up in the GUI provided. Asus interfaces for the guest networks 2.4GHz guest 1, 2, 3 is: wl0.1, wl0.2, wl0.3 and for 5GHz guest 4, 5, 6 is: wl1.1, wl1.2, wl1.3

so in order to setup Guest Network 4 (192.168.5.x) to access internet via wg12, we need to start with YazFi and create a custom script:
```sh
nano /jffs/addons/YazFi.d/userscripts.d/wg-yazfi.sh
```

Now we need to add firewall rules to allow this guest network to create new connections out to the internet on this interface and also only accept replies to our packages back, nothing else. populate the file with:
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

iptables -t nat -I POSTROUTING -s 192.168.5.0/24 -o wg12 -j MASQUERADE
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

iptables -t nat -D POSTROUTING -s 192.168.5.0/24 -o wg12 -j MASQUERADE
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

Inside wgm we will setup the routing rules so that the guest network will be routed out wg12. however, there is a snag... the routing table used for wg12 (which we are about to redirect guest network packages to) does only contain routes to internet via wg12 and to our local/main network. this means that there are no information there back to our guest network for packages destined TO our guest networks. that leaves us with 2 options:
* 1. Add routes for our guest network in that table
* 2. redirect packages TO our guest network to main table.

I have choosen to use option 2 because it is easier. 

so in wgm we issue (one by one):
```sh
E:Option ==> peer wg12 rule add vpn 192.168.5.1/24 comment Guest2VPN
E:Option ==> peer wg12 rule add wan 0.0.0.0/0 192.168.5.1/24 comment ToGuestUseMain
E:Option ==> peer wg12 auto=p
E:Option ==> restart wg12
```
This works because WAN routes have higher priority than VPN routes in wgm. The last line could be omitted if the peer is already in policy mode.

checking the rules in wg12:
```sh
E:Option ==> peer wg12
...
        Selective Routing RPDB rules
ID  Peer  Interface  Source          Destination     Description
1   wg12  WAN        0.0.0.0/0       192.168.5.1/24  ToGuestUseMain
2   wg12  VPN        192.168.1.1/24  Any             Guest2VPN
```

one last thing... the DNS used in YazFi for this network will for now on be overridden by wgm and the dns put into wg12 peer (or imported into). if you fore some reason are unhappy with using the DNS from your imported file, you could just change it (to 8.8.8.8 in this example):
```sh
E:Option ==> peer wg12 dns=8.8.8.8
E:Option ==> restart wg12
```

Thats it! it should now be working... if the rules did not come out correct, delete them and add them again.


# Setup a reverse policy based routing
why would anyone ever need to do this?
- cooming soon

# Route WG Server to internet via WG Client
- cooming soon

# Setup Transmission and/or Unbound to use WG Client
- cooming soon
