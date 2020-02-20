#!/bin/bash
#
# Split a signed OpenPGP key into component email UIDs and email them
# individually using Apple's Mail.app on MacOS.
#
# You can configure which additional UIDs to export with each UID below.
#
# This was hacked together for FOSDEM 2020 key signing party.
#
# Copyright 2020 Jonathan Cross (jonathancross.com) - WTFPL
#
# REQUIREMENTS:
#
# This script uses apple-mail.pl:
#  * https://github.com/jonathancross/jc-docs/blob/master/apple-mail.pl
#
# Before running this script, you should have the key in your gpg keyring.
#
# USAGE:
#
# Meant to be used with signed keys with this file name structure:
#   001_[FINGERPRINT]_SIGNED.asc
#   002_[FINGERPRINT]_SIGNED.asc
#   003_[FINGERPRINT]_SIGNED.asc
#
# Called like so:
# split-and-email.sh 119_9386A2FB2DA9D0D31FAF0818C0C076132FFA7695_SIGNED.asc
#
# Or in a loop:
# for N in 001 002 003; do F=$(ls ${N}_*_SIGNED.asc 2>/dev/null);FPR=${F#*_};FPR=${FPR%*_SIGNED.asc}; if [ -f "${F}" ]; then rm -rf "${N}"; ../split-and-email.sh "${F}" 2>/dev/null; gpg --delete-key "${FPR}";fi ;done

################################################################################
# BEGIN CONFIGURATION
################################################################################

# Configure additional UIDs to export with each email UID. With each email
# address UID that is exported, also export UIDs of these types:
EXPORT_IMAGE_UIDS=0  # Photos embedded in the key.
EXPORT_STRING_UIDS=0 # Eg names, web sites, keybase, other text, etc.

# Enable debugging messages:
DEBUG=0

################################################################################
# END CONFIGURATION
################################################################################

# Split UID into name and email address:
KEY_UID_REGEX='^([^ ]+).* <(.+)>'
# Recognize an email address regex:
KEY_UID_IS_EMAIL_REGEX='[a-zA-Z0-9]@[a-zA-Z0-9]'

IN_FILE="${1}"
if [[ ! -f "${IN_FILE}" ]]; then
  echo "ERROR: File '${IN_FILE}' was not found."
  echo "USAGE: $0 <SIGNEDKEYFILE.asc>"
  exit 1
fi

if [[ $IN_FILE =~ ([0-9]{3})_([0-9A-F]+)_SIGNED.asc ]]; then
  NUM="${BASH_REMATCH[1]}"
  KEY_FPR="${BASH_REMATCH[2]}"
  KEY_HANDLE="${KEY_FPR: -16}"
  debug "NUM=$NUM, KEY_FPR=$KEY_FPR"
  if [[ "${IN_FILE}" != "${NUM}_${KEY_FPR}_SIGNED.asc" ]]; then
    echo "ERROR: FILE name has the wrong structure: '${IN_FILE}'."
    exit 1
  fi
else
  echo "ERROR: FILE name has the wrong structure: '${IN_FILE}'."
  exit 1
fi

# CONFIGURE UID_FILTER
# See https://www.gnupg.org/documentation/manuals/gnupg/GPG-Examples.html
# Export the specific email UID AND the following:
if   ((   ${EXPORT_IMAGE_UIDS} )) && (( ${EXPORT_STRING_UIDS} )); then
  # All non-email UIDs (eg images, names, websites, etc):
  UID_FILTER=" || uid !~ @"
elif (( ! ${EXPORT_IMAGE_UIDS} )) && (( ${EXPORT_STRING_UIDS} )); then
  # All non-image UIDs (eg names, websites, etc):
  UID_FILTER=" || uid !~ image of size"
elif ((   ${EXPORT_IMAGE_UIDS} )) && (( ! ${EXPORT_STRING_UIDS} )); then
  # Only image UIDs:
  UID_FILTER=" || uid =~ image of size"
elif (( ! ${EXPORT_IMAGE_UIDS} )) && (( ! ${EXPORT_STRING_UIDS} )); then
  # Only export email address UIDs (ignore all others):
  UID_FILTER=""
fi

# Print a debug message to stderr.
# debug $MESSAGE
function debug {
  (( "$DEBUG" )) && echo "DEBUG: $1" > /dev/stderr
}

# get_email_body $NUM $UID_NAME $UID_EMAIL_ADDRESS $KEY_FPR
# returns the formatted body of the email message.
function get_email_body {
  NUM="${1}"
  UID_NAME="${2}"
  UID_EMAIL_ADDRESS="${3}"
  KEY_FPR="${4}"
  KEY_FPR_SPLIT="${KEY_FPR:0:4} ${KEY_FPR:4:4} ${KEY_FPR:8:4} ${KEY_FPR:12:4} ${KEY_FPR:16:4}  ${KEY_FPR:20:4} ${KEY_FPR:24:4} ${KEY_FPR:28:4} ${KEY_FPR:32:4} ${KEY_FPR:36:4}"
  # Note: Don't use apostrophes -- will break AppleScript for emailing.
  #       Quotes need to be triple escaped as \\\"
  echo "Hello ${UID_NAME},

Thank you for participating in the FOSDEM 2020 keysigning party!

Attached is your signed UID \\\"${UID_EMAIL_ADDRESS}\\\" for key #${NUM}:

  * ${KEY_FPR_SPLIT}

If your key has multiple email address, separate signatures will be sent to each.

Please consider uploading to multiple keyservers:

  * keyserver.ubuntu.com
  * keys2.kfwebs.net
  * hkps.pool.sks-keyservers.net

Note: keys.openpgp.org will strip signatures from your key, so it is not beneficial for the OpenPGP WOT.

I look forward to a key signature from you as well (I was the guy handing out stickers of my key fingerprint).

Cheers,

Jonathan Cross
https://jonathancross.com
9386 A2FB 2DA9 D0D3 1FAF  0818 C0C0 7613 2FFA 7695
"
}

mkdir -p ${NUM}
echo "#${NUM} ${KEY_FPR} UIDs:"
# Main loop:
IFS=$'\n'
for KEY_UID_RAW in $(gpg -k ${KEY_FPR} | egrep '^uid'); do
  KEY_UID="${KEY_UID_RAW##*] }" # Remove gpg debugging prefix.
  if [[ ! $KEY_UID =~ $KEY_UID_IS_EMAIL_REGEX ]]; then
    debug "   - Skipping '$KEY_UID'"
    continue
  fi
  debug "Found email address UID: '$KEY_UID'"
  # Split UID into name and email address:
  if [[ $KEY_UID =~ $KEY_UID_REGEX ]]; then
    UID_NAME="${BASH_REMATCH[1]}"
    UID_EMAIL_ADDRESS="${BASH_REMATCH[2]}"
    debug "UID_NAME=$UID_NAME, UID_EMAIL_ADDRESS=$UID_EMAIL_ADDRESS"
  else
    echo "ERROR: Could not parse KEY_UID: '$KEY_UID'."
    exit 1
  fi
  # Create an export filter for this UID + any other UIDs we want to keep:
  UID_FILTER_FULL="uid = ${KEY_UID}${UID_FILTER}"
  debug "UID_FILTER_FULL: '${UID_FILTER_FULL}'"
  OUT_FILE="${NUM}/${KEY_HANDLE}_${UID_EMAIL_ADDRESS}.asc"
  printf "   + '$KEY_UID':"
  # Import from file version:
  # if gpg -q --armor --no-options \
  #      --import-options import-export \
  #      --import-filter keep-uid="${UID_FILTER_FULL}" \
  #      --import < "${IN_FILE}" > "${OUT_FILE}"; then

  # Export the filtered key UIDs:
  if gpg -q --armor --export \
       --export-filter keep-uid="${UID_FILTER_FULL}" \
       "${KEY_FPR}" > "${OUT_FILE}"; then
    echo ' OK'
  else
    echo ' FAILED'
    exit 1
  fi
  # Send the email:
  EMAIL_SUBJECT="Key #${NUM} : Sig for ${UID_EMAIL_ADDRESS}"
  get_email_body "${NUM}" "${UID_NAME}" "${UID_EMAIL_ADDRESS}" "${KEY_FPR}" |
    apple-mail.pl -g -a "${OUT_FILE}" -s "${EMAIL_SUBJECT}" "${UID_EMAIL_ADDRESS}"
done
