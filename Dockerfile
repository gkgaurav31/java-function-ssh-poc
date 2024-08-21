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

# Create the /run/sshd directory first
RUN mkdir -p /run/sshd && \
    chmod 755 /run/sshd

# Create necessary directories and set permissions
RUN mkdir -p /run/sshd && \
    chmod 755 /run/sshd && \
    chmod +r /etc/profile && \
    chmod -R 755 /etc/ssh /azure-functions-host && \
    chmod 600 /etc/ssh/ssh_host_*_key && \
    chmod 644 /etc/ssh/ssh_host_*_key.pub && \
    chmod -R o+r /azure-functions-host


# Copy a script that will start necessary services and then run the main app
COPY start-services.sh /usr/local/bin/start-services.sh
RUN chmod +x /usr/local/bin/start-services.sh

# Set the script as the entry point
ENTRYPOINT ["/usr/local/bin/start-services.sh"]

# Default command to keep the container running
CMD ["sh"]
