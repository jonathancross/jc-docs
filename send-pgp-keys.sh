#!/bin/bash
# Script used to upload your GPG public key to multiple services after a change.
# AUTHOR:  Jonathan Cross 0xC0C076132FFA7695 (jonathancross.com)
# LICENSE: https://mit-license.org

PGP_KEY=XXXXXXXXXXXXXXXX # Your 16 character key handle
GPG_COMMAND=gpg2         # GnuPG command to use: gpg or gpg2

# SERVICES

# Use one or more public key servers:
ENABLE_PUBLIC_KEY_SERVERS=1
PUBLIC_KEY_SERVERS=(
  "x-hkp://pool.sks-keyservers.net"
  "pgp.mit.edu"
  "hkp://keys.gnupg.net"
)

# Local backup of your key.  I use the short 8 character key:
PGP_KEY_SHORT=${PGP_KEY:8-16} #  8 character key handle
LOCAL_KEY_FILE=~/Documents/${PGP_KEY_SHORT}.asc

# Do you have a personal website where you want to upload your key?
ENABLE_PERSONAL_KEY_SERVER=1
# scp login parameters
PERSONAL_KEY_SERVER_USER=username           # Eg: jonathan
PERSONAL_KEY_SERVER_DOMAIN=example.com      # Eg: example.com
PERSONAL_KEY_SERVER_DEST_FOLDER=webroot/foo # Eg: folder name on remote server

# Upload your key to keybase?
# Note: You should have an account there and the `keybase` command installed.
ENABLE_KEBASE=1


##############################################################################
# DO NOT MODIFY BELOW THIS LINE
##############################################################################

# Look at last time the key was exported
if [ -f ${LOCAL_KEY_FILE} ]; then
  LASTMOD_DATE="$(ls -al ${LOCAL_KEY_FILE} | awk '{print $6,$7, $8}')"
else
  LASTMOD_DATE='[first time]'
fi

echo "
Publishing your key: ${PGP_KEY}
"

# Save the new public key to a file:
echo " • Exporting key to file: ${LOCAL_KEY_FILE}"
echo "   Last modified: ${LASTMOD_DATE}"
# Grep for the key becasue gpg always returns true, even for missing keys!
if ${GPG_COMMAND} --list-secret-keys --keyid-format=long | grep -q ${PGP_KEY}; then
  ${GPG_COMMAND} --armor --export=${PGP_KEY} > ${LOCAL_KEY_FILE}
  LASTMOD_DATE="$(ls -al ${LOCAL_KEY_FILE} | awk '{print $6,$7, $8}')"
  echo "   Updated now:   ${LASTMOD_DATE}"
else
  echo " • ERROR: Could not export key ${PGP_KEY}.  Aborting."
  exit 128
fi

# Send new public key to my server:
if [[ "${ENABLE_PERSONAL_KEY_SERVER}" == "1" ]]; then
  # Build the destination used by scp
  PERSONAL_KEY_SERVER="${PERSONAL_KEY_SERVER_USER}@${PERSONAL_KEY_SERVER_DOMAIN}:${PERSONAL_KEY_SERVER_DEST_FOLDER}"
  printf " • Sending key to ${PERSONAL_KEY_SERVER}... "
  scp -q ${LOCAL_KEY_FILE} ${PERSONAL_KEY_SERVER}/ && echo " DONE."
fi

# Send to keybase:
if [[ "${ENABLE_KEBASE}" == "1" ]]; then
  echo " • Sending key to keybase.io..."
  keybase pgp update
fi

# Send keys to public keyserver:
if [[ "${ENABLE_PUBLIC_KEY_SERVERS}" == "1" ]]; then
  for S in ${PUBLIC_KEY_SERVERS[@]};do
    printf " • ";
     ${GPG_COMMAND} --keyid-format=long --keyserver ${S} --send-key ${PGP_KEY}
  done
fi
