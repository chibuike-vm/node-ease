ufw_allow()
{
	declare -a portsarray=("22" "80" "443/tcp" "1789" "1790" "8000")
	declare -i  ecount=0

	while (( ecount < ${#portsarray[*]} )); do
		sudo ufw allow "${portsarray[$ecount]}" >> ~/node_manager/logfile.txt 2>&1
		ecount=ecount+1
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
	declare -a portsarray=("22" "80" "443/tcp" "1789" "1790" "8000")
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

mixnode_id_checker()
{
	declare -l verifynodeid verifyaction
	verifyaction="$1"

	if [[ $verifyaction == "yes" ]]; then
		printf "\nKindly enter your mix node ID to continue (for security, it won't show on the screen"
		printf "\nbut type it anyway): "
		read -s verifynodeid

		verifynodeid="${verifynodeid:-yr790pz8asw}"

		if grep -w "$verifynodeid" /etc/systemd/system/nym-mixnode.service >> ~/ipc_dir/logfile.txt 2>&1; then
			return 0
		else
			printf "\n\nOps! Invalid Nym Mix Node ID!\nKindly provide the valid ID and try again.\n\n"
			return 1
		fi
	elif [[ $verifyaction == "no" ]]; then
		printf "\nNym mix node destroy operation was successfully aborted!\n\n"
		return 1
	else
		printf "\nInvalid response! Kindly try again.\n\n"
		exit 1
	fi
}

waddrvalidatorfeedback()
{
	printf "\nOps! Invalid Nym wallet address!"
	printf "\nKindly run the script again and provide the correct details as requested.\n\n"
	exit 1
}
