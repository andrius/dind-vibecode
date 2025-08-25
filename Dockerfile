FROM python:3.13-slim-trixie

# Accept build arguments for user UID/GID
ARG USER_UID=1000
ARG USER_GID=1000

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    unzip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs

# Create developer user and group with specified UID/GID
RUN groupadd -g $USER_GID developer && \
    useradd -u $USER_UID -g $USER_GID -m -s /bin/bash developer && \
    usermod -aG sudo developer && \
    usermod -aG docker developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure npm for global packages as root first
RUN mkdir -p /opt/npm-global && \
    npm config set prefix '/opt/npm-global' && \
    chmod -R 755 /opt/npm-global
ENV PATH="/opt/npm-global/bin:$PATH"

# Install Claude Code via npm (correct package name)
RUN npm install -g @anthropic-ai/claude-code

# Configure PATH for developer user
RUN echo 'export PATH="/home/developer/.local/bin:/opt/npm-global/bin:$PATH"' >> /home/developer/.bashrc

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy bin directory to developer's local bin
COPY bin/ /home/developer/.local/bin/
RUN chown -R developer:developer /home/developer/.local/bin && \
    chmod +x /home/developer/.local/bin/*

# Switch to developer user for all operations
USER developer

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]