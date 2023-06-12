#!/bin/bash

if [[ $HOSTTYPE != "x86_64" ]]; then
	printf "\n\nDear "%s", the 'mnode_auto' binary file cannot be executed because\n" $USER
 	printf "your machine's architecture is not x86_64. Please,consider using the\n"
 	printf "script file designated for your machine architecture.\n\n\n"

  	exit 1
fi 

cd ~
declare -lx nodeid waddress vps ipprivate ippublic response nodedescribe
declare -i count=3

until (( count == 0 )); do
	case $count in 
		3 )
		mkdir ~/node_manager
		mv ~/mnode_auto.sh ~/node_manager
		cd ~/node_manager
		wget -q https://github.com/nymtech/nym/releases/download/nym-binaries-v1.1.20/nym-mixnode
		chmod u+x nym-mixnode;;

		2 )
		wget -q https://github.com/chibuike-vm/nym-mix-node-setup-automation/releases/download/v.1.0.0-rc.1/nym-mixnode.service
		sudo chown root:root nym-mixnode.service;;

		1 )
		wget -q https://github.com/chibuike-vm/nym-mix-node-setup-automation/releases/download/v.1.0.0-rc.1/mnode_auto
		chmod u+x mnode_auto;;
	esac

	count=count-1
done

printf "\n\nDear "%s", Welcome to the Nym Mix Node Setup Automation Program, kindly provide
the following details to automatically set up your prospective Nym mix node.\n" $USER

printf "\nEnter the Nym mix node ID you wish to use: "
read nodeid

printf "\nEnter the nym wallet address you intend to bond your node with: "
read waddress

printf "\nChoosing from the options provided in the parenthesis (aws, google cloud, others)
kindly enter the VPS you are currently using to set up this mix node: "
read vps

if [[ $vps == "aws" || $vps == "google cloud" ]]; then
	printf "\nKindly enter your server's Private IPv4 address: "
	read ipprivate
	
	printf "\nKindly enter your server's Public IPv4 address: "
	read ippublic
		
	if [[ $nodeid && $waddress && $ipprivate && $ippublic ]]; then
		./nym-mixnode init --id $nodeid --host $ipprivate --announce-host $ippublic --wallet-address $waddress > node_details.txt 2>&1
	else
		printf "\nKindly run the script again and this time ensure to provide the correct details requested.\n\n"
		exit 1
	fi
elif [[ $nodeid && $waddress && $vps == "others" ]]; then
	./nym-mixnode init --id $nodeid --host $(curl ifconfig.me) --wallet-address $waddress > node_details.txt 2>&1
	./nym-mixnode describe --id $nodeid
else
	printf "\nThe requested details were not provided/correct.\n"
	exit 1
fi

printf "\nWould you like to describe your Nym mix node? Enter (yes or no) to proceed: "
read nodedescribe

if [[ $nodedescribe == "yes" ]]; then
	printf "\nKindly provide the details requested by the following prompts to describe your Nym mix node."
	./nym-mixnode describe --id $nodeid
fi

if [[ -e mnode_auto ]]; then
	echo "y" > ~/node_manager/reply.txt
	~/node_manager/mnode_auto < ~/node_manager/reply.txt >> ~/node_manager/logfile.txt
else
	printf "\nmnode_auto binary file does not exist!\n"
	exit 1
fi

if [[ -e nym-mixnode.service ]]; then
	sudo sed -i "s/noderef/$nodeid/" ~/node_manager/nym-mixnode.service
	sudo sed -i "s/persona/$USER/" ~/node_manager/nym-mixnode.service
	sudo mv ~/node_manager/nym-mixnode.service /etc/systemd/system/
	sudo systemctl enable nym-mixnode.service >> ~/node_manager/logfile.txt 2>&1
 	sudo service nym-mixnode start
else	
	printf "\nnym-mixnode.service file does not exist.\n"
	exit 1
fi

printf "\nCongratulations "%s"! You did it! \nYou've just successfully created your Nym mix node." $USER

printf "\n\nDo you want to see the live session of your Nym mix node? (yes or no): "
read response

if [[ $response == "yes" ]]; then
	printf "\nHere's the live session of your Nym mix node.\n\n\n"
	journalctl -f -u nym-mixnode.service 
elif [[ $response == "no" ]]; then 
	printf "\nThat's okay but if you decide to change your mind later, use this command;"
	printf "\njournalctl -f -u nym-mixnode.service\n\n\n"
	exit 1
else
	printf "\nYou entered an invalid response. Please try again.\n\n\n"
fi
