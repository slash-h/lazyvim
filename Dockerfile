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
    fd-find \
    ripgrep \ 
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
ARG NEOVIMVER=0.11.2
RUN curl -sL https://github.com/neovim/neovim/releases/download/v${NEOVIMVER}/nvim-linux-x86_64.tar.gz \
  | tar xzf - -C /usr --strip-components 1

ARG TMUXVER=3.3a
RUN cd $SETUPDIR \
  && curl -fsSL "https://github.com/tmux/tmux/releases/download/$TMUXVER/tmux-$TMUXVER.tar.gz" \
  | tar -xzf - \
  && cd "tmux-$TMUXVER" && ./configure && make && make install


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
RUN \
    git clone https://github.com/slash-h/dotfiles.git $USERHOME/dotfiles 
#   && chown -R node:node $USERHOME/lazyvim

#Symlink to NVIM config
RUN ln -s $USERHOME/dotfiles/config/nvim/ $USERHOME/.config/nvim                 
#Symlink to TMUX config
RUN ln -s $USERHOME/dotfiles/config/tmux/tmux.conf $USERHOME/.tmux.conf          


# Install TMUX Package Manager for supporting TMUX plugins
RUN git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm


RUN sudo rm -rf $SETUPDIR/

# ---------------------------------------------------------------------
FROM coreconfig AS finalsetup

#Set Terminal environment to use xterm-256 color scheme (this is required by tmux for correct rendering of symbols)
ENV TERM xterm-256color
ENV LANG us_EN.UTF-8

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
RUN echo '#Uncomment below lines to overwrite PS1 with a fancy chevrons prompt' >> /home/node/.bashrc
RUN echo '#source'  ${USERHOME}'/dotfiles/config/bash.d/functions.sh' >> /home/node/.bashrc
RUN echo "#PS1='\$(cecho \"\w\" cyan) \$(git_info \"on \") \$(chevrons) ' "  >> /home/node/.bashrc
RUN echo '  ' >> /home/node/.bashrc
RUN echo 'export PS1=${PS1/\$ /\\\\n$ }' >> /home/node/.bashrc


RUN cat <<EOINPUTRC >> /home/node/.inputrc
set editing-mode vi
EOINPUTRC


# Ready!
WORKDIR /home/node

CMD ["bash"]