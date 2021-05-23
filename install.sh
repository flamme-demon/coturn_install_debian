#/bin/sh
# Copyright 2021 Franck MULLER (see the AUTHORS file)
# SPDX-License-Identifier: GPL-3.0-or-later

#Functions
install_coturn() {
	base_install=$(whiptail --title "Coturn Installer" --yesno "Welcome in the Coturn Installer, after press Enter the installation start automaticaly" --no-button "Cancel" --yes-button "Go !" 13 60 3>&1 1>&2 2>&3)

	exitstatus=$?
	if [ $exitstatus = 0 ]; then
	{
	i=1
	while read -r line; do
		i=$(( i + 1 ))
		echo $i
		done < <(apt-get install coturn -y)
	 } | whiptail --gauge "Wait update and install Coturn Service" 6 60 0
	else
	exit
	fi
	configure_coturn 0
}

active_turn() {
    	 whiptail --yesno "Would you like to active TURN now?" 10 60 2
    	  if [ $? -eq 0 ]; then # yes
	    systemctl stop coturn
      	    sed -i '/TURNSERVER_ENABLED/c\TURNSERVER_ENABLED=1' /etc/default/coturn
	    configure_le
    	  else #no TURN configured
	   basic_start "Maybe Already Configured :"
	  fi
}
configure_le() {
         whiptail --yesno "This script work's only with Letsencrypt on Certbot, do you want to continue ?" 10 60 2
          if [ $? -eq 0 ]; then # yes
            systemctl stop coturn
            install_certbot 0
          else #no TURN configured
            basic_start "Maybe Already Configured :"
          fi
}
install_certbot() {
        if [ $1 -eq 0 ]; then
        {
        i=1
        while read -r line; do
                i=$(( i + 1 ))
                echo $i
                done < <(apt-get install certbot -y)
        } | whiptail --gauge "Please wait install Certbot" 6 60 0
        fi
	run_certbot
}

run_certbot() {
	#remove dryrun
	TURNDOMAIN=$(whiptail --inputbox "Please write your TURN Domain" 8 39 turn.domain.tld 3>&1 1>&2 2>&3)
        MAIL=$(whiptail --inputbox "Please your Email address for Letsencrypt" 8 39 myemail@domain.tld 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
        {
        i=1
        while read -r line; do
                i=$(( i + 1 ))
                echo $i
                done < <(certbot certonly --quiet --dry-run --email $MAIL --standalone --preferred-challenges http -d $TURNDOMAIN)
        } | whiptail --gauge "Please wait Certbot create SSL certificate, maybe long operation..." 6 60 0
        fi
	configure_turn
}

configure_turn() {
	#systemctl stop coturn
        TURNPORT=$(whiptail --inputbox "Please write your TURN Port access" 8 39 5349 3>&1 1>&2 2>&3)
	USER=$(whiptail --inputbox "Please enter your User pass (simple)" 8 39 user 3>&1 1>&2 2>&3)
	PASS=$(whiptail --inputbox "Please enter your Password (simple)" 8 39 password 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then # yes
            sed -i '/#tls-listening-port/c\tls-listening-port='$TURNPORT /etc/turnserver.conf
	    sed -i '/#cipher-list/c\cipher-list="ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384"' /etc/turnserver.conf
            sed -i '/#cert/c\cert=/etc/letsencrypt/live/'$TURNDOMAIN'/fullchain.pem' /etc/turnserver.conf
            sed -i '/#pkey/c\pkey=/etc/letsencrypt/live/'$TURNDOMAIN'/privkey.pem' /etc/turnserver.conf
            sed -i '/#user/c\user='$USER':'$PASS /etc/turnserver.conf
	fi
	nat_enable
}

nat_enable() {
         whiptail --yesno "NAT is enable on your Network ? (Public IP/ Private IP)" 10 60 2
          if [ $? -eq 0 ]; then # yes
	    PUBIP=$(whiptail --inputbox "Please write your Public IP" 8 39 1.1.1.1 3>&1 1>&2 2>&3)
	    PRIVIP=$(whiptail --inputbox "Please write your Private IP" 8 39 192.168.1.1 3>&1 1>&2 2>&3)
            sed -i '/extern-ip/c\extern-ip='$PUBIP'/'$PRIVIP /etc/turnserver.conf
	    construct_start
          else #no NAT
	    construct_start
          fi
}

configure_coturn() {
	if [ $1 -eq 0 ]; then
	{
	i=1
        while read -r line; do
                i=$(( i + 1 ))
                echo $i
                done < <(construct_file)
	} | whiptail --gauge "Wait..." 6 60 0
	fi
	setup_all
}

setup_all() {
	systemctl stop coturn
        SERVER=$(whiptail --inputbox "Please write your STUN domain" 8 39 stun.domain.tld 3>&1 1>&2 2>&3)
	REALM=$(whiptail --inputbox "Please write your domain" 8 39 domain.tld 3>&1 1>&2 2>&3)
	#EXTERNIP=$(whiptail --inputbox "Please enter your Extern IP (Maybe Public)" 8 39 domain.tld 3>&1 1>&2 2>&3)
        STUNPORT=$(whiptail --inputbox "Please your STUN Access Port" 8 39 3478 3>&1 1>&2 2>&3)
	  if [ $? -eq 0 ]; then # yes
            sed -i '/server-name/c\server-name='$SERVER /etc/turnserver.conf
            sed -i '/realm/c\realm='$REALM /etc/turnserver.conf
	    sed -i '/#listening-port/c\listening-port='$STUNPORT /etc/turnserver.conf
          fi
	active_turn
}
#Construct
construct_file() {
mv /etc/turnserver.conf /etc/turnserver.conf.backup
touch /etc/turnserver.conf
echo '#listening-port=3478
fingerprint
lt-cred-mech
server-name=
realm=
listening-ip=0.0.0.0
extern-ip=
#user=
total-quota=100
stale-nonce=600
#tls-listening-port=5349
#cert=/usr/local/psa/var/modules/letsencrypt/etc/live/ourcodeworld.com/cert.pem
#pkey=/usr/local/psa/var/modules/letsencrypt/etc/live/ourcodeworld.com/privkey.pem
#cipher-list=
proc-user=turnserver
proc-group=turnserver
bps-capacity=0
stale-nonce
no-multicast-peers
verbose' >> /etc/turnserver.conf
}

construct_start() {
echo "Final step, please Wait..."
mv /lib/systemd/system/coturn.service /tmp/
systemctl daemon-reload
update-rc.d coturn defaults
/etc/init.d/coturn start
echo ""
echo "Coturn is now Configured"
echo ""
echo "-------------"
echo "For start dans stop Coturn please use: /etc/init.d/coturn start|stop|restart"
echo "-------------"
echo ""
echo "-------------"
echo "Your STUN server is: "$SERVER":"$STUNPORT
echo "Your TURN server is: "$TURNDOMAIN":"$TURNPORT" Username: "$USER" Password: "$PASS
echo "-------------"
echo ""
echo "Have nice Day :-)"
}

basic_start() {
echo "Final step, please Wait..."
systemctl restart coturn
echo ""
echo "Coturn is now Configured with STUN server ONLY"
echo ""
echo "-------------"
echo "For start dans stop Coturn please use: systemctl start|stop|restart coturn"
echo "-------------"
echo ""
echo "-------------"
echo "Your STUN server is: $SERVER:$STUNPORT" $1
echo "Your TURN server is: NOT CONFIGURED  - Please use 'install.sh -d' for enable TURN"
echo "-------------"
echo ""
echo "Have nice Day :-)"
}
#Main
usage() {
    cat << EOF
    This script is used to install Coturn

    usage : $(basename $0) {-t}
        without arg (rda) : install Coturn
	-d		  : add Turn Service
        -r                : remove Coturn

EOF
    exit 1
}
while getopts ':rda:' opt; do
    case ${opt} in
        r)
	    systemctl stop coturn
	    apt-get remove coturn certbot -y
	    apt-get autoremove coturn certbot -y
	    exit
            ;;
	d)
	    active_turn
	    exit
	    ;;
        *)
            usage
            ;;
    esac
done
install_coturn
