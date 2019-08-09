FROM alpine:latest as builder

WORKDIR /tmp

# Install dependencies
RUN apk add --no-cache \
    build-base \
    ctags \
    git \
    libx11-dev \
    libxpm-dev \
    libxt-dev \
    make \
    curl \
    jq \
    ncurses-dev \
    python \
    python-dev

# Build vim from git source
RUN git clone https://github.com/vim/vim \
   && cd vim \
   && RELEASE=$(curl --silent https://api.github.com/repos/vim/vim/tags | jq -r ".[0].name") \
   && git checkout $RELEASE -b $RELEASE \
   && ./configure \
      --disable-gui \
      --disable-netbeans \
      --enable-multibyte \
      --enable-pythoninterp \
      --with-features=big \
      --with-python-config-dir=/usr/lib/python2.7/config \
   && make install
 
FROM alpine:latest

RUN apk add --no-cache \
   bash \
   fontconfig \
   git \
   diffutils \
   libice \
   libsm \
   libx11 \
   libxt \
   ncurses \
   tmux

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

COPY --from=builder /usr/local/bin/ /usr/local/bin
COPY --from=builder /usr/local/share/vim/ /usr/local/share/vim/
# NOTE: man page is ignored

COPY dotfiles/bashrc /root/.bashrc
COPY dotfiles/tmux.conf /root/.tmux.conf
COPY dotfiles/vimrc /root/.vimrc

RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm \
   && git clone https://github.com/tmux-plugins/tmux-sensible ~/.tmux/plugins/tmux-sensible \
   && git clone https://github.com/tmux-plugins/tmux-resurrect ~/.tmux/plugins/tmux-resurrect \
   && git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim \
# Install Powerline Fonts
   && mkdir -p ~/.fonts ~/.config/fontconfig/conf.d \
   && wget -qP ~/.fonts                     https://github.com/Lokaltog/powerline/raw/develop/font/PowerlineSymbols.otf \
   && wget -qP ~/.config/fontconfig/conf.d/ https://github.com/Lokaltog/powerline/raw/develop/font/10-powerline-symbols.conf \
   && fc-cache -vf ~/.fonts/ \
   && echo "set guifont=Droid\\ Sans\\ Mono\\ 10" >> ~/.profile \
# Install VIM plugins
   && echo | echo | vim +PluginInstall +qall

COPY entrypoint.sh /

# Git prompt
RUN chmod +x /entrypoint.sh \
   && wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -qO /root/.git-prompt.sh \
   && chmod +x /root/.git-prompt.sh

WORKDIR /work

ENTRYPOINT ["/entrypoint.sh"]