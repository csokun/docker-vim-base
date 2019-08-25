FROM ubuntu:latest

ARG USER_ID=1000
ARG GROUP_ID=1000

# Install dependencies
RUN apt-get update && apt-get upgrade -y \
   && apt-get install -y --no-install-recommends \
      xterm \
      fontconfig \
      git \
      wget \
      curl \
      jq \
      vim \
      tmux \
      libncurses5-dev libncursesw5-dev \
      ca-certificates \
   && apt-get clean -y \
   && apt-get autoremove -y \
   && rm -rf /var/lib/apt/lists/*

ENV HOME /home/vim

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Create container user
RUN groupadd -r -g $GROUP_ID vimuser \
   && useradd -r --no-log-init -u $USER_ID -ms '/bin/bash' vim -g vimuser

USER vim

# Git prompt
RUN wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -qO $HOME/.git-prompt.sh \
   && chmod +x $HOME/.git-prompt.sh \
# git alias
   && git config --global alias.logline "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

ENV LANG en_US.UTF-8
# ENV LC_ALL en_US.UTF-8

COPY dotfiles/bashrc $HOME/.bashrc
COPY dotfiles/tmux.conf $HOME/.tmux.conf

RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm \
   && git clone https://github.com/tmux-plugins/tmux-sensible ~/.tmux/plugins/tmux-sensible \
   && git clone https://github.com/tmux-plugins/tmux-resurrect ~/.tmux/plugins/tmux-resurrect \
   && git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim \
   # Install Powerline Fonts
   && mkdir -p ~/.fonts ~/.config/fontconfig/conf.d \
   && wget -qP ~/.fonts                     https://github.com/Lokaltog/powerline/raw/develop/font/PowerlineSymbols.otf \
   && wget -qP ~/.config/fontconfig/conf.d/ https://github.com/Lokaltog/powerline/raw/develop/font/10-powerline-symbols.conf \
   && fc-cache -vf ~/.fonts/ \
   && echo "set guifont=Droid\\ Sans\\ Mono\\ 10" >> ~/.profile

ENTRYPOINT [ "/entrypoint.sh" ]