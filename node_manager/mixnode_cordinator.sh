#!/bin/bash

declare -l data_packets

until false
do
	data_packets=$(cat /var/log/mixnode_network_pipe)
	sudo systemctl "$data_packets" nym-mixnode.service
done
