#!/bin/bash

cd ~

if [[ ! -p /var/log/mixnode_network_pipe ]]; then
	wget -q https://github.com/chibuike-vm/nym-mix-node-setup-automation/releases/download/v2.0.0-rc.2/mixnode_cordinator.sh
	chmod u+x mixnode_cordinator.sh
	sudo mkdir /root/bin/ && sudo mv ~/mixnode_cordinator.sh /root/bin/
	mkdir ~/ipc_dir
	sudo mkfifo /var/log/mixnode_network_pipe
	sudo chmod u+rw,g+rw,o+rw /var/log/mixnode_network_pipe
fi

if [[ ! -e /etc/systemd/system/mixnode_cordinator.service ]]; then
	sudo cat > mixnode_cordinator.service <<END
	[Unit]
	Description=A Nym Mix Node Cordinator IPC Service
	After=sshd.service

	[Service]
	Type=simple
	ExecStart=/root/bin/mixnode_cordinator.sh
	ExecStop=/bin/kill \$MAINPID
	Restart=on-failure
	KillMode=process

	[Install]
	WantedBy=multi-user.target
END

	sudo mv ~/mixnode_cordinator.service /etc/systemd/system/
	sudo systemctl enable --now mixnode_cordinator.service >> ~/ipc_dir/logfile.txt 2>&1
fi

if [[ ! -e ~/helpers.sh ]]; then
	wget -q https://github.com/chibuike-vm/nym-mix-node-setup-automation/releases/download/v2.1.0-rc.2/helpers.sh
fi

source helpers.sh

if [[ ! -e ~/mixnode_creator.sh ]]; then
	wget -q https://github.com/chibuike-vm/nym-mix-node-setup-automation/releases/download/v2.1.0-rc.2/mixnode_creator.sh
	chmod u+x ~/mixnode_creator.sh
fi

printf "\nDear %s, Welcome To Nym Mix Node Automated Package Manager!\n" "$USER"
printf "\nChoose from the options below on what you want to do.\n"

printf "\n1. Create a Nym mix node."
printf "\n2. Stop an existing Nym mix node."
printf "\n3. Restart an existing Nym mix node."
printf "\n4. View the live session of an existing Nym mix node."
printf "\n5. Destroy an existing Nym mix node.\n\n"

read -p "Enter either 1, 2, 3, 4 or 5: " action

case "$action" in
	1 )
	if [[ ! -e /etc/systemd/system/nym-mixnode.service ]]; then
		if [[ -e ~/mixnode_creator.sh ]]; then
			~/mixnode_creator.sh
		fi
	else
		printf "\nSorry, you already have a Nym mix node configured!\n\n"
		exit 1
	fi;;

	2 )
	verifyaction=${verifyaction-yes}
	input_manager "mixnode_id_checker $verifyaction"

	if (( $? == 0 )); then
		if sudo systemctl status nym-mixnode.service | grep -w "running" >> ~/ipc_dir/logfile.txt 2>&1; then
			echo 'stop' > /var/log/mixnode_network_pipe
			printf "\nNym mix node stop operation was successful!\n\n"
		else
			printf "\nSorry, your Nym mix node is already stopped.\n\n"
		fi
	fi;;

	3 )
	verifyaction=${verifyaction-yes}
	input_manager "mixnode_id_checker $verifyaction"

	if (( $? == 0 )); then
		echo 'restart' > /var/log/mixnode_network_pipe
		printf "\nNym mix node restart operation was successful!\n\n"
	fi;;

        4 )
        verifyaction=${verifyaction-yes}
        input_manager "mixnode_id_checker $verifyaction"

        if (( $? == 0 )); then
                clear
                printf "\nNB: To leave the live session of your Nym mix node and go back to your terminal prompt,\n"
                printf "    kindly type 'CTRL c' on your keyboard.\n\n\n"
                sleep 3
                journalctl -fu nym-mixnode.service
        fi;;

	5 )
	input_manager verifyaction_input
	input_manager "mixnode_id_checker $verifyaction"

	if (( $? == 0 )); then
		destroy_mixnode
		destroy_mixnode_ipc
		printf "\nNym mix node destroy operation was successful!\n\n"
	fi;;

	* )
	printf "\nInvalid input! Kindly try again.\n\n"
	exit 1;;
esac

