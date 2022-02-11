#!/bin/sh
version=0.2
# wgmExpo - script for executing commands inside wg_manager from the shell
# by ZebMcKayhan


# Zero input gives Version splash:
if [ "$1" = "" ];then
echo "   wgmExpo Version $version by ZebMcKayhan"
echo "      wgmExpo --help for usage info"
echo ""
exit
fi

# Process <Options>
Silent=0
PeerStatus=0
commands="" 

if [[ ${1::1} == "-" ]];then
	case "$1" in
		"--help"|"-H"|"-h")
			echo "   wgmExpo Version $version by ZebMcKayhan"
			echo ""
		        echo "   Execute menu command in Wireguard Session Manager"
			echo ""
			echo "   usage:"
			echo '      wgmExpo <Option> "command 1" "command 2" "command n"'
			echo ""
			echo "   Options:"
			echo "      -h     - help"
			echo "      -v     - version"
			echo "      -s     - Silent mode, no output"
			echo "      -c     - Monocrome output (no ASCII escape characters)"
			echo "      -t     - Display Wireguard ACTIVE Peer Status: each command" 
			echo ""
			echo "   example:"
			echo '      wgmExpo -c "peer wg11 dns=9.9.9.9" "restart wg11"'
			echo '      wgmExpo -ct "livin wg11 192.168.10.53"'
			echo ""
			exit
		;;
		
		"-V"|"-v")
			echo "   wgmExpo Version $version by ZebMcKayhan"
			echo ""
			exit
		;;
		
		"-S"|"-s")
			Silent=1
			shift
		;;
	
		"-C"|"-c" )
			commands="colour off\n"
			shift
		;;
	
		"-T"|"-t" )
			PeerStatus=1
			shift
		;;

		"-tc"|"-tC"|"-Tc"|"-TC"|"-ct"|"-cT"|"-Ct"|"-CT" )
			commands="colour off\n"
			PeerStatus=1
			shift
		;;
		
		*)
			echo "Error, invalid option: $1, use [wgmExpo --help] to view available options"
			exit
		;;
	esac
fi

# Concatenate the command string to wgm:
pad="\n" 
for arg in "$@" 
  do 
    commands="${commands}${arg}${pad}" 
  done
commands="${commands}e"


# Issue command:
if [ $Silent -eq 1 ];then
	echo -e "$commands" | wg_manager >/dev/null 2>&1
else
	if [ $PeerStatus -eq 1 ];then
		echo -e "$commands" | wg_manager | awk 'flag; /Option ==>/{flag=1} /WireGuard ACTIVE/{flag=0}'
	else
		echo -e "$commands" | wg_manager | awk '/Option ==>/{flag=1; next} /WireGuard ACTIVE Peer Status/{flag=0} flag'		
	fi
fi
