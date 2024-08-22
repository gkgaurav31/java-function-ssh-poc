#!/bin/sh

# Start SSH service
echo "Docker!" | su -c "service ssh start"

export DOTNET_USE_POLLING_FILE_WATCHER=true

if [ -z "$PORT" ]; then
  export ASPNETCORE_URLS=http://*:8080
else
  export ASPNETCORE_URLS=http://*:$PORT
fi

# Install ca-certificates
. /opt/startup/install_ca_certificates.sh

if [ -z "$SSH_PORT" ]; then
  export SSH_PORT=2222
fi

if [ "$APPSVC_REMOTE_DEBUGGING" = "TRUE" ]; then
    export languageWorkers__node__arguments="--inspect=0.0.0.0:$APPSVC_TUNNEL_PORT"
    export languageWorkers__python__arguments="-m ptvsd --host localhost --port $APPSVC_TUNNEL_PORT"
fi

# Get environment variables to show up in SSH session
eval "$(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/')"

if [ -f /azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost ]; then
    /azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost
else
    dotnet /azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost.dll
fi
