#!/bin/bash
docker run --rm -it -v $PWD/test:/work \
  --user $(id -u) --env UID=$(id -u) --env GID=$(id -g) csokun/vim-base