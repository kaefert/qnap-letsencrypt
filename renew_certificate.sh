#!/bin/bash
set -e
export PATH=/opt/QPython2/bin:$PATH

# VARIABLES, replace these with your own.
DOMAIN="www.example.com"
EMAIL="user@example.com"
###########################################
DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


echo "$(date +%F_%T.%N) Checking whether to create/renew certificate."

if [ -s letsencrypt/live/$DOMAIN/cert.pem ]; then
  echo "$(date +%F_%T.%N) A certificate has been created previously, checking for expiration"

  ## currently a new certificate will expire after 90 days. That's 7776000 seconds.
  ## this script will renew the certificate if 30 days or less are left. That's 2592000 seconds (30*24*60*60).
  if openssl x509 -enddate -in letsencrypt/live/$DOMAIN/cert.pem -checkend 2592000
  then
    echo "$(date +%F_%T.%N) More than 30 days left, will not renew certificate yet. EXIT Script now."
    exit
  else
    echo "$(date +%F_%T.%N) Certificate expires in less than 30 days, will attempt renewal!"
  fi
else
  echo "$(date +%F_%T.%N) No certificate has been created previously by this script, will attempt to fetch our first one!"
fi

echo "$(date +%F_%T.%N) Running letsencrypt, Getting/Renewing certificate..."
letsencrypt certonly --rsa-key-size 4096 --renew-by-default --webroot --webroot-path "/share/Web/" -d $DOMAIN -t --agree-tos --email $EMAIL --config-dir "$DIR/letsencrypt" 

echo "$(date +%F_%T.%N) ...Success!"

echo "$(date +%F_%T.%N) Stopping stunnel and setting new stunnel certificates..."
/etc/init.d/stunnel.sh stop

cd letsencrypt/live/$DOMAIN
cat privkey.pem cert.pem > /etc/stunnel/stunnel.pem
cp chain.pem /etc/stunnel/uca.pem

echo "$(date +%F_%T.%N) Done! Service startup and cleanup will follow now..."
/etc/init.d/stunnel.sh start
/etc/init.d/Qthttpd.sh restart


echo "$(date +%F_%T.%N) All Done! End of Script. Certificate has been renewed and webserver restarted."
