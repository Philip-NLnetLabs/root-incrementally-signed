#!/bin/sh
set -e
INCEPTION_OFFSET=1h
SIGNATURE_LIFETIME=13d
REMAIN=6d
ROOT_ZONE=root-2026021600

START_FAKETIME=1769904000	# 2026-02-01 00:00:00 UTC
END_FAKETIME=1772495999		# 2026-02-28 23:59:59 UTC
FAKETIME_INCREMENT=43200	# 12 hours

MODE=nsec

# Create an unsigned version of the root zone.
ldns-read-zone -s -e ZONEMD -e DNSKEY "$ROOT_ZONE" > root.unsigned

# Set up keyset
dnst keyset -c root.keyset-config create -n . -s root.keyset-state
dnst keyset -c root.keyset-config import zsk file keys/K.+008+61890.key
dnst keyset -c root.keyset-config import ksk file keys/K.+008+48259.key
dnst keyset -c root.keyset-config set fake-time "$START_FAKETIME"
dnst keyset -c root.keyset-config set dnskey-inception-offset 1d
dnst keyset -c root.keyset-config set dnskey-lifetime 60d
dnst keyset -c root.keyset-config set default-ttl 172800
dnst keyset -c root.keyset-config init

# Set up signer
dnst signer -c root.signer-config create -s root.signer-state -k root.keyset-state -i root.unsigned -o root.signed
dnst signer -c root.signer-config set fake-time "$START_FAKETIME"
dnst signer -c root.signer-config set inception-offset "$INCEPTION_OFFSET"
dnst signer -c root.signer-config set lifetime "$SIGNATURE_LIFETIME"
dnst signer -c root.signer-config set remain-time "$REMAIN"
case "$MODE" in
nsec)
        # NSEC is the default
        params=""
;;
nsec3)
        dnst signer -c root.signer-config set use-nsec3 true
        params="-n"
;;
nsec3-opt-out)
        dnst signer -c root.signer-config set use-nsec3 true
        dnst signer -c root.signer-config set opt-out true
        params="-n -P"
;;
esac
dnst signer -c root.signer-config set zone-md sha384

dnst signer -c root.signer-config sign
cp root.signed root.signed-"$START_FAKETIME"

CURR=$(expr "$START_FAKETIME" + "$FAKETIME_INCREMENT")
while test "$CURR" -lt "$END_FAKETIME"
do
	dnst signer -c root.signer-config set fake-time "$CURR"
	dnst signer -c root.signer-config cron
	cp root.signed root.signed-"$CURR"
	CURR=$(expr "$CURR" + "$FAKETIME_INCREMENT")
done

