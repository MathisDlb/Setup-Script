#!/bin/bash

output(){
    echo -e '\e[36m'$1'\e[0m';
}

version=v1

#Change your company name accordingly.
company="Mathis"

preflight(){
    output "Setup Script ${version}"

    if [ "$EUID" -ne 0 ]; then
        output "Please run as root."
        exit 1
    fi

    if [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
        dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
    else
        exit 2
    fi
    output "OS: $lsb_dist $dist_version detected."
    output ""

    if [ $lsb_dist != "fedora" ] && [ $lsb_dist != "centos" ] && [ $lsb_dist != "rhel" ] && [ $lsb_dist != "cloudlinux" ] && [ $lsb_dist != "ubuntu" ] && [ $lsb_dist != "debian" ]; then
        output "Unsupported Distribution."
        exit 3
    fi 
}

update_packages(){
    if [ $lsb_dist == "fedora" ] || [ $lsb_dist == "centos" ] || [ $lsb_dist == "rhel" ] || [ $lsb_dist == "cloudlinux" ]; then
        yum -y upgrade
        yum -y autoremove
        yum -y install curl
    elif [ $lsb_dist == "ubuntu" ] || [ $lsb_dist == "debian" ]; then
        apt update
        apt -y upgrade
        apt -y autoremove
        apt -y autoclean
        apt y install curl
    fi    
}

activate_iptables(){
    output "Activate basic IPtables rules?"
    output "[1] Yes (Recommended)."
    output "[2] No."
    read iptableschoice
    case $iptableschoice in
    1 ) output "Activating Iptables"
        curl -sSL https://raw.githubusercontent.com/tommytran732/Anti-DDOS-Iptables/master/iptables-no-prompt.sh | bash
        block_icmp
        ;;
    
    2 ) output "Skipping rules..."
        ;;

    * ) output "You did not enter a valid selection."
        block_icmp
    esac    
}

activate_fail2ban(){
    output "Set Fail2Ban up to protect sshd?"
    output "[1] Yes."
    output "[2] No."
    read f2b 
    case $f2b in 
    1)  output "Securing SSH login with fail2ban"
        if [ $lsb_dist == "fedora" ] || [ $lsb_dist == "centos" ] || [ $lsb_dist == "rhel" ] || [ $lsb_dist == "cloudlinux" ]; then
            yum -y install fail2ban
        elif [ $lsb_dist == "ubuntu" ] || [ $lsb_dist == "debian" ]; then
            apt -y install fail2ban
        fi   
        systemctl enable fail2ban
        bash -c 'cat > /etc/fail2ban/jail.local' <<-'EOF'
[DEFAULT]
# Ban hosts for ten hours:
bantime = 36000
# Override /etc/fail2ban/jail.d/00-firewalld.conf:
banaction = iptables-multiport
[sshd]
enabled = true
EOF
        service fail2ban restart
        ;;
    2)  output "Skipping..."
        ;;
    * ) output "You did not enter a valid selection."
        activate_fail2ban
    esac
}

whitelist_cloudflare(){
    output "Do you want to whitelist only Cloudflare (cloudflare.com)'s IPs on your selection of ports?"
    output "[1] Yes."
    output "[2] No."
    read cloudflare
    case $cloudflare in
    1)  bash <(curl -sSL https://raw.githubusercontent.com/tommytran732/Cloudflare-IPWhitelist/master/cloudflare.sh)
        ;;
    2) output "Skipping..."
        ;;
    * ) output "You did not enter a valid selection."
        whitelist_cloudflare
    esac
}

whitelist_tcpshield(){
    output "Do you want to whitelist only TCPShield's IPs on your selection of ports?"
    output "[1] Yes."
    output "[2] No."
    read tcpshield
    case $tcpshield in
    1)  bash <(curl -sSL https://raw.githubusercontent.com/tommytran732/TCPShield-IPWhitelist/master/tcpshield.sh)
        ;;
    2) output "Skipping..."
        ;;
    * ) output "You did not enter a valid selection."
        whitelist_tcpshield
    esac
}

javapipe_kernel(){
    output "Apply JavaPipe's kernel configurations? (https://javapipe.com/blog/iptables-ddos-protection/)"
    output "[1] Yes."
    output "[2] No."
    read javapipe
    case $javapipe in
        1)  bash -c 'cat > /etc/sysctl.conf' <<-'EOF'
kernel.printk = 4 4 1 7 
kernel.panic = 10 
kernel.sysrq = 0 
kernel.shmmax = 4294967296 
kernel.shmall = 4194304 
kernel.core_uses_pid = 1 
kernel.msgmnb = 65536 
kernel.msgmax = 65536 
vm.swappiness = 20 
vm.dirty_ratio = 80 
vm.dirty_background_ratio = 5 
fs.file-max = 2097152 
net.core.netdev_max_backlog = 262144 
net.core.rmem_default = 31457280 
net.core.rmem_max = 67108864 
net.core.wmem_default = 31457280 
net.core.wmem_max = 67108864 
net.core.somaxconn = 65535 
net.core.optmem_max = 25165824 
net.ipv4.neigh.default.gc_thresh1 = 4096 
net.ipv4.neigh.default.gc_thresh2 = 8192 
net.ipv4.neigh.default.gc_thresh3 = 16384 
net.ipv4.neigh.default.gc_interval = 5 
net.ipv4.neigh.default.gc_stale_time = 120 
net.netfilter.nf_conntrack_max = 10000000 
net.netfilter.nf_conntrack_tcp_loose = 0 
net.netfilter.nf_conntrack_tcp_timeout_established = 1800 
net.netfilter.nf_conntrack_tcp_timeout_close = 10 
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 10 
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 20 
net.netfilter.nf_conntrack_tcp_timeout_last_ack = 20 
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 20 
net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 20 
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 10 
net.ipv4.tcp_slow_start_after_idle = 0 
net.ipv4.ip_local_port_range = 1024 65000 
net.ipv4.ip_no_pmtu_disc = 1 
net.ipv4.route.flush = 1 
net.ipv4.route.max_size = 8048576 
net.ipv4.icmp_echo_ignore_broadcasts = 1 
net.ipv4.icmp_ignore_bogus_error_responses = 1 
net.ipv4.tcp_congestion_control = htcp 
net.ipv4.tcp_mem = 65536 131072 262144 
net.ipv4.udp_mem = 65536 131072 262144 
net.ipv4.tcp_rmem = 4096 87380 33554432 
net.ipv4.udp_rmem_min = 16384 
net.ipv4.tcp_wmem = 4096 87380 33554432 
net.ipv4.udp_wmem_min = 16384 
net.ipv4.tcp_max_tw_buckets = 1440000 
net.ipv4.tcp_tw_recycle = 0 
net.ipv4.tcp_tw_reuse = 1 
net.ipv4.tcp_max_orphans = 400000 
net.ipv4.tcp_window_scaling = 1 
net.ipv4.tcp_rfc1337 = 1 
net.ipv4.tcp_syncookies = 1 
net.ipv4.tcp_synack_retries = 1 
net.ipv4.tcp_syn_retries = 2 
net.ipv4.tcp_max_syn_backlog = 16384 
net.ipv4.tcp_timestamps = 1 
net.ipv4.tcp_sack = 1 
net.ipv4.tcp_fack = 1 
net.ipv4.tcp_ecn = 2 
net.ipv4.tcp_fin_timeout = 10 
net.ipv4.tcp_keepalive_time = 600 
net.ipv4.tcp_keepalive_intvl = 60 
net.ipv4.tcp_keepalive_probes = 10 
net.ipv4.tcp_no_metrics_save = 1 
net.ipv4.ip_forward = 0 
net.ipv4.conf.all.accept_redirects = 0 
net.ipv4.conf.all.send_redirects = 0 
net.ipv4.conf.all.accept_source_route = 0 
net.ipv4.conf.all.rp_filter = 1
EOF
            sysctl -p 
            ;;
        2)  output "Skipping..."
            ;;
        * ) output "You did not enter a valid selection."
            javapipe_kernel
    esac    
}

secure_ssh(){
    output "Ensure that the file and directory exists."
    mkdir -p ~/.ssh
    touch ~/.ssh/authorized_keys

    output "Adding SSH keys..."
    #Change your SSH Keys accordingly
    echo "PUT YOUR PUBLIC KEY HERE" >> ~/.ssh/authorized_keys
    output "Ensuring SSH keys permissions..."
    chmod -R go= ~/.ssh
    chown -R $USER:$USER ~/.ssh

    output "Disabling SSH password based login..."
    sed -i 's/.*PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    output "Restarting SSH service..."
    systemctl restart sshd
    output "Finished SSH configuration."
		
    output "Generating and establishing new root password..."
    rootpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    echo -e "${rootpassword}\n${rootpassword}" | passwd > /dev/null 2>&1
    output "New root password: ${rootpassword}"    
}

motd(){
    echo '

     /\_____/\      
    /  o   o  \     
   ( ==  ^  == )   This server is a property of '"${company}"'.
    )         (    Unauthorized access to this system will be prosecuted by law.
   (           )   Your ip address has been logged for security purposes.
  ( (  )   (  ) )   
 (__(__)___(__)__)

' | tee /etc/motd >/dev/null 2>&1
}

#Execution
preflight
update_packages
activate_iptables
activate_fail2ban
whitelist_cloudflare
whitelist_tcpshield
activate_tuned
javapipe_kernel
spectre_vulnerbility_check
secure_ssh
motd
output "Finished configuration."
