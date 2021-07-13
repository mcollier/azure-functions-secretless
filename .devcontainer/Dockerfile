# Find the Dockerfile for mcr.microsoft.com/azure-functions/dotnet:3.0-dotnet3-core-tools at this URL
# https://github.com/Azure/azure-functions-docker/blob/main/host/3.0/buster/amd64/dotnet/dotnet-core-tools.Dockerfile
FROM mcr.microsoft.com/azure-functions/dotnet:3.0-dotnet3-core-tools

# Uncomment following lines If you want to enable Development Container Script
# For more details https://github.com/microsoft/vscode-dev-containers/tree/main/script-library

# Avoid warnings by switching to noninteractive
# ENV DEBIAN_FRONTEND=noninteractive

# # Comment out these lines if you want to use zsh.

# ARG INSTALL_ZSH=true
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# RUN apt-get update && curl -ssL https://raw.githubusercontent.com/microsoft/vscode-dev-containers/main/script-library/common-debian.sh -o /tmp/common-script.sh \
#     && /bin/bash /tmp/common-script.sh "$INSTALL_ZSH" "$USERNAME" "$USER_UID" "$USER_GID" \
#     && rm /tmp/common-script.sh 

# Install system tools
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends apt-utils zip unzip curl bash-completion dnsutils \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Save command line history 
RUN echo "export HISTFILE=/home/$USERNAME/commandhistory/.bash_history" >> "/home/$USERNAME/.bashrc" \
    && echo "export PROMPT_COMMAND='history -a'" >> "/home/$USERNAME/.bashrc" \
    && mkdir -p /home/$USERNAME/commandhistory \
    && touch /home/$USERNAME/commandhistory/.bash_history \
    && chown -R $USERNAME /home/$USERNAME/commandhistory

# Git command prompt and bash completion
RUN git clone https://github.com/magicmonty/bash-git-prompt.git /home/$USERNAME/.bash-git-prompt --depth=1 \
    && echo "if [ -f \"/home/$USERNAME/.bash-git-prompt/gitprompt.sh\" ]; then GIT_PROMPT_ONLY_IN_REPO=1 && source /home/$USERNAME/.bash-git-prompt/gitprompt.sh; fi" >> "/home/$USERNAME/.bashrc" \
    && echo "source /usr/share/bash-completion/bash_completion" >> "/home/$USERNAME/.bashrc" \
    # Alias Powershell
    && echo "alias powershell=pwsh" >> "/home/$USERNAME/.bashrc"    

# Uncomment if not running as root (e.g., vscode).
USER $USERNAME

# Install Azure Bicep CLI for Azure CLI
RUN az bicep install