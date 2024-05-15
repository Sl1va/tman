# install system deps
sudo apt install -y lua5.1 luarocks
luarocks install luaposix

# install util
git clone https://github.com/roachme/tman.git

# make structure
mkdir -p ~/.config/tman

cat << EOF >> ~/.config/tman/config
Install ~/tman
Base ~/trash/tman
EOF
echo "source ${HOME}/tman/shell.sh" >> ~/.zshrc

echo "update shell session"
