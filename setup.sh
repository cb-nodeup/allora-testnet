#!/bin/bash

# Globals
ALLORA_GIT="https://github.com/allora-network/allora-chain.git"
RELEASE="v0.0.4"


source <(curl -s https://raw.githubusercontent.com/nodeup-xyz/utils/main/common.sh)

printLogo

read -p "Enter WALLET name:" WALLET
echo 'export WALLET='$WALLET
read -p "Enter your MONIKER :" MONIKER
echo 'export MONIKER='$MONIKER
read -p "Enter your RPC PORT (default port=26657):" RPC_PORT
echo 'export RPC_PORT='$RPC_PORT

# set vars
echo "export WALLET="$WALLET"" >> $HOME/.bash_profile
echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
echo "export ALLORA_CHAIN_ID="testnet"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:           \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:            \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:          \e[1m\e[32m$ALLORA_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$RPC_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.22.0"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

source <(curl -s https://raw.githubusercontent.com/nodeup-xyz/utils/main/dependencies_install.sh)


