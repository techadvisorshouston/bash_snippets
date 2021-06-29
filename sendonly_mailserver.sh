#!/bin/bash

DOMAIN=$(hostname -f)

apt install postfix -y

postconf -f "myhostname = sendonly.$DOMAIN"

systemctl restart postfix

apt-get install opendkim opendkim-tools -y

adduser postfix opendkim

sed -i 's|#Canonicalization     simple|Canonicalization     relaxed/simple|g' /etc/opendkim.conf
sed -i 's/#Mode                 sv/Mode                 s/g' /etc/opendkim.conf
sed -i 's/#SubDomains           no/SubDomains           no/g' /etc/opendkim.conf

cat << _EOF_ >> /etc/opendkim.conf
#OpenDKIM user
# Remember to add user postfix to group opendkim
UserID             opendkim

# Map domains in From addresses to keys used to sign messages
KeyTable           refile:/etc/opendkim/key.table
SigningTable       refile:/etc/opendkim/signing.table

# A set of internal hosts whose mail should be signed
InternalHosts       /etc/opendkim/trusted.hosts
_EOF_

mkdir /etc/opendkim
mkdir /etc/opendkim/keys
chown -R opendkim:opendkim /etc/opendkim
chmod go-rw /etc/opendkim/keys

echo "*@${DOMAIN}     sendonly._domainkey.${DOMAIN}">>/etc/opendkim/signing.table

echo "sendonly._domainkey.${DOMAIN}    ${DOMAIN}:sendonly:/etc/opendkim/keys/${DOMAIN}/sendonly.private">>/etc/opendkim/key.table

cat << _EOF_ >> /etc/opendkim/trusted.hosts
127.0.0.1
localhost

*.${DOMAIN}
_EOF_

mkdir /etc/opendkim/keys/${DOMAIN}

opendkim-genkey -b 2048 -d ${DOMAIN} -D /etc/opendkim/keys/${DOMAIN} -s sendonly -v

chown opendkim:opendkim /etc/opendkim/keys/${DOMAIN}/sendonly.private

cat /etc/opendkim/keys/${DOMAIN}/sendonly.txt>>DNS_RECORD.txt

 sed -i 's|Socket local:/var/run/opendkim/opendkim.sock|Socket local:/var/spool/postfix/opendkim/opendkim.sock|g' /etc/opendkim.conf

 mkdir /var/spool/postfix/opendkim

 chown opendkim:postfix /var/spool/postfix/opendkim

 sed -i 's|SOCKET=local:$RUNDIR/opendkim.sock|SOCKET="local:/var/spool/postfix/opendkim/opendkim.sock"|g' /etc/default/opendkim

 cat << _EOF_ >> /etc/postfix/main.cf
 # Milter configuration
milter_default_action = accept
milter_protocol = 6
smtpd_milters = local:opendkim/opendkim.sock
non_smtpd_milters = $smtpd_milters
_EOF_

systemctl restart opendkim postfix

cat << _EOF_ >> /etc/postfix/main.cf
smtp_tls_security_level = may
smtp_tls_loglevel = 1
_EOF_

systemctl restart postfix
