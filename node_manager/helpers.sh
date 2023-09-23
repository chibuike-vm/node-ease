#!/bin/bash

ufw_allow() {
	sudo ufw allow 22 >>~/node_manager/logfile.txt 2>&1
	sudo ufw allow 1789 >>~/node_manager/logfile.txt 2>&1
	sudo ufw allow 1790 >>~/node_manager/logfile.txt 2>&1
	sudo ufw allow 8000 >>~/node_manager/logfile.txt 2>&1
	sudo ufw allow 80 >>~/node_manager/logfile.txt 2>&1
	sudo ufw allow 443/tcp >>~/node_manager/logfile.txt 2>&1
}

ufw_config() {
	local status_text=($(sudo ufw status))
	local is_active="${status_text:7:9}"

	if [[ $is_active == "active" ]]; then
		sudo ufw enable >>~/node_manager/logfile.txt 2>&1
		ufw_allow
	else
		ufw_allow
	fi

}

setup_node_manager() {
	printf "\nSetting up 'node_manager' folder"

	mkdir ~/node_manager
	mv ~/mnode_auto.sh ~/node_manager/mnode_auto.sh
	cd ~/node_manager

	wget -q https://github.com/nymtech/nym/releases/download/nym-binaries-v1.1.20/nym-mixnode
	chmod u+x nym-mixnode
}

load_service_file() {
	printf "\nDownloading nym-mixnode.service file"
	wget -q https://github.com/chibuike-vm/nym-mix-node-setup-automation/releases/download/v1.0.0-rc.1/nym-mixnode.service
	sudo chown root:root nym-mixnode.service
}
