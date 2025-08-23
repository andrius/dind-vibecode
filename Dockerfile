FROM python:3.13-slim-trixie

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    unzip \
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

# Configure npm for global packages (avoid permission issues)
RUN mkdir -p /root/.npm-global && \
    npm config set prefix '/root/.npm-global'
ENV PATH="/root/.npm-global/bin:$PATH"

# Install Claude Code via npm (correct package name)
RUN npm install -g @anthropic-ai/claude-code

# Create working directory
WORKDIR /workspace

# Start Docker daemon and keep container running
CMD ["sh", "-c", "dockerd-entrypoint.sh & sleep infinity"]