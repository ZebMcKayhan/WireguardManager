# wireguard

for installation instructions, se original repo: https://github.com/MartineauUK/wireguard

Wireguard Session Manager (2nd) thread: https://www.snbforums.com/threads/session-manager-discussion-2nd-thread.75129/

Wireguard Session Manager: https://www.snbforums.com/threads/session-manager-discussion-thread-closed-expired-oct-2021-use-http-www-snbforums-com-threads-session-manager-discussion-2nd-thread-75129.70787/

Original thread: https://www.snbforums.com/threads/experimental-wireguard-for-rt-ac86u-gt-ac2900-rt-ax88u-rt-ax86u.46164/

## Table of content
[Setup wgm](#setup-wgm)  
  -[Import Client](#import-client)  
  -[Add persistentKeepalive](#add-persistentkeepalive)  
  -[Manage Killswitch](#manage-killswitch)  
  -[Change DNS/mtu/Name](#change-dnsmtuname)  
  -[ipv6](#ipv6)  
  -[Check connection](#check-connection)  
  -[Default or Policy routing](#default-or-policy-routing)  
  -[Create rules in WGM](#create-rules-in-wgm)  
  -[Create categories](#create-categories)  
  -[Geo-location](#geo-location)  
  -[Manage/Setup IPSETs for policy based routing](#managesetup-ipsets-for-policy-based-routing)  
  -[Route WG Server to internet via WG Client](#route-wg-server-to-internet-via-wg-client)  
  
[Why is Diversion not working for WG Clients](#why-is-diversion-not-working-for-wg-clients)  
[Using Yazfi and WGM to route different SSIDs to different VPNs](#using-yazfi-and-wgm-to-route-different-ssids-to-different-vpns)  
[Setup a reverse policy based routing](#setup-a-reverse-policy-based-routing)  
[Setup Transmission and/or Unbound to use WG Client](#setup-transmission-andor-unbound-to-use-wg-client)  

# Setup wgm

## Import Client
First make sure to obtain a client file from your favorite wireguard vpn provided. Once you have obtained your .conf file, it is a really good idea to test it on an android client (using wireguard app for Android) or windows or similar. it appears a common problem that config files have a short life and sometimes no life at all. it could spare you alot of trouble by making sure that this config file is working before proceeding with importing it into wgm.

when you have concluded that your config file is working, stop the Android/windows/whatever client and copy the .conf file to router here:
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

Now you can use several command to look at your import:
```sh
E:Option ==> list
```
And
```sh
E:Option ==> peer wg11
```
And
```sh
E:Option ==> peer wg11 config
```
Each giving different views.

Since the import the client default to "auto=N" which means it will only start if explicitly called to start and then in default mode.
This mode will have your entire network accessing internet via VPN.

If you want to start the client peer:
```sh
E:Option ==> start wg11
```

If you wish to have the client in this mode and autostart at boot, then issue:
```sh
E:Option ==> peer wg11 auto=Y
```

If you want to stop the client peer:
```sh
E:Option ==> stop wg11
```

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
E:Option ==> exit
```
We need to use the userspace tool to view this:
```sh
wg show
```
It should now say 
```sh
peristent keepalive every 25 seconds
```

## Manage Killswitch
The wgn vpn killswitch is a firewall rule to prevent access to WAN. This is handy if you rather have your connection broken than falling back to non-vpn.

The killswitch is global so you can't use it in combination with policy based routing where you allow some clients to access internet via wan.
You can temporary enable or disable this in wgm:
```sh
E:Option ==> killswitch on
E:Option ==> killswitch off
```
Any changes will be valid until the next reboot. 

To permanently change the killswitch, edit wgm configuration file::
```sh
E:Option ==> vx
```
Then disable the killswitch by adding a # in front of KILLSWITCH:
```sh
#KILLSWITCH
```
Or enable it by removing the hash:
```sh
KILLSWITCH
```
You can check killswitch function by:
```sh
E:Option ==> ?
```
You will get one of 4 messages:
```sh
[✔] WAN KILL-Switch is ENABLED
[✔] WAN KILL-Switch is temporarily ENABLED
[✖] WAN KILL-Switch is DISABLED
[✖] WAN KILL-Switch is temporarily DISABLED
```
Temporarily means the status will change the next reboot.

## Change DNS/mtu/name
Dns:
```sh
E:Option ==> peer wg11 dns=8.8.8.8
```
Mtu:
```sh
E:Option ==> peer wg11 mtu=1412
```
Tag name/Annotate:
```sh
E:Option ==> peer wg11 comment My 1st VPN Client
```

## ipv6
Note: IPv6 is experimental in wgm. Im not aware of any reports where IPv6 have been successfully implemented.
In wgm this is determined when a peer is imported. if IPv6 is determined enabled on the router, then the IPv6 will be imported.

to check which has been imported in your case you could issue:
```sh
E:Option ==> peer wg11

        Peers (Auto=P - Policy, Auto=X - External i.e. Cell/Mobile)

Client  Auto  IP              Endpoint                   DNS          MTU   Public                                        Private                                       Annotate
wg11    P     10.0.69.214/24  <importedEndpoint:port>    192.168.1.1  1412  <FrekishlyLongKeyWithRandomLetters>           <AnotherFrekishlyLongKeyWithRandomLetters>    <Peer Name>
```
The values above might differ, but the important thing to look at is the IP. If this is an IPv4 as in the picture above, then this peer has been imported as IPv4.

If there is an IPv6 here and if this is working for you, then congratulations!

If this was not intentional and/or not working properly you might want to delete this import and try again. 

It has been reported that the import has got this wrong and if that is the case you might need to manually remove the IPv6 from the .conf file before import.

## check connection
Checking connection is usually needed to find out why something is not working properly.
There are a number of things that could be the cause of why a client is not working. To start with, check if there are any handshakes going on:
```sh
E:Option ==> list

        interface: wg11         <MyWGServerIP:Port>                    IP/CIDR          # <comment>
                peer: <ImportedPeerPublicKey>
                 latest handshake: 1 minute, 20 seconds ago
                 transfer: 184 B received, 616 B sent                   0 Days, 00:03:27 from 2021-11-03 18:57:03 >>>>>>

        WireGuard ACTIVE Peer Status: Clients 1, Servers 0
```
looking at the transfer, my data above the peer was started alittle over 3min ago and there have been no user data so what we are seing are the handshakes and the pings. if you see atleast some bytes recieved and transmits it is a good sign! we can also look at the "latest handshake" as this timer gets reset at every successful handshake. Handshakes are usually alittle over 2 min so as long as this timer is reset every now and then the client is actually communicating with the server so the vpn tunnel is up!

If your bytes are showing 00 and/or the handshake timer does not get reset, this means that the tunnel is NOT up. looking like this is a bad sign (Thanks to snb forum member @chongnt for creating this):
```sh
E:Option ==> list

        interface: wg11         <MyWGServerIP:Port>                       <IP/CIDR>             # <comment>
                peer: FreakishlyLongKey
                 transfer: 0 B received, 5.20 KiB sent                  0 Days, 00:03:01 from 2021-11-04 19:17:28 >>>>>>
```

If the tunnel is not up, then start by checking your config file in another system, like Android, Windows or whatever your preffered platform is. It has been reported that some of the manually generated conf files have very short lifespan and sometimes does not work at all. this means that you might need to generate acouple of files until you find one that is working. it also means that if you have been disconnected for some time, your config file might have been killed off, so you might need to generate a new one.  
If indeed the conf file is working, we need to check the import.
Start with checking so that wgm has not accidentally imported IPv6 according to instructions above.
Further you might need manually check the .conf file:
```sh
nano /opt/etc/wireguard.d/filename.conf_imported

[Interface]
PrivateKey = FreakishlyLongPrivateKey
Address = IPv4/CIDR, IPv6/CIDR
DNS = IPv4DNS

[Peer]
Endpoint = EndpointIPHostName:Port
PublicKey = FreakishlyLongPublicKey
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```
make sure there are no extra characters or other strange things going on. while editing, you could remove the IPv6 parts to make sure wgm does not import them by mistake.
then try to import the peer again.

if/when the peer is handshaking properly but you still cant seem to connecto to internet, next thing to check is if this is DNS related.  
set the peer in Default (ALL) mode
```sh
wgm
E:Option ==> peer wg11 auto=N
E:Option ==> peer wg11 restart
```
then try to ping a known adress (like google.com):
```sh
ping 216.58.211.4
ping 8.8.8.8
```
if you get a proper response, then you are successfully pinging data over the vpn tunnel, so this works. if not, that might indicate that the tunnel is still not really up and/or something is fishy with how the routing turned out or some firewall rule preventing access. 
check your config in wgm by:
```sh
E:Option ==> diag
```
remove all sensitive data (private keys, public keys, public ip adresses a.s.o) and post on the snb forum links above to get some more assistance for your particular system.

if you can ping ip adresses, try to ping a domain name:
```sh
ping www.google.com
```
if you get proper response then your system is online and connected and whatever problem you had before could be caused by policy routing rules gone wrong.

if you dont get a responce, you are having problems resolving names but still have a working connection (this usually appears as no connection, since everything we do on internet is mostly based on these names.

try changing the peer DNS in wgm. it should be noted though that some VPN supplier prohibit the use of other DNS than their own. if you look in the .conf file there are sometimes 2 DNS but wgm only imports the 1st. use the commands above to change the DNS to the other one to see if that works better.

also try to change it to a commersial DNS like 8.8.8.8 or 9.9.9.9. you could also try to point it back to the router itself (192.168.1.1) then it will end up at the routers ordinary DNS handling and from that point you could try to change the DNS in the router GUI (WAN tab).


## Default or Policy routing?
Default routing is the most common way and basically what you will get if using stock ASUS firmware. this means everything will be routed out your client peer. Even the router itself will access internet via a wg client set in default mode and this could really be the key point. if you are using Transmission, or any other programs on the router itself in Default mode ALL local functions on the router will naturally access the internet via your vpn client. the drawback with this mode is that it is very troublesome to run multiple clients and/or even to run a wg server (basically because the server will also connect via vpn where you cant open ports). it is however possible to exclude some clients by using reverse policy routing (see section) but you will end up managing everything via scripting. so if you just want your entire network to access internet via VPN then this might be your solution. also if you really need router local programs to access internet via VPN then this might also be worth looking into.

In Policy mode the default routing is still done over WAN. then you need to setup rules for which IP, IPRange or IPSETs that should be routed out this specific VPN. you can ofcource put your entire network on a single rule, but the router itself will access internet via WAN. some programs, like Unbound and Transmission can be bound to a specific source adress thus making it possible to have them to obey the policy rules and access internet via VPN (see section) but this is only on case-by-case basis and not all programs can be bound like this.
Because of the natural routing (for ip's not matching any rules) is via WAN it is really easy to add several VPN clients and have some IPs to use one and some use the other. also to combine VPN clients with VPN servers. This is by far the most flexible mode. The main drawback is that local router program access internet via WAN and this is difficult to work around. 

## Create rules in WGM
if you have decided that policy (P) mode is what you want, we need to setup rules.  
you will get some terminology help inside wgm:
```sh
E:Option ==> peer help

        peer help                                                               - This text
        peer                                                                    - Show ALL Peers in database
        peer peer_name                                                          - Show Peer in database or for details e.g peer wg21 config
        peer peer_name {cmd {options} }                                         - Action the command against the Peer
        peer peer_name del                                                      - Delete the Peer from the database and all of its files *.conf, *.key
        peer peer_name ip=xxx.xxx.xxx.xxx                                       - Change the Peer VPN Pool IP
        peer category                                                           - Show Peer categories in database
        peer peer_name category [category_name {del | add peer_name[...]} ]     - Create a new category with 3 Peers e.g. peer category GroupA add wg17 wg99 wg11
        peer new [peer_name [options]]                                          - Create new server Peer e.g. peer new wg27 ip=10.50.99.1/24 port=12345
        peer peer_name [del|add] ipset {ipset_name[...]}                        - Selectively Route IPSets e.g. peer wg13 add ipset NetFlix Hulu
        peer peer_name {rule [del {id_num} |add [wan] rule_def]}                - Manage Policy rules e.g. peer wg13 rule add 172.16.1.0/24 comment All LAN
                                                                                                           peer wg13 rule add wan 52.97.133.162 comment smtp.office365.com
                                                                                                           peer wg13 rule add wan 172.16.1.100 9.9.9.9 comment Quad9 DNS
```
as stated before, we need to create rules for everything that needs to go out VPN. any IPs not matching any rule will go out WAN. so why would we ever need to create WAN rules you might ask? because sometimes we create a rule for VPN but needs exceptions. for this purpose WAN rules is always set to a higher priority than VPN rules, regardless of the order in wgm.

so to create a rule that will send a specific ip, say 192.168.1.38 to wg11:
```sh
E:Option ==> peer wg11 rule add vpn 192.168.1.38 comment My Computer To VPN
```
and the result will be:
```sh
E:Option ==> peer wg11
<snip>
        Selective Routing RPDB rules
ID  Peer  Interface  Source          Destination     Description
1   wg11  VPN        192.168.1.38    Any             My Computer To VPN
```
if we want to remove the rule, we use the ID:
```sh
E:Option ==> peer wg11 rule del 1
```
and the rule will be removed.

in my system I create one rule for my entire Guest network 4:
```sh
E:Option ==> peer wg11 rule add vpn 192.168.5.1/24 comment Guest To VPN
```
but since the policy routing table is not as complete as the main routing table I need to make exceptions. like if the router needs to contact this subnet it wont find any route to it in this table, so we need to make an exception:
```sh
E:Option ==> peer wg11 rule add wan 0.0.0.0/0 192.168.5.1/24 comment To Guest Use Main
```
this works brilliantly since the WAN rules have higher priority so any packets going TO this network will be using the main routing table and this is very ok, since the reason for redirect the subnet is for packages going out internet and these packages are not. Packages to internet will not have these adresses as destination so they will be sent to vpn.

wgm uses smart categorizing when only one ip adress is given. if this ip belongs to a local ip adress (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16) then it will be considered a source adress. if it does not it will be considered a destination adress.  
i.e.
```sh
E:Option ==> peer wg11 rule add vpn 10.23.50.189 comment LocalIP
E:Option ==> peer wg11 rule add wan 8.8.8.8 comment RemoteIP
```
and the result is:
```sh
E:Option ==> peer wg11
<snip>
        Selective Routing RPDB rules
ID  Peer  Interface  Source          Destination     Description
1   wg11  VPN        10.23.50.189    Any             LocalIP
1   wg11  VPN        Any             8.8.8.8         RemoteIP
```
to avoid this the author recommends using src= and dst= to work around this, which should look like:
```sh
E:Option ==> peer wg11 rule add vpn dst=10.23.50.189 comment LocalIP
```
but currently there is a bug in wgm causing the destination to be ANY in some cases, and until this is resolved we will have to resort to adding the dummy 0.0.0.0/0 (which is any) as in the example above.
  
a typical use case could be that we want the entire network to go out VPN except a single computer:
```sh
E:Option ==> peer wg11 rule add vpn 192.168.1.1/24 comment All LAN to VPN
E:Option ==> peer wg11 rule add wan 192.168.1.38 comment Except This Computer
```
this works just fine, with one exception. sadly this conputer will still use wg DNS (because vpn rules gets a dns redirection rule but wan rules does not). so in this case it could be better to devide your network in 2 parts, like restrict the DHCP to only give out ip adresses 192.168.1.32 - 192.168.1.255 and manually assign the numbers below 32 and create rules for these ranges separately:
192.168.1.0/27 #0 - 31 (no rule needed for this)
192.168.1.32/27 #32-63 (wgm VPN rule)
192.168.1.64/26 #64-127 (wgm VPN rule)
192.168.1.128/25 #128-255 (wgm VPN rule)

so in wgm:
```sh
E:Option ==> peer wg11 rule add vpn 192.168.1.128/25 comment 128-255
E:Option ==> peer wg11 rule add vpn 192.168.1.64/26 comment 64-127
E:Option ==> peer wg11 rule add vpn 192.168.1.32/27 comment 32-63
```
no rules are needed for the 0-31 range since the above rules dont cover them so it will naturally go out WAN.
now, every computer you manually assign an ip in the range 192.168.1.2 - 192.168.1.31 will go out WAN and the rest will go out VPN.
  
## Create categories

## Geo-location
This tool is handly to i.e. change the location of a specific client. This only works for peers in policy (P) mode.  
if you have multiple vpn connections wich outputs in different countries, say something like this:
```sh
E:Option ==> peer

        Peers (Auto=P - Policy, Auto=X - External i.e. Cell/Mobile)

Client  Auto  IP              Endpoint                      DNS          MTU   Annotate
wg11    P     10.0.69.214/24  <ip:port>                     8.8.8.8      1412  # Output Italy
wg12    P     10.0.93.103/24  <ip:port                      9.9.9.9      1412  # Output USA
```
we could use the jump | geo | livin to change where a source ip gets routed "on-the-fly" IOW without restarting any peers (which also means any config will get reset on the next reboot)

basic terminology is:
```sh
jump|geo|livin { @home | * | {[*tag* | wg1x]} {LAN device}
```
so if I have a client ip on the local network, 192.168.1.38, I could change this computer geo-location instantly by:
```sh
E:Option ==> livin wg11 192.168.1.38
```
or, with same result:
```sh
E:Option ==> livin Italy 192.168.1.38
```
what is happening is that a high-priority rule is created for this ip to be routed out the matching wg1x interface, and also an entry to shift the DNS to the target wg DNS.

further we could change the same IP to:
```sh
E:Option ==> livin USA 192.168.1.38
```
and 192.168.1.38 will be re-assigned to wg12 and finally:
```sh
E:Option ==> livin @home 192.168.1.38
```
will delete the rule so this ip will return to be routed to whatever the policy routing rules tell it.

this could also be used with CIDR notation:
```sh
E:Option ==> livin Italy 192.168.1.1/24
```
but in order to remove the rule, the same ip/CIDR needs to be used:
```sh
E:Option ==> livin @home 192.168.1.1/24
```
This is really handy if you want to change the location of a specific computer rapidly, but it requires you to continously work with wgm over SSH. 

Note: if you already have rules explicit for this IP setup in policy rules, there is a risk that this rule might be temporarily removed when issuing @home. this command should only be issued against IPs which does not have any explicit rules (Thanks to SNB Forum member @chongnt for finding this).

## Manage/Setup IPSETs for policy based routing
- cooming soon

## Route WG Server to internet via WG Client
- cooming soon

# Why is Diversion not working for WG Clients
Diversion is using the routers build in DNS program dnsmasq to filter content. The same goes for autopopulating IPSETs used by i.e. x3mrouting and Unbound is setup to work together with dnsmasq. When wgm diverts DNS to the wireguard DNS, these functions will not work anymore.  
in order to make this work we will need to reset the WG DNS back to the router. 

There are some precautions though. This will mean that wg clients are using the same DNS as the rest of your system (as specified in the router GUI) and it is not all VPN providers that allow access to other DNS than their specified. also putting wg DNS in the router GUI might not work since dnsmasq is not accessing internet via VPN and these DNS are typically not accessable from outside VPN. however, not all VPN suppliers are this strict.  
A popular combination is to use Unbound together with WG. since Unbound setup dnsmasq to forward requests to Unbound we will still benefit from Diversion and IPSET autopopulation. 

to change the wg DNS to use dnsmasq, simply issue:
```sh
E:Option ==> peer wg11 dns=192.168.1.1
```

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

it has also been proven difficult to get a WG server working properly (since these packages want to go out VPN and not WAN as they should). I will however present a solution that should work, but has not been properly tested.

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
This is only needed in policy mode. 

Lets Start with Transmission since this is easier. In order to select outgoing interface we need to bind the program to a specific source adress.

Please note before doing this. You will not be able to open ports if Transmission is communicating via VPN. Only proceed if this is acceptable.

What we are going to do is to make Transmission request a specific source adress on its packages. the source adress choosen should be an ip-adress that is a part of the router. typically the most straight forward ip would be to use the br0 bridge ip which usually is 192.168.1.1 (but could be different on your router). If you already have an interface (like guest network 4 for example) routed out vpn then use this local ip instead (192.168.5.1).

Stop transmission:
```sh
sh /opt/etc/init.d/S88transmission stop
```

Edit the config file:
```sh
nano /opt/etc/transmission/settings.json
```
Change this line to your router adress (assuming 192.168.1.1, change to your needs):
```sh
"bind-address-ipv4": "192.168.1.1"
```
Ideally this adress should be your wg11 adress but that would mean start/stop Transmission as wg client start/stop. Scraping current ip adress and change the config file automatically. Whilst very possible, using router main adress is much easier and no direct implications.

then start transmission again:
```sh
sh /opt/etc/init.d/S88transmission start
```

Depending on how your policy routes are setup we might add or delete rules. If you are a typical user were only a couple of single ips are routed out vpn then our main interface needs to be added:
```sh
E:Option ==> peer wg11 rule add vpn 192.168.1.1 comment Transmission2vpn
```
if you already have a general rule like 192.168.1.1/24 already directed to VPN then this should already cover it.

note: access to Transmission GUI/Webpage might be affected by the fact that Transmission is now using a specific local interface. Replies from transmission GUI back to other subnets might need additional rules... se Unbound below to add these rules to redirect replies to other subnets to main table.

For Unbound it is pretty much the same. first of all, for Wireguard clients to use unbound we need to set the wireguard DNS to use the router
```sh
E:Option ==> peer wg11 dns=192.168.1.1
```

Start unbound manager and choose:
```sh
vx
```
And change this line:
```sh
#outgoing-interface: xxx.xxx.xxx.xxx # v1.08 Martineau Use VPN tunnel to hide Root server queries from ISP (or force WAN ONLY)
```
To
```sh
outgoing-interface: 192.168.1.1 # v1.08 Martineau Use VPN tunnel to hide Root server queries from ISP (or force WAN ONLY)
```
Save and Exit.

Ok, so what is more problematic with this then Transmission?
Basically because Unbound does not only talk to internet to resolve name it also need to talk to all local clients to serve them with ips for their request.

We will handle this by redirecting ToLocal packages to main routing table.
In wgm:
```sh
E:Option ==> peer wg11 rule add wan 0.0.0.0/0 192.168.1.1/16 comment ToLocalUseMain
E:Option ==> peer wg11 rule add vpn 192.168.1.1 comment Unbound2VPN
E:Option ==> peer wg11 auto=p
E:Option ==> restart wg11
```
The first line redirect packages TO 192.168.x.x to the main routing table since there are no routes for them in the VPN table.

If you plan to serve dns replies to clients connected to your wireguard vpn server you might also need something like:
```sh
E:Option ==> peer wg11 rule add wan 0.0.0.0/0 10.50.1.1/24 comment ToWg21UseMain
```
You might need to further adjust this for your system.
