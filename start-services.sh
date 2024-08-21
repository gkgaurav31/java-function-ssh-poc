#!/bin/sh

sed -i "s/SSH_PORT/$SSH_PORT/g" /etc/ssh/sshd_config

# Start SSH service
service ssh start

# Start the main app using /azure-functions-host/start.sh
exec /azure-functions-host/start.sh
