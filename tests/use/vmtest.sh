# install system deps
sudo apt update
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

touch ~/.config/tman/config

echo "source ${HOME}/tman/tman.sh" >> ~/.zshrc

echo "update shell session"
