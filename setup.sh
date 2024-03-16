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
read -p "Enter chain ID (eg. testnet, edgenet):" ALLORA_CHAIN_ID
echo 'export ALLORA_CHAIN_ID='$ALLORA_CHAIN_ID
read -p "Enter your RPC PORT (default port=26657):" RPC_PORT
echo 'export RPC_PORT='$RPC_PORT

# set vars
echo "export WALLET="$WALLET"" >> $HOME/.bash_profile
echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
echo "export ALLORA_CHAIN_ID="$ALLORA_CHAIN_ID"" >> $HOME/.bash_profile
echo "export RPC_PORT="$RPC_PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:    \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:     \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:   \e[1m\e[32m$ALLORA_CHAIN_ID\e[0m"
echo -e "Node port:  \e[1m\e[32m$RPC_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
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

printGreen "4. Installing allorad binary ..." && sleep 1
# clone repo
cd $HOME
git clone $ALLORA_GIT
cd allora-chain/
git checkout $RELEASE
make install
allorad version

printGreen "5. Configuring and init node..." && sleep 1
GENESIS_URL="https://raw.githubusercontent.com/upshot-tech/networks/main/${ALLORA_CHAIN_ID}/genesis.json"
PEERS_URL="https://raw.githubusercontent.com/upshot-tech/networks/main/${ALLORA_CHAIN_ID}/peers.txt"
BLOCKLESS_API_URL="${BLOCKLESS_API_URL:-https://heads.edgenet.allora.network:8443}"   #! Replace with your blockless API URL
APP_HOME="${APP_HOME:-./data}"
INIT_FLAG="${APP_HOME}/.initialized"
KEYRING_BACKEND=os                             
GENESIS_FILE="${APP_HOME}/config/genesis.json"
DENOM="uallo"

echo "To re-initiate the node, remove the file: ${INIT_FLAG}"
if [ ! -f $INIT_FLAG ]; then
    rm -rf ${APP_HOME}/config

    #* Init node
    allorad --home=${APP_HOME} init ${MONIKER} --chain-id=${ALLORA_CHAIN_ID} --default-denom $DENOM

    #* Download genesis
    rm -f $GENESIS_FILE
    curl -Lo $GENESIS_FILE $GENESIS_URL

    #* Setup allorad client
    allorad --home=${APP_HOME} config node tcp://localhost:${RPC_PORT}
    allorad --home=${APP_HOME} config set client chain-id ${ALLORA_CHAIN_ID}
    allorad --home=${APP_HOME} config set client keyring-backend $KEYRING_BACKEND

    #* Create symlink for allorad config
    ln -sf . ${APP_HOME}/.allorad

    touch $INIT_FLAG
fi
echo "Node is initialized"

# create service file
sudo tee /etc/systemd/system/allorad.service > /dev/null <<EOF
[Unit]
Description=allora node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$APP_HOME
ExecStart=$(which allorad) start --home=${APP_HOME} --moniker=${MONIKER} --rpc.laddr=tcp://0.0.0.0:${RPC_PORT} --grpc.address=0.0.0.0:9090 --minimum-gas-prices=0${DENOM} --log_level=debug --api.address=tcp://0.0.0.0:1317 --api.enable --api.enabled-unsafe-cors

Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "7. Starting node..." && sleep 1
# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable allorad
sudo systemctl restart allorad && sudo journalctl -u allorad -f