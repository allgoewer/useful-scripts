#!/bin/bash
#
# make sure mapping to ddns is correctly configured on elara's
# /etc/bind/named.conf and /etc/bind/db.*
#
# Call with `sudo ./manage-cert.sh new CERT_NAME` to recreate cert
#
# Place a file at /etc/letsencrypt/manage-cert.env with
# config looking like this:
#
# # the DNS server
# SERVER=localhost
#
# # the DDNS record to update
# RECORD="_acme-challenge.ddns.example.org"
#
# # key required for nsupdate to authenticate
# KEY="/etc/letsencrypt/nsupdate.key"
#
# # uncomment to do a dry run against LE staging servers
# #DRY_RUN="--dry-run"
#
# # certs with authenticated domains
# declare -A DOMAINS=(['example.org']='-d *.example.org'
#                     ['example.com']='-d example.com -d *.example.com -d test.example.com')
#

# load config
. /etc/letsencrypt/manage-cert.env

cb() {
	certbot certonly \
		${DRY_RUN} \
		-v \
		--preferred-challenge dns \
		--manual \
		--manual-auth-hook "/etc/letsencrypt/manage-cert.sh hook add" \
		--manual-cleanup-hook "/etc/letsencrypt/manage-cert.sh hook delete" \
		--post-hook "/etc/letsencrypt/renewal-hooks/post/reload-certs.sh" \
		$@
}

new() {
	# check if domain exists
	[ "empty${DOMAINS[$1]}" = "empty" ] && exit 1
	cb ${DOMAINS[$1]}
}

hook() {
	echo -e "server ${SERVER}\nupdate ${1} ${RECORD}. 1 TXT ${CERTBOT_VALIDATION}\n\n" | \
		nsupdate -k "${KEY}"
}

case "$1" in
	new) new "$2";;
	hook) hook "$2";;
esac
