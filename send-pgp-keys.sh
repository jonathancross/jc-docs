#!/bin/bash
# Script used to upload your GPG public key to multiple services after a change.
# AUTHOR:  Jonathan Cross 0xC0C076132FFA7695 (jonathancross.com)
# LICENSE: WTFPL - https://github.com/jonathancross/jc-docs/blob/master/LICENSE

################################################################################
# YOU MUST CHANGE THE SETTINGS BELOW BEFORE RUNNING                            #
################################################################################

GPG_ID=XXXXXXXXXXXXXXXX     # (required) Your 16 character GPG key ID without 0x
GPG_ID_SHORT=${GPG_ID:8-16} # An 8 character short key ID.
                            # You can optionally use this below as needed.
GPG_COMMAND=gpg2            # GnuPG command to use: gpg or gpg2.

# Configure the service(s) where you want to host your key.

# Local export of your public key. (required)
# Change this to match where you want the key backup stored:
# Example: LOCAL_KEY_FILE=/tmp/${GPG_ID}.asc
# Example: LOCAL_KEY_FILE=~/Documents/${GPG_ID_SHORT}.asc
LOCAL_KEY_FILE=~/${GPG_ID}_pub.asc


# Upload to one or more public key servers:
ENABLE_PUBLIC_KEY_SERVERS=1 # Change to 0 (zero) to disable.
# You can add / remove servers as needed:
PUBLIC_KEY_SERVERS=(
  "hkps://keyserver.ubuntu.com"
  "hkps://pgp.surfnet.nl"
  "hkps://hkps.pool.sks-keyservers.net"
  "hkps://pgp.mit.edu"
)


# Do you have a personal website where you want to upload your key?
# This setting will upload your key using scp and the settings below.
ENABLE_PERSONAL_KEY_SERVER=0 # Change to 1 (one) to enable.
# scp login settings:
PERSONAL_KEY_SERVER_USER=username           # Eg: jonathan
PERSONAL_KEY_SERVER_DOMAIN=example.com      # Eg: example.com
PERSONAL_KEY_SERVER_DEST_FOLDER=webroot/foo # Eg: folder name on remote server.
                                            #     The LOCAL_KEY_FILE above will
                                            #     be transferred there via scp.

# Upload your key to Keybase?
# Note: You must have an account on keybase.io and the `keybase` commandline
# program installed on your computer. Test that `keybase login` command works.
ENABLE_KEBASE=0 # Change to 1 (one) to enable.


################################################################################
# DO NOT MODIFY BELOW THIS LINE                                                #
################################################################################

# Test config:
if [[ "${GPG_ID}" == "XXXXXXXXXXXXXXXX" ]]; then
  echo "ERROR: Please configure this script with *YOUR* gpg Key ID."
fi

# Look at last time the key was exported:
if [[ -f ${LOCAL_KEY_FILE} ]]; then
  LASTMOD_DATE="$(ls -al ${LOCAL_KEY_FILE} | awk '{print $6,$7, $8}')"
else
  LASTMOD_DATE='[first time]'
fi

echo "
Publishing your key: ${GPG_ID}
"

# Save the new public key to a file:
echo " • Exporting key to file: ${LOCAL_KEY_FILE}"
echo "   Last modified: ${LASTMOD_DATE}"

# Confirm GPG_ID is correct:
if ${GPG_COMMAND} --list-secret-keys ${GPG_ID} > /dev/null 2>&1; then
  ${GPG_COMMAND} --armor --export ${GPG_ID} > ${LOCAL_KEY_FILE}
  LASTMOD_DATE="$(ls -al ${LOCAL_KEY_FILE} | awk '{print $6,$7, $8}')"
  echo "   Updated now:   ${LASTMOD_DATE}"
else
  echo " • ERROR: Could not export key ${GPG_ID}.  Aborting."
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
  for S in "${PUBLIC_KEY_SERVERS[@]}"; do
    printf " • ";
    ${GPG_COMMAND} --keyid-format long --keyserver ${S} --send-key ${GPG_ID}
  done
fi
