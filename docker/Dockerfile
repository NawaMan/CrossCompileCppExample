FROM ubuntu:24.04

# Set non-interactive mode for APT
ENV DEBIAN_FRONTEND=noninteractive

# Copy the setup script into the image
COPY setup-in-docker.sh /tmp/setup-in-docker.sh

# Make it executable and run it
RUN chmod +x /tmp/setup-in-docker.sh && \
    /tmp/setup-in-docker.sh && \
    rm -f /tmp/setup-in-docker.sh

# Set working directory
WORKDIR /app

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/bin/bash"]
