#!/bin/sh
#
# USAGE:
# gpg-keys-signed-by.sh LongKeyID
#
# EXAMPLE:
# gpg-keys-signed-by.sh C0C076132FFA7695
#
# DESCRIPTION:
# This script takes 1 parameter: LongKeyID (eg: C0C076132FFA7695 or fingerprint)
# and returns a list of PGP key fingerprints representing keys in your local
# keychain which were signed by the given key.
# Based on https://unix.stackexchange.com/a/305969/100248
#
# The script will cache basic data in /tmp/
#
# Latest version:
# https://github.com/jonathancross/jc-docs/blob/master/gpg-keys-signed-by.sh
#
# LICENSE: WTFPL
################################################################################

# Cache gpg data.
# This file can be deleted at any time and will be rebuilt if needed:
GPG_DATA_FILE=/tmp/gpg-key-data.txt

# Echo to stderr rather than stdout
alias errcho='>&2 printf'

# Validate commandline parameter:
keyid="${1}"

# Remove '0x' prefix if needed
keyid="${keyid#0x}"

# Check length
if [[ "${#keyid}" -lt "16" ]]; then
  echo "Please supply the long key ID (or full fingerprint with no spaces) of"\
       "the key whose signatures we are to search for."
  echo "Examples:"
  echo "${0} C0C076132FFA7695"
  echo "${0} 9386A2FB2DA9D0D31FAF0818C0C076132FFA7695"
  exit 1
else
  keyid="${keyid:(-16)}" # Take the last 16 chars
fi

# TODO: Check if hex: [[ "${keyid}" =~ ^[a-fA-F0-9]+$ ]]
#       Also check if keyid is in keyring

# Cache the gpg data:
if [ ! -f "${GPG_DATA_FILE}" ]; then
  errcho "Creating keyring database (${GPG_DATA_FILE})..."
  # Export gpg signature data
  gpg --with-colons --fingerprint --list-sigs 2> /dev/null |
    # Filter out sigs for keys we don't have
    grep --fixed-strings --invert-match '[User ID not found]' > ${GPG_DATA_FILE}
  errcho " [DONE]\n"
else
  errcho "Using cached database: ${GPG_DATA_FILE}\n"
fi

errcho "Searching for keys signed by ${keyid}"

# Counter
let I=0

# Load the data:
cat ${GPG_DATA_FILE} |

# Extract keys which are signed by keyid:
while read line; do
  packettype="$(echo "${line}" | cut -d':' -f1)"
  [[ "$(($I % 100))" == "0" ]] && errcho '.' # Progress
  let I++
  case $packettype in
    fpr)
      fingerprint="$(echo "${line}" | cut -d':' -f10)"
      ;;
    sig)
      issuedby="$(echo "${line}" | cut -d':' -f5)"
      if [ "x${issuedby}" = "x${keyid}" ]; then
        echo "${fingerprint}"
      fi
      ;;
  esac
done |
uniq |
tr '\n' ' ' # Convert new lines to spaces

errcho " [DONE]\n"
