# syntax=docker/dockerfile:1


ARG VARIANT="22"
FROM mcr.microsoft.com/devcontainers/javascript-node:${VARIANT} AS base


# Install some generally useful tools
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
    curl git sqlite3 entr source-highlight rlwrap \
    build-essential \
    ca-certificates \
    sudo \
    adduser \
    fzf \
    unzip

# Ensure keyrings dir is there, for apt-based Docker and Node.js installs
RUN mkdir -p /etc/apt/keyrings

###### REMEMBER TO SET YOUR LOCAL CA ROOT CERTIFICATE ###############
# Copy Zscaler Root CA certificate (the certficate should be in the same directory in which this dockerfile is residing)

COPY ZscalerRootCA.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates


# ---------------------------------------------------------------------
FROM base AS extra
ARG SETUPDIR=/tmp/setup
ARG DEST=/usr/local/bin

RUN mkdir $SETUPDIR && chmod 777 $SETUPDIR


RUN cd $SETUPDIR


# Jq
ARG JQVER=1.7
RUN curl \
  --silent \
  --location \
  --output $DEST/jq \
  --url "https://github.com/jqlang/jq/releases/download/jq-${JQVER}/jq-linux-amd64" \
  && chmod +x $DEST/jq

# Neovim
ARG NEOVIMVER=0.9.5
RUN curl -sL https://github.com/neovim/neovim/releases/download/v${NEOVIMVER}/nvim-linux64.tar.gz \
  | tar xzf - -C /usr --strip-components 1


# ---------------------------------------------------------------------
FROM extra AS npminstalls

# CAP installs
RUN \
  npm install --global \
    @sap/cds-dk \
    @sap/cds-lsp \
    @ui5/cli \
    yo \
    @sapui5/generator-sapui5-templates \
    @sap/generator-base-mta-module \
    @sap/generator-cap-project \
    @sap/generator-fiori \
    @cap-js/cds-typer \
    typescript \
    ts-node \
#  jwt-cli \
#  ramda \
    url-decode-encode-cli \
    yarn 

# ---------------------------------------------------------------------
FROM npminstalls AS coreconfig

USER node
ARG USERHOME=/home/node

# Basic LazyVim config & setup
#RUN \
#    git clone https://github.com/slash-h/lazyvim.git $USERHOME/lazyvim \
#   && chown -R node:node $USERHOME/lazyvim

#RUN \          
#   ln -s $USERHOME/lazyvim/config/nvim/ $USERHOME/.config/nvim                  #Symlink to NVIM config


# Basic LazyVim config & setup
RUN \
    git clone https://github.com/slash-h/lazyvim.git $SETUPDIR/lazyvim \
    && cp -a $SETUPDIR/lazyvim/config/nvim/ $USERHOME/.config/nvim



# ---------------------------------------------------------------------
FROM coreconfig AS finalsetup

RUN cat <<EOBASHRC >> /home/node/.bashrc
# vi mode everywhere
export EDITOR=vi
set -o vi
bind -x '"\C-l": clear'

# vi-mode enhanced cds REPL and core Node.js REPL
# (see https://nodejs.org/api/repl.html#environment-variable-options)
alias cdsr="env NODE_NO_READLINE=1 rlwrap -a cds r"
alias node="env NODE_NO_READLINE=1 rlwrap node"
EOBASHRC

# nicer prompt
RUN echo 'export PS1=${PS1/\$ /\\\\n$ }' >> /home/node/.bashrc

RUN cat <<EOINPUTRC >> /home/node/.inputrc
set editing-mode vi
EOINPUTRC


# Ready!
WORKDIR /home/node

CMD ["bash"]