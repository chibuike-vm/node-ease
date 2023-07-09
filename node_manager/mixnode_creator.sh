#!/bin/bash

if [[ -e ~/helpers.sh ]]; then
	source ~/helpers.sh
else
	exit 1
fi

clear && cd ~
declare -l nodeid waddress vps ipprivate ippublic response nodedescribe

printf "\n\nDear %s, Welcome to the Nym Mix Node Setup Automation Program, kindly provide
the following details to automatically set up your prospective Nym mix node.\n" "$USER"

printf "\nEnter the Nym mix node ID you wish to use: "
read nodeid

printf "\nEnter the Nym wallet address you intend to bond your node with: "
read waddress

if [[ ! $waddress =~ ^n1*[a-z0-9] ]] && [[ ${#waddress} != 40 ]]; then
	 waddrvalidatorfeedback
elif [[ $waddress =~ ^n1*[a-z0-9] ]] && [[ ${#waddress} != 40 ]]; then
	 waddrvalidatorfeedback
fi

printf "\nChoosing from the options provided in the parenthesis (aws, google cloud, others)
kindly enter the VPS you are currently using to set up this mix node: "
read vps

setup_node_manager
load_service_file

if [[ $vps == "aws" || $vps == "google cloud" ]]; then
	printf "\nKindly enter your server's Private IPv4 address: "
	read ipprivate

	printf "\nKindly enter your server's Public IPv4 address: "
	read ippublic

	if [[ $nodeid && $waddress && $ipprivate && $ippublic ]]; then
		./nym-mixnode init --id "$nodeid" --host "$ipprivate" --announce-host "$ippublic" --wallet-address "$waddress" > node_info 2>&1
	else
		printf "\nKindly run the script again and provide the correct details as requested.\n\n"
		exit 1
	fi
elif [[ $nodeid && $waddress && $vps == others ]]; then
	./nym-mixnode init --id "$nodeid" --host $(curl ifconfig.me) --wallet-address "$waddress" > node_info 2>&1
else
	printf "\nThe requested details were not provided/correct.\n"
	exit 1
fi

printf "\nWould you like to describe your Nym mix node? Enter (yes or no) to proceed: "
read nodedescribe

if [[ $nodedescribe == "yes" ]]; then
	printf "\nKindly provide the details requested by the following prompts to describe your Nym mix node."
	./nym-mixnode describe --id "$nodeid"
fi

ufw_config

if [[ -e nym-mixnode.service ]]; then
	sudo sed -i "s/noderef/$nodeid/" nym-mixnode.service
	sudo sed -i "s/persona/$USER/" nym-mixnode.service
	sudo mv nym-mixnode.service /etc/systemd/system/
	sudo systemctl enable nym-mixnode.service >> ~/node_manager/logfile.txt 2>&1
	sudo service nym-mixnode start
else
	printf "\n'nym-mixnode.service' file does not exist.\n"
	exit 1
fi

printf "\nCongratulations %s! You did it! \nYou've just successfully created your Nym mix node." "$USER"

printf "\n\nDo you want to see the live session of your Nym mix node? (yes or no): "
read response

if [[ $response == "yes" ]]; then
	printf "\nYou can now signin to your Nym wallet and bond your Nym mix node using the details"
	printf "\ngenerated by this script and stored in the file 'node_info' found inside the"
	printf "\nfolder 'node_manager' present in your home directory.\n"
	printf "\nHere below is the live session of your Nym mix node. Wow! That was fast and smooth!"
	printf "\n\nNB: To close the live session and go back to your terminal prompt, simply type"
	printf "\n    (CTRL c) on your keyboard.\n\n\n"
	journalctl -f -u nym-mixnode.service
elif [[ $response == "no" ]]; then
	printf "\nThat's okay but if you decide to change your mind later, use this command;"
	printf "\njournalctl -f -u nym-mixnode.service\n"
	printf "\nYou can now signin to your Nym wallet and bond your Nym mix node using the details"
	printf "\ngenerated by this script and stored in the file 'node_info' found inside the"
	printf "\nfolder 'node_manager' present in your home directory.\n\n\n"
else
	printf "\nYou entered an invalid response. Please try again.\n\n\n"
fi
