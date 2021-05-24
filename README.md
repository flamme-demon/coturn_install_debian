# Coturn AutoInstall
Auto Install Coturn (STUN &amp; TURN) for Debian 10 Buster

# Information
In full install method, the script install Certbot for Letsencrypt Certificate. 
Added packets :
- wget
- coturn
- certbot
- dnsutils

# Install
Must be run in root.
```
apt install wget -y && wget -O- https://raw.githubusercontent.com/fouille/coturn_install_debian/main/install.sh | bash
```

# Command Line Arguments
You can add arguments for your installation file.
```
wget https://raw.githubusercontent.com/fouille/coturn_install_debian/main/install.sh
chmod +x install.sh
``` 
`$ ./install.sh argument1 argument2 ...`

Where, install.sh is a shell script file and argument1, argument2 ... argumentN are list of arguments.

1. The `-t` variable
Configure TURN (STUN must be already configured)

2. The `-r` variable
Remove Coturn and Certbot

3. The `-N` variable
List of arguments
