PROG="tman"

# install util
git clone https://github.com/roachme/tman.git $PROG

cd "$PROG" || return 1
./install.sh -i
