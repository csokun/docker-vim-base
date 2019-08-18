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

# ***************************************
# Build vim from git source
# ***************************************
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

# ***************************************
# Runtime
# ***************************************
FROM alpine:latest

COPY --from=builder /usr/local/bin/ /usr/local/bin
COPY --from=builder /usr/local/share/vim/ /usr/local/share/vim/
# NOTE: man page is ignored

RUN apk add --no-cache \
   curl \
   jq \
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

ARG USER_ID
ARG GROUP_ID
ENV HOME /home/vim

COPY entrypoint.sh /
# Git prompt
RUN mkdir -p $HOME \
   && chmod +x /entrypoint.sh \
   && wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -qO $HOME/.git-prompt.sh \
   && chmod +x $HOME/.git-prompt.sh \
# git alias
   && git config --global alias.logline "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Create container user
RUN addgroup -g 1000 -S vimuser && \
   adduser -u 1000 -D -s '/bin/bash' -S vim -G vimuser
        
USER vim

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

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

ENTRYPOINT [ "/bin/bash", "-c" ]
CMD [ "TERM=xterm-256color tmux $@" ]