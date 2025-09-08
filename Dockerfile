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

# Configure PATH for developer user
RUN echo 'export PATH="/home/developer/.local/bin:$PATH"' >> /home/developer/.bashrc

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create and configure .local directory structure for developer user
RUN mkdir -p /home/developer/.local/bin /home/developer/.local/lib && \
  chown -R developer:developer /home/developer/.local

# Copy bin directory to developer's local bin
COPY bin/ /home/developer/.local/bin/
RUN chown -R developer:developer /home/developer/.local/bin && \
  chmod +x /home/developer/.local/bin/*

# Switch to developer user for all operations
USER developer

# Configure npm for developer user to install in local space
RUN npm config set prefix '/home/developer/.local'

# Install vibecoding tools as developer user
RUN npm install -g @anthropic-ai/claude-code && \
  npm install -g @qwen-code/qwen-code && \
  npm install -g @google/gemini-cli && \
  npm install -g @charmland/crush && \
  npm install -g opencode-ai \
  npm install -g @just-every/code \
  npm install -g @openai/codex

# Install Python-based vibecoding tools as developer user
RUN pip install --user llm llm-anthropic llm-gemini

# Set PATH environment variable so all tools are accessible in all shells
ENV PATH="/home/developer/.local/bin:${PATH}"

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
