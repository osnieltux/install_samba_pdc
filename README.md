## install_samba_pdc
#### Simple script for creating a local domain in Samba on Ubuntu

if you are using **Ubuntu** or **Debian** with sudo
  
      curl -fsSL https://raw.githubusercontent.com/osnieltux/install_samba_pdc/refs/heads/main/install_samba_pdc.sh -o /tmp/script.sh && sudo bash /tmp/script.sh <your_domain> <your_ipv4>


without sudo

      curl -fsSL https://raw.githubusercontent.com/osnieltux/install_samba_pdc/refs/heads/main/install_samba_pdc.sh -o /tmp/script.sh && bash /tmp/script.sh <your_domain> <your_ipv4>

**If you are using an LXC it must be unprivileged and set DNS manually.**

**Remember to:**
  
  - *set your \<domain> and \<IP>*
  - *change you administrator passord*
  - *delete PASSWORD.txt (contains the randomly generated password)*
