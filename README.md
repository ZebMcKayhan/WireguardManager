# wireguard
Manage/Install WireGuard on applicable ASUS routers

see https://www.snbforums.com/threads/experimental-wireguard-for-rt-ac86u-gt-ac2900-rt-ax88u-rt-ax86u.46164/

## Installation ##

###NOTE: Entware is assumed to be installed###

Enable SSH on router, then use your preferred SSH Client e.g. Xshell6,MobaXterm, PuTTY etc.

(TIP: Triple-click the install command below) to copy'n'paste into your router's SSH session:
    
    mkdir -p /jffs/addons 2>/dev/null;mkdir -p /jffs/addons/wireguard 2>/dev/null;curl --retry 3 "https://raw.githubusercontent.com/MartineauUK/wireguard/main/wg_manager.sh" -o "/jffs/addons/wg_manager" && chmod 755 "/jffs/addons/S50wireguard" && /jffs/addons/wg_manager.sh install
    
Example successful install.....

	Retrieving scripts 'wg_manager.sh/wg_server'

    <snip> 100.0%
    <snip> 100.0%

	Retrieving Wireguard Kernel module for RT-AC86U (v386.2)
    
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
    100   190  100   190    0     0    822      0 --:--:-- --:--:-- --:--:--   833
    100 57251  100 57251    0     0   166k      0 --:--:-- --:--:-- --:--:--  166k

	Retrieving WireGuard User space Tools for RT-AC86U (v386.2)
    
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed                            
    100   187  100   187    0     0    820      0 --:--:-- --:--:-- --:--:--   834
    100 46503  100 46503    0     0  98315      0 --:--:-- --:--:-- --:--:-- 98315

	Loading WireGuard Kernel module and Userspace Tools for RT-AC86U (v386.2)

    Installing wireguard-kernel (1.0.20210219-k27) to root...
    Configuring wireguard-kernel.

    Installing wireguard-tools (1.0.20210223-1) to root...
    Configuring wireguard-tools.

    wireguard: WireGuard 1.0.20210219 loaded. See www.wireguard.com for information.

	Creating WireGuard configuration file '/jffs/configs/WireguardVPN_map'

	Creating WireGuard 'Client' and 'Server' Peer templates 'wg11.conf' and wg21.conf'

	WireGuard install COMPLETED.

WireGuard Manager v2.0 now uses a menu (amtm compatible)




In lieu of the NVRAM variables that can retain OpenVPN Client/Server configurations across reboots, this script uses 

'/jffs/configs/WireguardVPN_map' for the WireGuard directives.

As this is a beta, the layout of the file includes placeholders, but currently, the first column is significant and is used as a primary lookup key and only the 'Auto' and 'Annotation Comment' fields are extracted/used to determine the actions taken by the script.

e.g.

    wg13    P      xxx.xxx.xxx.xxx/32    103.231.88.18:51820    193.138.218.74    # Mullvad Oz, Melbourne

is used to auto-start WireGuard VPN 'client' Peer 3 ('wg13')' in Policy mode, where the associated Policy rules are defined as

    rp13    <Dummy VPN 3>172.16.1.3>>VPN<Plex>172.16.1.123>1.1.1.1>VPN<Router>172.16.1.1>>WAN<All LAN>172.16.1.0/24>>VPN

which happens to be in the same format as the Policy rules created by the GUI for OpenVPN clients i.e.

Use the GUI to generate the rules using a spare VPN Client and simply copy'n'paste the resulting NVRAM variable

    vpn_client?_clientlist etc.
    
The contents of the WireGuard configuration file will be used when 'wg13.conf' is activated - assuming that you have used say the appropriate WireGuard Web configurator such as Mullvads' to create the Local IP address and Public/Private key-pair for the remote Peer.
 e.g
 
    S50wireguard start client 3
    
 The script supports several commands:
    
    S50wireguard   {start|stop|restart|check|install} [ [client [policy] |server]} [wg_instance] ]
    S50wireguard   start 0
                   Initialises remote peer 'client' 'wg0' solely to remain backwards compatibilty with original
    S50wireguard   start client 0
                   Initialises remote peer 'client' 'wg0'
    S50wireguard   start 1
                   Initialises local peer 'server' 'wg1' solely to remain backwards compatibilty with original
    S50wireguard   start server 1
                   Initialises local peer 'server' 'wg21' uses interface naming convention as per OpenVPN e.g. tun21
    S50wireguard   start client 1
                   Initialises remote peer 'client' 'wg11' uses interface naming convention as per OpenVPN e.g. tun11
    S50wireguard   start client 1 policy
                   Initialises remote peer 'client' 'wg11' in 'policy' Selective Routing mode
    S50wireguard   stop client 3
                   Terminates remote peer 'client' 'wg13'
    S50wireguard   stop 1
                   Terminates local peer 'server' 'wg21'
    S50wireguard   stop
                   Terminates ALL ACTIVE peers (wg1* and wg2* etc.)
    S50wireguard   start
                   Initialises ALL peers (wg1* and wg2* etc.) defined in the configuration file where Auto=Y or Auto=P
                 
and if the install is successful, there should now be simple aliases

e.g.

    wgstart         Start ALL Peers defined in the config where Auto=Y or Auto=P
    wgstop          Stop ALL ACTIVE Peers
    wgrestart       Restart/Start either the designated Peer or ALL Peers defined in config where Auto=Y or Auto=P
    wgshow          generate a report of active Peers
    wgdiag          Generate a report of active Peers (with or without DEBUG iptables/RPDB rules etc.)
 
    The following (WireGuard Manager) is the alias to allow execution of console commands  
  
e.g.

    wgm peer list   Lists the defined Peers in the config The sub-commands for peer allow manipulation of the Auto= value etc

An example of the enhanced WireGuard Peer Status report showing the names of the Peers rather than just their cryptic Public Keys

    wgshow

    (S50wireguard): 15024 v1.01b4 WireGuard VPN Peer Status check.....

	interface: wg21 	(# Martineau Host Peer 1)
		 public key: j+aNKC0yA7+hFyH7cA9gISJ9+Ms05G3q4kYG/JkBwAU=
		 private key: (hidden)
		 listening port: 1151
		
		peer: wML+L6hN7D4wx+E1SA0K4/5x1cMjlpYzeTOPYww2WSM= 	(# Samsung Galaxy S8)
		 allowed ips: 10.50.1.88/32
		
		peer: LK5/fu1iX1puR7+I/njj6W88Cr6/tDZhuaKp3XKM/R4= 	(# Device iPhone12)
		 allowed ips: 10.50.1.90/32
 
NOTE: Currently, if you start say three WireGuard remote Peers concurrently and none of which are designated as Policy Peers, ALL traffic will be forced via the most recent connection, so if you then terminate that Peer, then the least oldest of the previous Peers will then have ALL traffic directed through it.
Very crude fall-over configuration but may be useful. 

For hosting a 'server' Peer (wg21) you can use the following command to generate a Private/Public key-pair and auto add it to the 'wg21.conf' and to the WireGuard config '/jffs/configs/WireGuardVPN_map'

    wgm create Nokia6310i

	Creating Wireguard Private/Public key pair for device 'Nokia6310i'

	Device 'Nokia6310i' Public key=uAMVeM6DNsj9rEsz9rjDJ7WZEiJjEp98CDfDhSFL0W0=

	Press y to ADD device 'Nokia6310i' to 'server' Peer (wg21) or press [Enter] to SKIP.
    y
	Adding device Peer 'Nokia6310i' to RT-AC86U 'server' (wg21) and WireGuard config

and the resulting entry in the WireGuard 'server' Peer config 'wg21.conf' - where 10.50.1.125 is derived from the DHCP pool for the 'server' Peer

e.g. WireGuard configuration 'WireguardVPN_map' contains

    wg21    Y      10.50.1.1/24                                                 # Martineau Host Peer 1

and the next avaiable IP with DHCP pool prefix '10.50.1' e.g. .125 is chosen as .124 is already assigned when the Peer is appended to 'wg21.conf'

    # Nokia6310i
    [Peer]
    PublicKey = uAMVeM6DNsj9rEsz9rjDJ7WZEiJjEp98CDfDhSFL0W0=
    AllowedIPs = 10.50.1.125/32
    # Nokia6310i End
  
and the cosmetic Annotation identification for the device '# Device Nokia6310i' is appended to the WireGuard configuration 'WireguardVPN_map'  

    # Optionally define the 'server' Peer 'clients' so they can be identified by name in the enhanced WireGuard Peer status report
    # Public Key                                      DHCP IP             Annotation Comment
    <snip>
    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=      10.50.1.124         # A Cell phone
    snip>
    
    uAMVeM6DNsj9rEsz9rjDJ7WZEiJjEp98CDfDhSFL0W0=      10.50.1.125         # Device Nokia6310i

To import the device Nokia6310i into the WireGuard App on the mobile device or tablet, rather than manually enter the details, or import the text file using a secure means of transfer, it is easier to simply display the QR Code containing the configuration and point the phone's/tablet's camera at the QR Code! ;-)

     wgr qrcode Nokia6310i



    
    
     
