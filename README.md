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
  -[Terminal Options](#terminal-options)  
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
[I cant access my nas/samba share over vpn](#i-cant-access-my-nassamba-share-over-vpn)  
[Why is my SMB share slow over vpn](#why-is-my-smb-share-slow-over-vpn)

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

The {start | stop | restart} {peer | category} are also possible to execute directly from the ssh client:
```sh
wgm start wg11 #start wg11
wgm stop #stop all peers
Wgm restart MyCategory ##restart peers in category

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

## Terminal Options
Wireguard Session Manager was designed to operate properaly with XSHELL 7 with Delete Key = VT220 and Backspace = Backspace. if you are using other terminal programs (like Putty) there is a risk you will have problems with backspace not really looking like it is deleting anything altough it is.
the reason for this was that Wireguard Session Manager was designed to use "command buffert" to use "PG-UP" to get to older commands.
This does not always work well with other terminal programs. 

if you experience problems and wish to revert to "Basic" then you could issue:
```sh
E:Option ==> pgupkey off
```

if you wish to keep this setting:
```sh
E:Option ==> vx
```
and change
```sh
#NOPG_UP
```
to
```sh
NOPG_UP
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

To set the peer to autostart in default mode:
```sh
E:Option ==> peer wg11 auto=Y
```  
  
  
In Policy mode the default routing is still done over WAN. then you need to setup rules for which IP, IPRange or IPSETs that should be routed out this specific VPN. you can ofcource put your entire network on a single rule, but the router itself will access internet via WAN. some programs, like Unbound and Transmission can be bound to a specific source adress thus making it possible to have them to obey the policy rules and access internet via VPN (see section) but this is only on case-by-case basis and not all programs can be bound like this.
Because of the natural routing (for ip's not matching any rules) is via WAN it is really easy to add several VPN clients and have some IPs to use one and some use the other. also to combine VPN clients with VPN servers. This is by far the most flexible mode. The main drawback is that local router program access internet via WAN and this is difficult to work around. 
To set the peer to autostart in policy mode:
```sh
E:Option ==> peer wg11 auto=P
```
However, this will not work until you have put in atleast one rule for the peer (see section)


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
1   wg11  WAN        Any             8.8.8.8         RemoteIP
```
to avoid this the author recommends using src= and dst= to work around this, which should look like:
```sh
E:Option ==> peer wg11 rule add vpn dst=10.23.50.189 comment LocalIP
```
  
a typical use case could be that we want the entire network to go out VPN except a single computer:
```sh
E:Option ==> peer wg11 rule add vpn 192.168.1.1/24 comment All LAN to VPN
E:Option ==> peer wg11 rule add wan 192.168.1.38 comment Except This Computer
```
this works just fine, with one exception. sadly this computer will still use wg DNS (because vpn rules gets a dns redirection rule but wan rules does not). so in this case it could be better to devide your network in 2 parts, like restrict the DHCP to only give out ip adresses 192.168.1.32 - 192.168.1.255 and manually assign the numbers below 32 and create rules for these ranges separately:
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

Whenever you are satisfied with your rules, you can put the peer in policy mode:
```sh
E:Option ==> peer wg11 auto=P
```
  
## Create categories
Categories is a way of grouping clients and servers under a category name and allows you to start or stop entire categories.

you can create a category by adding peers to it directly (in this case adding wg11 and wg12 to a category named My1stCategory:
```sh
E:Option ==> peer category My1stCategory add wg11 wg12


        'Peer category 'My1stCategory' created

```
you can now check so it got created properly:
```sh
E:Option ==> peer category

        Peer categories

My1stCategory=wg11 wg12
```

now you can issue start and stop commands to this category:
```sh
E:Option ==> start My1stCategory
```
or even directly from the shell:
```sh
wgm start My1stCategory
```

at present day you cannot add or delete a single peer to the category, instead you delete it and create a new.

if you wish to remove a category:
```sh
E:Option ==> peer category My1stCategory del

        'Peer category 'My1stCategory' Deleted
```

## Geo-location
Note: development of this feature have been terminated. Please use it if it fit your needs. This feature might be removed in future versions.

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
wgm creates the ability to manage your IPSETs. it does not however, by any means, help you in the creation of IPSETs. depending on what you want to do, there are other tools for that. if you for example wish that NETFLIX and similar streaming sites should bypass VPN since these sites block connection from VPN then "x3mrouting" is just what you need. altough x3mrouting is not really compatible with routing wireguard it does a good job of creating/managing the IPSETs for you.

ofcource there is nothing stopping you from plainly create these yourself, for any purpose. an IPSET is just a list with IPAdresses which you can add or delete adresses as you wish. you can read about it here:  
[ipset man page](https://linux.die.net/man/8/ipset)  

one methode, used by x3mrouting is to have these IPSETs autopopulated with IPAdresses by dnsmasq as certain terms, like netflix is found in the adress, then the ip adress looked up is then added to the IPSET list. This way you dont suffer from changing ipadresses and you dont need to lookup ipadresses, it is all handled by dnsmasq. this ofcource requires you to actually use dnsmasq (see section about Diversion).

wgm offers some assistance in managing these IPSETs.

A couple of things need to happen for IPSET based routing to work:
1. a rule in the firewall is setup to mark packages with a destination or source adress matching an IP in IPSET. The mark is set based on where you wish to route matching IPs.
2. a routing rule is setup to direct packages with a specific mark to a specific routing table.
3. rp_filter needs to be disabled (or set to loose) for interfaces where IPSETs are routed out.

wgm will handle number 1 completally, so you dont have to worry about that. it will partally handle 2 and 3 but not for all use cases.

we can take a look at which mark is used to route where:
```sh
E:Option ==> ipset

        Table:ipset Summary

FWMark  Interface
0x1000  wg11
0x2000  wg12
0x4000  wg13
0x7000  wg14
0x3000  wg15
0x8000  wan
```

these are the preffered marks. I do not recommend changing them altough it is possible. The point is that marking a package with 0x3000 would mean that we want this package to be routed out wg15.  
an IPSET could be added to any peer. it does not however mean that it has to be routed out THAT peer it just mean that the rules gets added and deleted as the peer is started stopped. It will also create routing rule and disable rp_filter for that peer.

so, lets say we have an IPSET named NETFLIX_DNS that we want to add to wg12 for matching destination IPs to be routed out WAN:
```sh
E:Option ==> peer wg12 add ipset NETFLIX_DNS
        [✔] Ipset 'NETFLIX_DNS' Selective Routing added wg12
<snip>
IPSet        Enable  Peer  FWMark  DST/SRC
NETFLIX_DNS  Y       wg12  0x2000  dst
```
What is happening now is that wgm will create a firewall rule to mark packages with destination matching any ip in our ipset with mark 0x2000. It will also create a rule to route packages marked with 0x2000 out wg12. Since wg12 now contain ipsets then wgm also disables wg12 rp_filter.  
this was really not what we entended, clearly we wanted destinations to go out WAN instead, so we could just change the MARK accordingly: 
```sh
E:Option ==> peer wg12 upd ipset NETFLIX_DNS fwmark 0x8000
        [✔] Updated IPSet Selective Routing FWMARK for wg12
```
and we can check to see that it all looks good:
```sh
E:Option ==> peer wg12
<snip>
IPSet        Enable  Peer  FWMark  DST/SRC
NETFLIX_DNS  Y       wg12  0x8000  dst
```
The firewall rule is now Updated to mark matching packages with 0x8000 instead.
if this IPSET was infact a set of source adresses which we wanted to route out WAN instead, we need to change "dst" to be "src" instead:
```sh
E:Option ==> peer wg12 upd ipset NETFLIX_DNS dstsrc src

        [✔] Updated IPSet DST/SRC for wg12

E:Option ==> peer wg12
<snip>
IPSet        Enable  Peer  FWMark  DST/SRC
NETFLIX_DNS  Y       wg12  0x8000  src
```

and if we want to delete it:
```sh
E:Option ==> peer wg12 del ipset NETFLIX_DNS
        [✔] Ipset 'NETFLIX_DNS' Selective Routing deleted wg12
```

the final thing we can do in wgm is to disable the rp_filter for the WAN interface. whenever we use IPSET to force packages to different route we will need to disable this.  
"reverse path filter" is a very simple protection that many now days consider obsolete. whenever a packages comes in on i.e. WAN it will change place on Destination and Source and run it trough the routing table to see if a reply to this package would be routed out the same way. it understands most rules but it will not understand that some packages will recieve a mark and be routed differently. so in this case we need to disable the rp_filter on WAN, otherwise answers from WAN will not be accepted. there are 3 values for rp_filter. 0 means "Disabled", 1 means "Enabled, strict", 2 means "Enabled loose". loose means that it does not check routing explicitly, but will accept if there are any routing ways back this interface. 2 is sufficient for us.

specifically for WAN this could be handled in wgm by:
```sh
E:Option ==> rp_filter disable
         [✔] Reverse Path Filtering DISABLED (2)
```
however, Im pretty sure that this wont survive a reboot. Se we better put a 
```sh
echo 2 > /proc/sys/net/ipv4/conf/eth0/rp_filter
```
(assuming eth0 is your WAN interface) in wg12-up.sh for example (see further down).

ok, so this is how we setup IPSETs in wgm.

wgm will setup rules for marks going out wg1x interfaces but not for the WAN interface (as it is not linked to any peer). so here we need to make a custom script:
```sh
nano /jffs/addons/wireguard/Scripts/wg12-up.sh
```
populate this with your mark rule and disable the rp_filter:
```sh
#!/bin/sh
ip rule add from all fwmark 0x8000 table main prio 9900
echo 2 > /proc/sys/net/ipv4/conf/eth0/rp_filter
```
save and exit.  
you will also need to make a script to delete the rule as the peer is stopped:
```sh
nano /jffs/addons/wireguard/Scripts/wg12-down.sh
```
populate with:
```sh
#!/bin/sh
ip rule del prio 9900
```
save and exit

make both files executable:
```sh
chmod +x /jffs/addons/wireguard/Scripts/wg12-up.sh
chmod +x /jffs/addons/wireguard/Scripts/wg12-down.sh
```

now you can go into wgm and restart the peer and our rules should kick in!
```sh
E:Option ==> restart wg12
```
if we were to use the original fwmark to route out matches wg12, then we wouldnt need to create anything in wg12-up.sh. both routing rule and rp_filter is taken care of by wgm.  
in my case I have 2 country outputs, and one of the purpose is to be able to watch streaming content from a different continent, which means I want to limit the fwmark to only apply to certain subnets, in my case the rule is:
```sh
ip rule add from 192.168.1.1/24 fwmark 0x8000 table main prio 9900
```
so only 192.168.1.x will be covered by this rule. all else will be routed out VPN according to policy rules regardless of any 0x8000 fwmark set.

there are endless variations to this and the up/down scripts could be used to delete rules created by wgm and replace them with your own. I cannot cover everything in here so please read up on what everything does and adjust to your needs.

## Route WG Server to internet via WG Client
This is a brand new feature (included in 4.12b4). I cannot test this as Im not running any server. the point would be if you only have 1 client and will be able to connect home over the internet to access your LAN and also to surf the internet via your VPN client... in this case you should use the wgm "passthru" command.
when clients are connected in policy mode then of no rules are setup then server clients will access the internet via WAN. sadly it is not enough to just add the ips to the policy routing table. we also need to handle access rights in the firewall and setup masquarading. wgm handles till all for you in a single command!

some information:
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
        peer serv_peer_name {passthru client_peer {[add|del] [device|IP/CIDR]}} - Manage passthu' rules for inbound 'server' peer devices/IPs/CIDR outbound via 'client' peer tunnel
                                                                                                           peer wg21 passthru add wg11 SGS8
                                                                                                           peer wg21 passthru add wg15 all
                                                                                                           peer wg21 passthru add wg12 10.100.100.0/27
```

interpreting the help above would give, the device SGS8 connected to wg21 should be routed out wg11 for internet access.
```sh
E:Option ==> peer wg21 passthru add wg11 SGS8
```

similarely to route ALL devices connected on wg21 out wg11
```sh
E:Option ==> peer wg21 passthru add wg11 all
```

and finally to only allow a single ip or group of ips to be routed out out wg11:
```sh
E:Option ==> peer wg21 passthru add wg11 10.50.1.53/32
```


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

Note: Below instructions are ONE way of doing this. It is not the only way and may not even be the best way for your setup.

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
E:Option ==> peer wg12 rule add wan dst=192.168.5.1/24 comment ToGuest4UseMain
E:Option ==> peer wg12 rule add vpn 192.168.5.1/24 comment Guest2VPN
E:Option ==> peer wg12 auto=p
E:Option ==> restart wg12
```
This works because WAN rules have higher priority than VPN routes in wgm. The "auto=p" line could be omitted if the peer is already in policy mode.

If you need the guest network to access other subnets than your main network you might need to broaden the range of the "ToGuest4UseMain" rule. For example I used:
```sh
E:Option ==> peer wg12 rule add wan dst=192.168.1.1/16 comment ToLocalUseMain
```
If you have a wireguard server which shall be able to communicate with the guest network, replies from the guest network will need to find its way back. So then something like this may be needed:
```sh
E:Option ==> peer wg12 rule add wan dst=10.50.1.1/24 comment ToWg21UseMain
```
Ofcourse these rules will not provide any access to other subnets since we have not allowed anything in the firewall more than Guest 4 to wg12, but it will allow the packages to be routed but might still be BLOCKED by firewall.  
Add more rules if you have more subnets.

checking the rules in wg12:
```sh
E:Option ==> peer wg12
...
        Selective Routing RPDB rules
ID  Peer  Interface  Source          Destination     Description
1   wg12  WAN        Any             192.168.5.1/24  ToGuest4UseMain
2   wg12  VPN        192.168.5.1/24  Any             Guest2VPN
```

one last thing... the DNS used in YazFi for this network will for now on be overridden by wgm and the dns put into wg12 peer (or imported into). if you for some reason are unhappy with using the DNS from your imported file, you could just change it (to 8.8.8.8 in this example):
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

Note: Below instructions are ONE way of doing this. It is not the only way and may not even be the best way for your setup.

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
E:Option ==> peer wg11 rule add wan dst=192.168.1.1/16 comment ToLocalUseMain
E:Option ==> peer wg11 rule add vpn 192.168.1.1 comment Unbound2VPN
E:Option ==> peer wg11 auto=p
E:Option ==> restart wg11
```
The first line redirect packages TO 192.168.x.x to the main routing table since there are no routes for them in the VPN table.

If you plan to serve dns replies to clients connected to your wireguard vpn server you might also need something like:
```sh
E:Option ==> peer wg11 rule add wan dst=10.50.1.1/24 comment ToWg21UseMain
```
You might need to further adjust this for your system.

# I cant access my nas/samba share over vpn
 - Thanks for SNB forum member @mgear1981 for testing and elaborating to get this together.

It is common that some devices have build in protection, since they are designed to be used within a single network. This could be because higher end devices pays alot of attention to access control, to make it work from a different subnet you may need to change several settings in several different places. some devices could be just impossible to seem to get it to work from a different subnet.  

first of all, access control to i.e. NAS will not work by trying to access the share name. niether will the share pop up by itself since advertisement dont work over VPN. you will need to access the NAS "blindly" by using it's local ip-adress (like 192.168.1.20).  

some NAS uses netmask to control access, so ips within the netmask are allowed to access it, but nothing else. the netmask setting is usually under GUI, LAN --> LAN IP and usually set to 255.255.255.0. this is the same as CIDR notation /24 and means that NAS IP must match the first 3 numbers, so if NAS has 192.168.1.20 then it will accept 192.168.1.X ips to access.  

but wg server uses 10.50.1.X and therin lies our problem. in order for this to work we would have to set the netmask to 0.0.0.0 to allow all, but this is not at all recommended nor is it allowed by the GUI.  

but what if we could set our wg server to give out 192.168.2.x? Then we could adjust the netmask slightly to (255.255.252.0) /22 which would then include 192.168.0.X - 192.168.3.X. this might collide with YazFi gust networks, but they are easaly moved to some other ip's via the GUI tab.  

ofcource we could change the network mask to 255.255.0.0 and give our wg server any 192.168.X.Y ip, but it is considered good practice to limit as much access as possible. The router still prevents access, so there are no real security risks, but typically more layers of security gives better protection.

Disconnect all clients from the server and stop it:
```sh
E:Option ==> stop wg21
```

now you likely need to remove all device peers from the server:
```sh
E:Option ==> peer Device1 delX
E:Option ==> peer Device2 delX
E:Option ==> peer Device3 delX
...
```

now change wg21 ip pool:
```sh
E:Option ==> peer wg21 ip=192.168.2.0/24
```

if you create the server for the first time, you could include this ip from the beginning:
```sh
E:Option ==> peer new wg21 ip=192.168.2.0/24
```

Recreate your device peers
```sh
E:Option ==> create Device1
...
E:Option ==> create Device2
...
E:Option ==> create Device3
...
```

Set your server in auto mode and start it:
```sh
E:Option ==> peer wg21 auto=Y
E:Option ==> start wg21
```

update your netmask in the GUI (LAN --> LAN IP) to 255.255.252.0

reboot of router after all this to make sure everything got a clean start.

check if NAS accepts the new network mask, otherwise you might need to change the network mask inside the NAS configuration.

now, hopefully you will be able to access your NAS via wg VPN.

a variation of this could be to use a netmask of /17 (255.255.127.0) which will include 192.168.1.X - 192.168.126.X but still block access 192.168.127.X - 192.168.255.X so you could assign <= 126 subnet to trusted network and >= 127 subnets to less trusted networks (like guest network, IoT a.s.o.)

as an alternate way:  
whenever you feel like you reach the end of the line, and have checked that you can access everything on your local network except this specific resource, the last resort could be to masquarade your vpn communication so the NAS "thinks" the request comes from it's own subnet.  

why is this a last resort? because it actually does not solve the root cause. it will add complexity to your system while at the same time limit your ability to further control and monitor access to your NAS from VPN (as all access via VPN appears to come from the router)

lets say my stubborn share is at 192.168.1.20 and router itself has 192.168.1.1 and I have trouble accessing it from wg21, 10.50.1.x. try enter a rule in the router ssh, at the prompt:
```sh
iptables -t nat -I POSTROUTING -s 10.50.1.0/24 -d 192.168.1.20 -j SNAT --to-source 192.168.1.1 -m comment --comment "WireGuard 'server'"
```
the rule matches packets from 10.50.1.X (wg21 clients) to 192.168.1.20 (my NAS) and when packets are matches, the source adress of the packet is changed to 192.168.1.1 (and any reply is changed back). This way we have masquaraded our packages so the NAS think they come from the router itself which is on the same subnet so we are affectively bypassing whatever security measures that we never managed to get to the setting. 
this type of adress translation happens over the internet all the time without us even knowing about it. try to use 8.8.8.8 as your dns for example and do a dnsleak test. you will not see any 8.8.8.8 there because your packets were re-directed to multiple other sources (DNAT - Destination Network Adress Translation). In this case we are basically using the same technique as your router is already doing to hide your LAN ip (192.168.1.x) from the internet, so it appears as your entire LAN has one single internet adress.

if you found the rule not to be working, or you made some type, just enter the exact same rule again and just change the -I to -D to delete it:
```sh
iptables -t nat -D POSTROUTING -s 10.50.1.0/24 -d 192.168.1.20 -j SNAT --to-source 192.168.1.1 -m comment --comment "WireGuard 'server'"
```

if you are successful and wish to keep the rule, lets add it to the wg21 autostart scripts:
```sh
nano /jffs/addons/wireguard/Scripts/wg21-up.sh
```
and populate the file with:
```sh
#!/bin/sh
iptables -t nat -I POSTROUTING -s 10.50.1.0/24 -d 192.168.1.20 -j SNAT --to-source 192.168.1.1 -m comment --comment "WireGuard 'server'"
```
Save & Exit 

Create a new file to delete this when the wg server is brought down:
```sh
nano /jffs/addons/wireguard/Scripts/wg21-down.sh
```
Populate with:
```sh
#!/bin/sh
iptables -t nat -D POSTROUTING -s 10.50.1.0/24 -d 192.168.1.20 -j SNAT --to-source 192.168.1.1 -m comment --comment "WireGuard 'server'"
```

make the files executable
```sh
chmod +x /jffs/addons/wireguard/Scripts/wg21-up.sh
chmod +x /jffs/addons/wireguard/Scripts/wg21-down.sh
```

there, your rule shall now be applied when wg21 starts (including at boot) and the rule is deleted if you stop your server peer.

# Why is my SMB share slow over vpn
This is basically a problem with TCP and/or the way it is used by SMB. it has been miltigated over the years with SMD2 and SMB3 but SMB was never meant to be used on the internet.  
The speed killer for SMD is infact latency, which is partly caused by physical distance (i.e. speed of light) and partly by more equipment handling each packet.  
we cant do much about the speed of light, it is what it is. but we can do what we can to make sure out package does not need to be mangled more than bare minimum. Less handling of the package means lower latency. The typical mangling that happens is that packages which are too big for a certain interface gets cut into 2 packages and then re-assembled.  
Ones the package leaves your router on it's way over the internet there is nothing we can do about it. if your ISP has high latency out on the internet even for non-mangled packages, there is little we can do about it, and your speed will always be slow.

it has been shown that proper setting will atleast give you read/write speeds in the 20-30MB/s range.  

More detailed info about this will be provided soon.
