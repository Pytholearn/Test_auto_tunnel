#!/bin/bash

# [Previous color definitions and other functions remain unchanged]

install_tunnel() {
    nebula_menu "| 1  - Multiple Iran servers to Kharej \n| 2  - Kharej to Iran \n| 0  - Exit"

    read -p "Enter option number: " setup

    case $setup in
    1)
        read -p "How many Iran servers: " iran_count
        read -p "Enter Kharej IP: " kharej_ip
        for ((i=1; i<=iran_count; i++))
        do
            iran_setup $i "$kharej_ip"
        done
        ;;
    2)
        read -p "How many Kharej servers: " kharej_count
        for ((i=1; i<=kharej_count; i++))
        do
            kharej_setup $i
        done
        ;;
    0)
        echo -e "${GREEN}Exiting program...${NC}"
        exit 0
        ;;
    *)
        echo "Not valid"
        ;;
    esac
}

iran_setup() {
    local server_num=$1
    local kharej_ip=$2

    echo -e "${YELLOW}Setting up Iran server $server_num${NC}"
    
    read -p "Enter Iran IP for server $server_num: " iran_ip
    read -p "Enter IPv6 Local for server $server_num: " ipv6_local
    
    cat <<EOL > /etc/netplan/mramini-$server_num.yaml
network:
  version: 2
  tunnels:
    tunnel0858-$server_num:
      mode: sit
      local: $iran_ip
      remote: $kharej_ip
      addresses:
        - $ipv6_local::1/64
EOL
    netplan_setup
    sudo netplan apply

    start_obfs4

    cat <<EOL > /root/connectors-$server_num.sh
ping $ipv6_local::2
EOL

    chmod +x /root/connectors-$server_num.sh

    screen -dmS connectors_session_$server_num bash -c "/root/connectors-$server_num.sh"

    echo "Iran Server $server_num setup complete."
    echo -e "####################################"
    echo -e "# Your IPv6 :                      #"
    echo -e "#  $ipv6_local::1                  #"
    echo -e "####################################"
}

kharej_setup() {
    echo -e "${YELLOW}Setting up Kharej server $1${NC}"
    
    read -p "Enter Iran IP    : " iran_ip
    read -p "Enter Kharej IP  : " kharej_ip
    read -p "Enter IPv6 Local : " ipv6_local
    
    cat <<EOL > /etc/netplan/mramini-$1.yaml
network:
  version: 2
  tunnels:
    tunnel0858-$1:
      mode: sit
      local: $kharej_ip
      remote: $iran_ip
      addresses:
        - $ipv6_local::2/64
EOL
    netplan_setup
    sudo netplan apply

    start_obfs4

    cat <<EOL > /root/connectors-$1.sh
ping $ipv6_local::1
EOL

    chmod +x /root/connectors-$1.sh

    screen -dmS connectors_session_$1 bash -c "/root/connectors-$1.sh"

    echo "Kharej Server $1 setup complete."
    echo -e "####################################"
    echo -e "# Your IPv6 :                      #"
    echo -e "#  $ipv6_local::2                  #"
    echo -e "####################################"
}

# [Rest of the script remains unchanged: check_core_status, netplan_setup, unistall, loader, etc.]