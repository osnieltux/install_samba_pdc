#!/bin/bash

# arg validation
if [ "$#" -ne 2 ]; then
    echo "necessary arguments: <domain> <IPv4>"
    exit 1
fi

# common regex
valid_domain_regex='^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$'
ipv4_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'

# validating domain
if [[ "$1" =~ $valid_domain_regex ]]; then
    REALM="$1"
    REALM_DOMAIN="${REALM%%.*}"
else
    echo "Error: '$1' is not a valid realm"
    exit 2
fi

# validating ip address
NAMESERVER_DOMAIN="$2"
if [[ ! "$NAMESERVER_DOMAIN" =~ $ipv4_regex ]]; then
    echo "Error: '$NAMESERVER_DOMAIN' not valid IPv4"
    exit 3
fi
IFS='.' read -r o1 o2 o3 o4 <<< "$NAMESERVER_DOMAIN"
for octet in "$o1" "$o2" "$o3" "$o4"; do
    if (( octet < 0 || octet > 255 )); then
        echo "Error: '$NAMESERVER_DOMAIN' invalid range number (0–255)."
        exit 4
    fi
done

# ptr
ptr_ip_domain="$o4"
ptr_reverse="$o3.$o2.$o1"

# random passowrd
PASSWORD=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#$%&*' | head -c16)

# function to debug
check_code() {
    local code="$1"
    local msg="$2"
    if [ "$code" -ne 0 ]; then
        echo "Error ($code): $msg"
        exit "$code"
    fi
}

apt update
check_code $? "Updating apt"

apt upgrade -fy
check_code $? "Upgrading"

DEBIAN_FRONTEND=noninteractive apt install -y  samba krb5-config krb5-kdc winbind smbclient
check_code $? "Installing"

cat /dev/null  > /etc/samba/smb.conf
check_code $? "Blanking smb.conf"

samba-tool domain provision --use-rfc2307 --server-role=dc --dns-backend=SAMBA_INTERNAL --realm="$REALM" --domain="$REALM_DOMAIN" --adminpass="$PASSWORD"
check_code $? "Creating ad"

cp /var/lib/samba/private/krb5.conf /etc/
check_code $? "Copying krb5.conf"

systemctl stop smbd nmbd winbind
check_code $? "Stop services: smbd nmbd winbin"

systemctl disable smbd nmbd winbind
check_code $? "Disable  smbd nmbd winbind"

systemctl unmask samba-ad-dc
check_code $? "Unmask smbd nmbd winbind"

systemctl enable --now  samba-ad-dc
check_code $? "Enabling && starting  samba-ad-dc"

systemctl stop systemd-resolved
check_code $? "Stop systemd-resolved"

systemctl disable systemd-resolved
check_code $? "disable systemd-resolved"

unlink /etc/resolv.conf
check_code $? "Unlink /etc/resolv.conf"

cat /dev/null > /etc/resolv.conf && echo "nameserver $NAMESERVER_DOMAIN " >> /etc/resolv.conf && echo "search $REALM " >> /etc/resolv.conf
check_code $? "Write resolv.conf"

samba-tool dns zonecreate $NAMESERVER_DOMAIN "$ptr_reverse".in-addr.arpa -U administrator --password="$PASSWORD"
check_code $? "Create PTR zone"

samba-tool dns add $NAMESERVER_DOMAIN "$ptr_reverse".in-addr.arpa $ptr_ip_domain  PTR pdc.$REALM -U administrator --password="$PASSWORD"
check_code $? "Create PTR record for pdc"

samba-tool domain level show

echo "Password is stored in PASSWORD.txt, please delete the file"
echo "$PASSWORD" > PASSWORD.txt
