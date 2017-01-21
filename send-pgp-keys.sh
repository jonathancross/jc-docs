#!/bin/bash
# Script used to upload your GPG public key to multiple services after a change.
# AUTHOR:  Jonathan Cross 0xC0C076132FFA7695 (jonathancross.com)
# LICENSE: WTFPL - https://github.com/jonathancross/jc-docs/blob/master/LICENSE

################################################################################
# YOU MUST CHANGE THE SETTINGS BELOW BEFORE RUNNING
################################################################################

PGP_KEY=XXXXXXXXXXXXXXXX # Your 16 character PGP key handle. (required)
GPG_COMMAND=gpg2         # GnuPG command to use: gpg or gpg2 (optional)


# Local backup of your key. (required)
# Change this to match where you want the key backup stored:
# Example: LOCAL_KEY_FILE=/tmp/${PGP_KEY}.asc
# Example: LOCAL_KEY_FILE=~/Documents/${PGP_KEY}.asc
LOCAL_KEY_FILE=~/${PGP_KEY}_pub.asc


# Upload to one or more public key servers:
ENABLE_PUBLIC_KEY_SERVERS=1 # Change to 0 (zero) to disable.
PUBLIC_KEY_SERVERS=(
  "x-hkp://pool.sks-keyservers.net"
  "pgp.mit.edu"
  "hkp://keys.gnupg.net"
)


# Do you have a personal website where you want to upload your key?
ENABLE_PERSONAL_KEY_SERVER=0 # Change to 1 (one) to enable.
# scp login settings:
PERSONAL_KEY_SERVER_USER=username           # Eg: jonathan
PERSONAL_KEY_SERVER_DOMAIN=example.com      # Eg: example.com
PERSONAL_KEY_SERVER_DEST_FOLDER=webroot/foo # Eg: folder name on remote server


# Upload your key to Keybase?
# Note: You must have an account on keybase.io and the `keybase` commandline
# program installed on your computer. Test that `keybase login` command works.
ENABLE_KEBASE=0 # Change to 1 (one) to enable.


################################################################################
# DO NOT MODIFY BELOW THIS LINE
################################################################################

# Test config:
if [[ "${PGP_KEY}" == "XXXXXXXXXXXXXXXX" ]]; then
  echo "ERROR: Please configure this script with YOUR PGP Key handle."
fi

# Look at last time the key was exported:
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

# Grep for the key because gpg always returns true, even for missing keys:
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
    ${GPG_COMMAND} --keyid-format=long --send-key ${PGP_KEY} --keyserver ${S}
  done
fi
