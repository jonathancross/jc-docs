#!/bin/bash
#
# Bash script used to install OLDER versions of the Monero cli on Linux.
# By "old" we mean those signed by Fluffy Pony- Riccardo Spagni <ric@spagni.net>
# Tested with v0.11 - v0.15.0.1
# For NEW releases signed by BinaryFate -- see "upgrade-monero.sh"
# Script will properly validate downloads, verify gpg signatures and checksums.
#
# REQUIREMENTS:
#
# Configure the settings below (see CONFIGURATION) to match your system.
#
# EXAMPLE USAGE:
#
# ./upgrade-monero-old.sh
#
# Upgrading the Monero daemon
# ===========================
#   * Downloading Hashes: https://www.getmonero.org/downloads/hashes.txt
#     Saved as: /home/USER/tmp/monero_hashes_19374.txt
#     Signature data?:  [CONFIRMED]
#   * New version: v0.15.0.0
#   * Destination: /home/USER/bin/
#   * Downloading Release: https://downloads.getmonero.org/cli/monero-linux-x64-v0.15.0.0.tar.bz2
#
# Checking for Fluffy's gpg key in keyring... [key NOT found]
# Importing from keyserver... [OK]
#
# Verifying signature in monero_hashes_19374.txt:
# gpg: Signature made Sat 09 Nov 2019 02:56:55 AM CET
# gpg:                using RSA key 94B738DD350132F5ACBEEA1D55432DF31CCD4FCD
# gpg: Good signature from "Riccardo Spagni <ric@spagni.net>" [unknown]
# Primary key fingerprint: BDA6 BD70 42B7 21C4 67A9  759D 7455 C5E3 C0CD CEB9
#      Subkey fingerprint: 94B7 38DD 3501 32F5 ACBE  EA1D 5543 2DF3 1CCD 4FCD
# Signature VERIFIED.
#
# Verifying hashes:
#   * Expected: 53d9da55137f83b1e7571aef090b0784d9f04a980115b5c391455374729393f3
#   * Actual:   53d9da55137f83b1e7571aef090b0784d9f04a980115b5c391455374729393f3
# Hashes match.
#
# Extracting files from monero-linux-x64-v0.15.0.0.tar.bz2... Done.
#
# Moving extracted folder to /home/USER/bin/... Done.
# Replacing soft links:
#   'monerod' -> 'monero-x86_64-linux-gnu-v0.15.0.0/monerod'
#   'monero-wallet-cli' -> 'monero-x86_64-linux-gnu-v0.15.0.0/monero-wallet-cli'
#   'monero-wallet-rpc' -> 'monero-x86_64-linux-gnu-v0.15.0.0/monero-wallet-rpc'
#
# Confirming installation... CONFIRMED: Monero 'Carbon Chamaeleon' (v0.15.0.0-release)
# You can now delete the downloaded files in /home/USER/tmp
#
# DONE.
################################################################################
# AUTHOR:  Jonathan Cross 0xC0C076132FFA7695 (jonathancross.com)
# LICENSE: WTFPL - https://github.com/jonathancross/jc-docs/blob/master/LICENSE
# BUGS:    https://github.com/jonathancross/jc-docs/issues/new
################################################################################

################################################################################
# BEGIN CONFIGURATION
################################################################################

# Folder locations, please change as needed:
TMP=/tmp    # Folder (without trailing slash) where files are downloaded to.
DEST=~/bin  # Destination (without trailing slash) where we will install.

# TODO: Add configuration options for commands needed such as openssl.

# Items below can be modified, but in most cases should work fine as-is.

# File containing release hashes.  This tells us the version number as well:
HASHES_URL='https://www.getmonero.org/downloads/hashes.txt'

# egrep pattern for Linux archive file (unfortunately this changes regularly):
NEW_VERSION_PATTERN='monero-linux-x64-v[0-9.]+.tar.bz2'

# Prefix (without version number) of the folder extracted from the bzip archive:
EXTRACTED_FOLDER_PREFIX="monero-x86_64-linux-gnu-" # v0.15.0.0 version

# URL prefix containing the release (without filename):
BZIP_URL_PREFIX='https://downloads.getmonero.org/cli/'

# Fluffy's PGP key fingerprint:
GPG_KEY_FPR='BDA6 BD70 42B7 21C4 67A9  759D 7455 C5E3 C0CD CEB9'

# Hard code expected UID in gpg key to check for fakes:
FLUFFY_UID='Riccardo Spagni <ric@spagni.net>'

# URL for Gitian signatures built reproducibly:
GITIAN_URL='https://github.com/monero-project/gitian.sigs'

################################################################################
# END CONFIGURATION
################################################################################

WARNING_MSG="
--------------------------------------------------------------------------------
This may be the result of a download error, dev mistake or foul play.
DO NOT PROCEED until you determine the cause."

echo "
Upgrading the Monero daemon
==========================="

# Make sure DEST exists:
if [[ ! -d "${DEST}/" ]]; then
  echo "ERROR: Could not find DEST ($DEST).
  You must configure this as path to the destination folder.";
  exit 1;
fi

# Make sure TMP exists:
if [[ ! -d "${TMP}/" ]]; then
  echo "ERROR: Could not find TMP ($TMP).
  You must configure this as a full path to the directory used for temp files.";
  exit 1;
fi

cd "${TMP}"

# Temporary file name for hashes to make sure unique.
HASHES_FILE="monero_hashes_$$.txt"

# Get HASHES_FILE from HASHES_URL:
if [[ -f "${TMP}/${HASHES_FILE}" ]]; then
  echo "  * Signed Hashes: ${TMP}/${HASHES_FILE}"
else
  echo "  * Downloading Hashes: ${HASHES_URL}"
  if curl --silent "${HASHES_URL}" --output "${HASHES_FILE}"; then
    echo "    Saved as: ${TMP}/${HASHES_FILE}"
    # Check if HASHES_FILE actually downloaded (they keep changing location)
    echo -n "    Signature data?: "
    if grep -q "BEGIN PGP SIGNED MESSAGE" "${HASHES_FILE}"; then
      echo " [CONFIRMED]"
    else
      echo " [ERROR: Not a GPG signature]"
      exit 1
    fi
  else
    echo "ERROR: Could not download ${TMP}/${HASHES_FILE}"
    exit 1
  fi
fi

# Extract version number and file name:
NEW_VERSION_PATTERN_PREFIX="${NEW_VERSION_PATTERN%[*}"
NEW_BZIP=$(egrep --only-matching "${NEW_VERSION_PATTERN}" "${HASHES_FILE}")
# Check if we got something:
if [[ "${NEW_BZIP}" != *"${NEW_VERSION_PATTERN_PREFIX}"* ]]; then
  echo "ERROR: Could not extract new version info from hashes.txt using NEW_VERSION_PATTERN.
       NEW_VERSION_PATTERN = ${NEW_VERSION_PATTERN}
       HASHES_FILE = ${TMP}/${HASHES_FILE}
       Maybe file name format changed?"
  exit 1
fi
# Continue now that we know we have something:
NEW_VER=${NEW_BZIP##*-}     # Strip off prefix
NEW_VER=${NEW_VER%.tar.bz2} # Strip off suffix
NEW_TAR="${NEW_VER}.tar"    # Add back the .tar suffix
EXTRACTED_FOLDER_NAME="${EXTRACTED_FOLDER_PREFIX}${NEW_VER}"
NEW_VERSION_FOLDER="monero-${NEW_VER}"
BZIP_URL="${BZIP_URL_PREFIX}${NEW_BZIP}"

echo "  * New version: $NEW_VER"
echo "  * Destination: ${DEST}/"

# Download BZIP file:
if [[ -f "${TMP}/${NEW_BZIP}" ]]; then
  echo "  * Release file already downloaded: ${TMP}/${NEW_BZIP}"
else
  echo "  * Downloading Release: ${BZIP_URL}"
  printf "    "
  if curl --progress-bar "${BZIP_URL}" --output "${TMP}/${NEW_BZIP}"; then
    echo "    Saved as: ${TMP}/${NEW_BZIP}"
  else
    echo "ERROR: Could not download ${TMP}/${NEW_BZIP}"
    exit 1
  fi
fi
echo ''

# Check if we have fluffy's key in the local keyring:
GPG_KEY_HANDLE="${GPG_KEY_FPR:30}"      # Extract last 64 bits
GPG_KEY_HANDLE="${GPG_KEY_HANDLE// /}"  # Remove spaces
echo -n "Checking for Fluffy's gpg key in keyring..."
if gpg -k 0x${GPG_KEY_HANDLE} &> /dev/null; then
  echo " [key found]"
else
  echo " [key NOT found]"
  echo -n "Importing from keyserver..."
  if gpg --keyserver keyserver.ubuntu.com --recv-key "${GPG_KEY_FPR}" &> /dev/null; then
    echo " [OK]"
  else
    echo "
    ERROR: Could not import this key from the keyserver:
    ${GPG_KEY_FPR}
    Please import manually and try this script again."
    exit 1
  fi
fi

# Use Fluffy's key to verify hashes.txt:
echo -e "\nVerifying gpg signature in ${HASHES_FILE}:"
SIG_ERROR=1
SIG_RESULT="$(gpg --verbose --verify ${HASHES_FILE} 2>&1)"
# Did the command complete successfully?
if [[ "$?" == '0' ]]; then
  # Is the signature valid?
  if [[ "${SIG_RESULT}" == *"Good signature from"* ]]; then
    # Was the signature made with the correct key?
    if [[ "${SIG_RESULT}" == *"${GPG_KEY_FPR}"* ]]; then
      SIG_ERROR=0
      # Print simplified results:
      echo "${SIG_RESULT}" | grep --perl-regexp '(Signature made|Good signature from|Primary key fingerprint)'
      echo "Signature VERIFIED."
    fi
  fi
fi

# Check the results of the signature verification:
if [[ "${SIG_ERROR}" == "1" ]]; then
  echo "ERROR: Bad signature for Fluffy's key:
       ${GPG_KEY_FPR}"
  if [[ "${SIG_RESULT}" == *"primary key ${GPG_KEY_HANDLE}"* ]]; then
    echo "Key was correct, but signature is invalid (file may have been modified?)."
  elif [[ "${SIG_RESULT}" == *"no signature found"* ]]; then
    echo "Signature is invalid / modified or doesn't exist."
  else
    echo "WARNING: File signed using incorrect key."
    if [[ "${SIG_RESULT}" == *"${FLUFFY_UID}"* ]]; then
      echo "         Key looks like an impostor pretending to be ${FLUFFY_UID}."
    fi
  fi
echo "
Signature debugging info:
${SIG_RESULT}
${WARNING_MSG}"
  exit 1
fi

# Verify file checksums against those in hashes.txt
echo -e "\nVerifying hashes:"

HASH_EXPECTED="$(grep "${NEW_BZIP}" "${HASHES_FILE}" | cut -d ' ' -f 2)"
echo "  * Expected: ${HASH_EXPECTED}"

HASH_ACTUAL="$(openssl dgst -sha256 "${NEW_BZIP}" | cut -d ' ' -f 2)"
echo "  * Actual:   ${HASH_ACTUAL}"

if [[ "${HASH_EXPECTED}" == "${HASH_ACTUAL}" ]]; then
  echo "Hashes match."
else
  echo "
ERROR: Hashes DO NOT match.
You can manually verify by comparing with hashes found here:
  ${HASHES_URL}
And / or here:
  ${GITIAN_URL}
${WARNING_MSG}"
  exit 1
fi

echo -en "
Extracting files from ${NEW_BZIP}... "
# Handle v0.14.1 release which is a gzip pretending to be a bzip2.
# https://repo.getmonero.org/monero-project/monero-site/issues/964
if file "${NEW_BZIP}" | grep -q gzip; then
  echo -n '(trying to extract malformed gzip) '
  if tar -z --extract --file "${NEW_BZIP}"; then
    echo "Done."
    # 14.1 also renamed for extracted folder:
    echo -n "  - Fixing broken 14.1 naming..."
    if mv -f "monero-x86_64-linux-gnu" ${NEW_VERSION_FOLDER}; then
      echo " Done."
    else
      echo "ERROR: Failed to rename monero-x86_64-linux-gnu to ${NEW_VERSION_FOLDER}"
      exit 1
    fi
  else
    echo "ERROR: Failed to extract gzip named as bzip (release v.0.14.1)."
    exit 1
  fi
elif tar --extract --bzip2 --file "${NEW_BZIP}"; then
  echo "Done."
  echo -n "  - Fixing v15+ naming..."
  if mv -f "${EXTRACTED_FOLDER_NAME}" "${NEW_VERSION_FOLDER}"; then
    echo " Done."
  else
    echo "ERROR: Failed to rename ${EXTRACTED_FOLDER_NAME} to ${NEW_VERSION_FOLDER}."
    echo "       Script probably needs to be updated with new folder name."
    exit 1
  fi
else
  echo "ERROR: Failed to expand ${NEW_BZIP}"
  exit 1
fi

# Create softlinks if possible:
if [[ -d "${NEW_VERSION_FOLDER}" ]]; then
  echo -en "\nMoving extracted folder to ${DEST}/... "
  cp -Rf "${NEW_VERSION_FOLDER}" "${DEST}/"
  cd "${DEST}/"
  echo -e "Done.\nReplacing soft links:"
  for APP in monerod monero-wallet-cli monero-wallet-rpc; do
    printf '  '
    ln -sfv "${NEW_VERSION_FOLDER}/${APP}" "${APP}"
  done

  echo -en "\nConfirming installation..."
  INSTALLED_VER="$(${DEST}/monerod --version)"
  PATH_VER="$(monerod --version)"
  if [[ "$INSTALLED_VER" == "$PATH_VER" ]]; then
    echo " CONFIRMED: $PATH_VER"
    echo "You can now delete the downloaded files in $TMP"
  else
    echo -e "\nWARNING: ${DEST}/monerod doesn't seem to be in your PATH."
    echo -e "           Instead we found $(which monerod)"
  fi
else
  echo '
NOTE: Folder name has changed, you must manually install:
  NEW_VERSION_FOLDER=new_name_of_extracted_folder_here;
  cp -R "${NEW_VERSION_FOLDER}" "'${DEST}/'";
  cd "'${DEST}/'";
  for APP in monerod monero-wallet-cli monero-wallet-rpc;
    do ln -sfv "${NEW_VERSION_FOLDER}/${APP}" "${APP}";
  done;
  ';
fi

echo -e "\nDONE."
