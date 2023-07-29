declare -a portsarray=("22" "80" "443/tcp" "1789" "1790" "8000")

ufw_allow()
{
	for ports in ${portsarray[*]}; do
		sudo ufw allow "$ports" >> ~/node_manager/logfile.txt 2>&1
	done
}

ufw_config()
{
	local ufw_status_output="$(sudo ufw status)"
	local ufw_status="${ufw_status_output:8:6}"

	if [[ $ufw_status == "active" ]]; then
		sudo ufw status > ~/node_manager/ufw_status_report.txt 2>&1
		ufw_allow
	else
		echo 'y' > affirm.txt
		sudo ufw enable < affirm.txt >> ~/node_manager/logfile.txt 2>&1
		ufw_allow
		rm affirm.txt
	fi
}

setup_node_manager()
{
	if [[ ! -d ~/node_manager ]]; then
		mkdir ~/node_manager
	fi

	cd ~/node_manager

	if [[ ! -e nym-mixnode ]]; then
		printf "\nSetting up 'node_manager' folder."
		wget -q https://github.com/nymtech/nym/releases/download/nym-binaries-v1.1.20/nym-mixnode
		chmod u+x nym-mixnode
	fi
}

load_service_file()
{
	if [[ ! -e nym-mixnode.service ]]; then
		printf "\n\nDownloading 'nym-mixnode.service' file.\n"
		wget -q https://github.com/chibuike-vm/nym-mix-node-setup-automation/releases/download/v2.0.0-rc.2/nym-mixnode.service
		sudo chown root:root nym-mixnode.service
	fi
}

ufw_config_rm()
{
	declare -i ecount=0

	while (( ecount < ${#portsarray[*]} )); do
		if [[ -e ~/node_manager/ufw_status_report.txt ]]; then
			if ! grep -w "${portsarray[$ecount]}" ~/node_manager/ufw_status_report.txt >> ~/node_manager/logfile.txt 2>&1; then
					sudo ufw delete allow "${portsarray[$ecount]}" >> ~/node_manager/logfile.txt 2>&1
			fi
		else
			sudo ufw delete allow "${portsarray[$ecount]}" >> ~/node_manager/logfile.txt 2>&1

			if (( ecount == ${#portsarray[*]}-1 )); then
				sudo ufw disable >> ~/node_manager/logfile.txt 2>&1
			fi
		fi

		ecount=ecount+1
	done
}

destroy_mixnode()
{
	if [[ -d ~/node_manager && -d ~/.nym ]]; then
		sudo systemctl disable --now nym-mixnode.service >> ~/node_manager/logfile.txt 2>&1

		ufw_config_rm
		rm -rf ~/.nym
		rm -rf ~/node_manager
		sudo rm /etc/systemd/system/nym-mixnode.service
		sudo systemctl daemon-reload
		rm ~/mixnode_creator.sh
	fi
}

destroy_mixnode_ipc()
{
	if [[ -d ~/ipc_dir ]]; then
		sudo systemctl disable --now mixnode_cordinator.service >> ~/ipc_dir/logfile.txt 2>&1

		sudo rm /var/log/mixnode_network_pipe
		sudo rm -rf /root/bin
		sudo rm /etc/systemd/system/mixnode_cordinator.service
		sudo systemctl daemon-reload
		rm -rf ~/ipc_dir

		rm ~/helpers.sh
		rm ~/mixnode_packager.sh
	fi
}

nodeid_input()
{
	printf "\nEnter the Nym mix node ID you wish to use: "
	read nodeid

	if [[ $nodeid ]]; then
		return 0
	fi

	return 1
}

waddress_input()
{
	printf "\nEnter the Nym wallet address you intend to bond your node with: "
	read waddress

	if [[ $waddress =~ ^n1*[a-z0-9] ]] && [[ ${#waddress} == 40 ]]; then
		return 0
	fi

	return 1
}

vps_input()
{
	printf "\nChoosing from the options provided in the parenthesis (aws, google cloud, others)"
	printf "\nkindly enter the VPS you are currently using to set up this mix node: "
	read vps

	if [[ $vps == "aws" || $vps == "google cloud" || $vps == "others" ]]; then
		return 0
	fi

	return 1
}

ip_address_input()
{
	if [[ $vps == "aws" || $vps == "google cloud" ]]; then
		declare -l ip_check

		printf "\nKindly enter your server's Private IPv4 address: "
		read ipprivate

		printf "\nKindly enter your server's Public IPv4 address: "
		read ippublic

 		(ping -c1 $ipprivate; echo $?) > ~/caticat 2>&1
		ip_check=$(sed -n '$p' caticat)

		if [[ $ippublic && $ip_check == 0 ]]; then
			return 0
		fi

		return 2
	fi
}

nodedescribe_input()
{
	printf "\nWould you like to describe your Nym mix node? Enter (yes or no) to proceed: "
	read nodedescribe

	if [[ $nodedescribe == "yes" || $nodedescribe == "no" ]]; then
		return 0
	fi

	return 1
}

response_input()
{
	printf "\nDo you want to see the live session of your Nym mix node? (yes or no): "
	read response

	if [[ $response == "yes" || $response == "no" ]]; then
		return 0
	fi

	return 1
}

verifyaction_input()
{
	printf "\nThis option that you chose will destroy your Nym Mix Node including your private keys."
	printf "\nDo you still want to continue? Enter (yes or no) to proceed: "
	read verifyaction

	if [[ $verifyaction == "yes" || $verifyaction == "no" ]]; then
		return 0
	fi

	return 1
}

mixnode_id_checker()
{
	declare -l verifynodeid verifyaction
	verifyaction="$1"

	if [[ $verifyaction == "yes" ]]; then
		printf "\nKindly enter your mix node ID to continue (for security reasons, it won't show on the"
		printf "\nscreen but type it anyway): "
		read -s verifynodeid

		printf "\n"

		if [[ $verifynodeid ]] && grep -w "$verifynodeid" /etc/systemd/system/nym-mixnode.service >> ~/ipc_dir/logfile.txt 2>&1; then
			return 0
		fi

		return 1
	elif [[ $verifyaction == "no" ]]; then
		printf "\nNym mix node destroy operation was successfully aborted!\n\n"
		exit 1
	fi
}

input_manager()
{
	func_arg="$1"
	declare -i j input_func_ret_value

	if [[ -e ~/caticat ]]; then
		rm ~/caticat
	fi

	for ((j=0; j<=3; j++)); do
		$func_arg
		func_arg_ret_value=$(echo $?)

		if (( func_arg_ret_value == 0 )); then
			return 0
		elif (( j <= 2 )); then
			printf "${error_msgs[func_arg_ret_value]}"
		fi
	done

	printf "\nKindly run the script again and then ensure to enter the correct details as requested."
	printf "\nThank you.\n\n"
	exit 1
}

