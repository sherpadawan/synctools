#!/bin/bash

# see https://wiki.smile.fr/view/Systeme/ConfigPostes/ServeurSMTPProjets

if [ "`which postconf`" == "" ];then
	if [ -f '/etc/redhat-release' ];then
		yum install postfix
		yum install mailx  
	else 
		apt-get install postfix
		apt-get install mailutils
	fi
fi

read -p "My Hostname: " h
read -p "My Domain: "  d

# Nom du serveur
postconf -e "myhostname = $h"

# Domaine d'appartenance du serveur
postconf -e "mydomain = $d"

# Domaine a utiliser (domaine afficher apres le @)
postconf -e "myorigin = \$mydomain"

# Banniere de login a la connexion du serveur SMTP
postconf -e "smtpd_banner = \$myhostname ESMTP \$mail_name (Debian/GNU)"

# Service d'envoie des notifications de reception de message
postconf -e "biff = no"

# Ajouter un domain si aucun n'est specifie
postconf -e "append_dot_mydomain = no"

# Alias
postconf -e "alias_maps = hash:/etc/aliases"
postconf -e "alias_database = hash:/etc/aliases"

# Domaine pour lequel les mails seront delivres en local
postconf -e "mydestination = \$myhostname, localhost, \$mydomain"

# Si pas de serveur de relai. Utilisation du DNS (mail MX)
postconf -e "relayhost = messager-projets.lvl.intranet"

# Acceptation des mails provenant uniquement de localhost
postconf -e "mynetworks = 127.0.0.0/8"

# Si postfix n'a pas lieu de faire office de RelayHost, on ecoute qu'en local
# pour l'acceptation des mails locaux
postconf -e "inet_interfaces = localhost"

if [ -f '/etc/redhat-release' ];then
	service postfix restart
else 
	/etc/init.d/postfix restart
fi

echo "[INFO] Sending  test email"
read -p "Recipient address:" email
echo 'Test ok: '$HOSTNAME | mail -s "Install ok on $HOSTNAME" $email

echo '[INFO] tail of mail log file'
if [ -f '/etc/redhat-release' ];then
	tail -f /var/log/maillog
else 
	tail -f /var/log/mail.log
fi



exit 0

