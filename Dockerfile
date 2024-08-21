ARG JAVA_VERSION=8

# Build stage
FROM mcr.microsoft.com/azure-functions/java:4-java$JAVA_VERSION-build AS installer-env

COPY . /src/java-function-app
RUN cd /src/java-function-app && \
    mkdir -p /home/site/wwwroot && \
    mvn clean package && \
    cd ./target/azure-functions/ && \
    cd $(ls -d */|head -n 1) && \
    cp -a . /home/site/wwwroot

# Final stage with SSH enabled
FROM mcr.microsoft.com/azure-functions/java:4-java$JAVA_VERSION-appservice

# Create a group and a non-root user (nonroot)
RUN groupadd -r nonroot && \
    useradd -r -g nonroot -d /home/nonroot -s /sbin/nologin -c "Non-root user" nonroot

# Set appropriate permissions for SSH and start script
RUN chmod +r /etc/profile && \
    chmod 600 /etc/ssh/ssh_host_*_key && \
    chmod 644 /etc/ssh/ssh_host_*_key.pub && \
    chmod -R 755 /etc/ssh && \
    mkdir -p /run/sshd && \
    chmod 755 /run/sshd && \
    chmod 755 /azure-functions-host/start.sh

# Grant read permissions to the host folder /azure-functions-host
RUN chmod -R o+r /azure-functions-host

# Ensure SSH configuration allows root login
RUN sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "root:Docker!" | chpasswd

# Fix SSH key permissions
RUN chmod 600 /etc/ssh/ssh_host_rsa_key && \
    chmod 600 /etc/ssh/ssh_host_ecdsa_key && \
    chmod 600 /etc/ssh/ssh_host_ed25519_key && \
    chmod 644 /etc/ssh/ssh_host_rsa_key.pub && \
    chmod 644 /etc/ssh/ssh_host_ecdsa_key.pub && \
    chmod 644 /etc/ssh/ssh_host_ed25519_key.pub

# Copy a script that will start necessary services and then run the main app
COPY start-services.sh /usr/local/bin/start-services.sh
RUN chmod +x /usr/local/bin/start-services.sh

# Testing - separate RUN instructions
RUN chown nonroot:nonroot /etc/ssh/sshd_config && \
    chown nonroot:nonroot /etc/ssh/ssh_host_* && \
    chmod 600 /etc/ssh/ssh_host_*

ENV SSH_PORT=2222
RUN sed -i "s/SSH_PORT/$SSH_PORT/g" /etc/ssh/sshd_config

USER nonroot

# Set the script as the entry point
ENTRYPOINT ["/usr/local/bin/start-services.sh"]

# Default command to keep the container running
CMD ["sh"]
