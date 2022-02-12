#!/bin/sh
version=0.4
# wgmExpo - script for executing commands inside wg_manager from the shell
# by ZebMcKayhan

# Config, Initialization:
#StartTag="Option ==>"
#EndTag="WireGuard ACTIVE Peer Status"
Selector="Normal" # Defines which command to use if no option is given.
commands="" 

# Zero input gives Version splash:
if [ "$1" = "" ];then
echo "   wgmExpo Version $version by ZebMcKayhan"
echo "      wgmExpo --help for usage info"
echo ""
exit
fi

# Process <Options>
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
			echo "      -h       - help"
			echo "      -v       - version"
			echo "      -s       - Silent mode, no output"
			echo "      -c       - Monocrome output (no ASCII escape characters)"
			echo "      -t       - Display Wireguard ACTIVE Peer Status: each command" 
			echo "      -e       - Expose all display output (no filtering)"
		 echo "      -remove  - Remove wgmExpo"
                        echo ""
			echo "   example:"
			echo '      wgmExpo -c "peer wg11 dns=9.9.9.9" "restart wg11"'
			echo '      wgmExpo -ct "livin wg11 192.168.10.53"'
			echo ""
			exit
		;;
		
		"-V"|"-v")
			echo "   wgmExpo Version $version"
			echo ""
			exit
		;;
		
		"-S"|"-s")
			Selector="Silent"
			shift
		;;
	
		"-C"|"-c" )
			commands="colour off\n"
			shift
		;;
	
		"-T"|"-t" )
			Selector="Status"
			shift
		;;

		"-tc"|"-tC"|"-Tc"|"-TC"|"-ct"|"-cT"|"-Ct"|"-CT" )
			commands="colour off\n"
			Selector="Status"
			shift
		;;

		"-E"|"-e" )
			Selector="Full"
			shift
		;;

		"-ec"|"-eC"|"-Ec"|"-EC"|"-ce"|"-cE"|"-Ce"|"-CE" )
			commands="colour off\n"
			Selector="Full"
			shift
		;;		

  "-install")
  rm /opt/bin/wgmExpo 2>/dev/null
  ln -s /jffs/addons/wireguard/wgmExpo.sh /opt/bin/wgmExpo 2>/dev/null

  echo "   wgmExpo Version $version by ZebMcKayhan"
  echo ""
  echo "   Wrapper installed"
  exit
  ;;

  "-remove")
  rm /opt/bin/wgmExpo
  rm /jffs/addons/wireguard/wgmExpo.sh
  echo "   wgmExpo Version $version by ZebMcKayhan"
  echo ""
  echo "   Wrapper removed"
  exit
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
commands="${commands}e" #end with "e" to exit wgm


# Issue command:
case "$Selector" in
	"Full")
		echo -e "$commands" | wg_manager
	;;
	
	"Silent")
		echo -e "$commands" | wg_manager >/dev/null 2>&1
	;;
	
	"Status")
		echo -e "$commands" | wg_manager | awk 'flag; /Option ==>/{flag=1} /WireGuard ACTIVE Peer Status/{flag=0}'
	;;
	
	"Normal")
		echo -e "$commands" | wg_manager | awk '/Option ==>/{flag=1; next} /WireGuard ACTIVE Peer Status/{flag=0} flag'
	;;
	
	*)
		echo "Error, invalid command, something went wrong"
		echo ""
	;;
	
esac
