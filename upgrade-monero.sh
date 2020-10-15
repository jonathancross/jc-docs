#!/bin/bash
#
# Bash script used to install the newest version of the Monero cli on Linux.
# Script will properly validate downloads, verify gpg signatures and checksums.
# Tested with v0.15.0.5 - v0.17.1.0
# See upgrade-monero-old.sh for older versions signed by Fluffy.
#
# REQUIREMENTS:
#
# 1. Import GPG Key for BinaryFate:
#    gpg --keyserver hkps://keyserver.ubuntu.com --recv-key 81AC591FE9C4B65C5806AFC3F0AF4D462A0BDF92
#
# 2. Trust it:
#    echo -e "trust\n5\ny\n" | gpg --command-fd 0 --edit-key 81AC591FE9C4B65C5806AFC3F0AF4D462A0BDF92
#
# 3. Configure the settings below (see CONFIGURATION) to match your system.
#
# EXAMPLE USAGE:
#
# ./upgrade-monero.sh
#
# Upgrading the Monero daemon
# ===========================
#   * Downloading Hashes: https://www.getmonero.org/downloads/hashes.txt
#     Saved as: /tmp/monero_hashes_17975.txt
#     Signature data?:  [CONFIRMED]
#   * New version: v0.15.0.5
#   * Destination: /home/USER/bin/
#   * Downloading Release: https://downloads.getmonero.org/cli/monero-linux-x64-v0.15.0.5.tar.bz2
#
# Checking for BinaryFate's gpg key in keyring... [key found]
#
# Verifying gpg signature in monero_hashes_17975.txt:
# gpg: Signature made Wed 18 Mar 2020 10:51:04 PM CET
# gpg: Good signature from "binaryFate <binaryfate@getmonero.org>" [ultimate]
# Primary key fingerprint: 81AC 591F E9C4 B65C 5806  AFC3 F0AF 4D46 2A0B DF92
# Signature VERIFIED.
#
# Verifying hashes:
#   * Expected: 6cae57cdfc89d85c612980c6a71a0483bbfc1b0f56bbb30e87e933e7ba6fc7e7
#   * Actual:   6cae57cdfc89d85c612980c6a71a0483bbfc1b0f56bbb30e87e933e7ba6fc7e7
#   * Gitian:   6cae57cdfc89d85c612980c6a71a0483bbfc1b0f56bbb30e87e933e7ba6fc7e7
# Hashes match.
#
# Extracting files from monero-linux-x64-v0.15.0.5.tar.bz2... Done.
#   - Renaming extracted folder... Done.
#
# Moving extracted folder to /home/USER/bin/... Done.
# Replacing soft links:
#   'monerod' -> 'monero-v0.15.0.5/monerod'
#   'monero-wallet-cli' -> 'monero-v0.15.0.5/monero-wallet-cli'
#   'monero-wallet-rpc' -> 'monero-v0.15.0.5/monero-wallet-rpc'
#
# Confirming installation... CONFIRMED: Monero 'Carbon Chamaeleon' (v0.15.0.5-release)
# You can now delete the downloaded files in /tmp
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

# GitHub user trusted to have created Gitian assert files for this release:
GH_USER=TheCharlatan

# OpenPGP Fingerprint for the above user (ignored currently):
# GH_USER_KEY_FPR="9A8FC 55F3 B04B A314 6F34  92E7 9303 B33A 3052 24CB"

# Repo URL for Gitian assert files:
GITIAN_REPO="https://raw.githubusercontent.com/monero-project/gitian.sigs"

# File containing release hashes.  This tells us the version number as well:
HASHES_URL='https://www.getmonero.org/downloads/hashes.txt'

# egrep pattern for Linux archive file (unfortunately this changes regularly):
NEW_VERSION_PATTERN='monero-linux-x64-v[0-9.]+.tar.bz2'

# Prefix (without version number) of the folder extracted from the bzip archive:
EXTRACTED_FOLDER_PREFIX="monero-x86_64-linux-gnu-"

# URL prefix containing the release (without filename):
BZIP_URL_PREFIX='https://downloads.getmonero.org/cli/'

# BinaryFate's PGP key fingerprint:
GPG_KEY_FPR='81AC 591F E9C4 B65C 5806  AFC3 F0AF 4D46 2A0B DF92'

# Hard code expected UID in gpg key to check for fakes:
GPG_KEY_UID='binaryFate <binaryfate@getmonero.org>'

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
# Determine the major version (used later for URLs):
VER_REGEX='v(0\.[0-9][0-9])\.'
[[ $NEW_VER =~ $VER_REGEX ]] && VER_MAJOR="${BASH_REMATCH[1]}"
NEW_TAR="${NEW_VER}.tar"    # Add back the .tar suffix
EXTRACTED_FOLDER_NAME="${EXTRACTED_FOLDER_PREFIX}${NEW_VER}"
NEW_VERSION_FOLDER="monero-${NEW_VER}"
BZIP_URL="${BZIP_URL_PREFIX}${NEW_BZIP}"

echo "  * New version: ${NEW_VER}"
echo "  * Destination: ${DEST}/"

# Check if this version is already installed:
if [[ -d "${DEST}/${NEW_VERSION_FOLDER}" ]]; then
  echo "
Seems this version is already installed:
  ${DEST}/${NEW_VERSION_FOLDER}

Nothing to do, exiting.
"
  exit 0
fi

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

# Check if we have the GPG signing key in the local keyring:
# TODO: Put this in a for loop to also get $GH_USER_KEY_FPR
GPG_KEY_HANDLE="${GPG_KEY_FPR:30}"      # Extract last 64 bits
GPG_KEY_HANDLE="${GPG_KEY_HANDLE// /}"  # Remove spaces
echo -n "Checking for BinaryFate's gpg key in keyring..."
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

# Use GPG key to verify hashes.txt:
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
  echo "ERROR: Bad signature for BinaryFate's key:
       ${GPG_KEY_FPR}"
  if [[ "${SIG_RESULT}" == *"primary key ${GPG_KEY_HANDLE}"* ]]; then
    echo "Key was correct, but signature is invalid (file may have been modified?)."
  elif [[ "${SIG_RESULT}" == *"no signature found"* ]]; then
    echo "Signature is invalid / modified or doesn't exist."
  else
    echo "WARNING: File signed using incorrect key."
    if [[ "${SIG_RESULT}" == *"${GPG_KEY_UID}"* ]]; then
      echo "         Key looks like an impostor pretending to be ${GPG_KEY_UID}."
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

HASH_EXPECTED="$(grep "${NEW_BZIP}" "${HASHES_FILE}")"
HASH_EXPECTED="${HASH_EXPECTED%% *}" # Remove everything after first space.
echo "  * Expected: ${HASH_EXPECTED}"

HASH_ACTUAL="$(openssl dgst -sha256 "${NEW_BZIP}" | cut -d ' ' -f 2)"
HASH_ACTUAL="${HASH_ACTUAL%% *}" # Remove everything after first space.
echo "  * Actual:   ${HASH_ACTUAL}"

if [[ "${HASH_EXPECTED}" != "${HASH_ACTUAL}" ]]; then
  echo "
ERROR: Hashes DO NOT match.
You can manually verify by comparing with hashes found here:
  ${HASHES_URL}
And / or here:
  ${GITIAN_URL}
${WARNING_MSG}"
  exit 1
fi

# Build the URL to the Gitian assert file we will check for a hash match:
GITIAN_ASSERT_FILE="monero-linux-${VER_MAJOR}-build.assert"
GITIAN_ASSERT_URL="${GITIAN_REPO}/master/${NEW_VER}-linux/${GH_USER}/${GITIAN_ASSERT_FILE}"
GITIAN_ASSERT_DOWNLOAD_ERROR=1 # Assume an error unless we know we succeed below.

# Downloading Gitian assert file and sig from GitHub to cross-check:
if curl -s --remote-name-all ${GITIAN_ASSERT_URL}{,.sig}; then
  # Check if the files were actually downloaded:
  if [[ -f "${GITIAN_ASSERT_FILE}" && -f "${GITIAN_ASSERT_FILE}.sig" ]]; then
    GITIAN_ASSERT_DOWNLOAD_ERROR=0
  fi
fi

if [[ "${GITIAN_ASSERT_DOWNLOAD_ERROR}" == "1" ]]; then
  echo "ERROR: Failed to download assert file for ${NEW_VER} from:"
  echo "${GITIAN_ASSERT_URL}"
  exit 1
fi

###############################################################################
# TODO: check the signature on the assert file using $GH_USER_KEY_FPR.
###############################################################################

# Compare Gitian hash to ours:
GITIAN_ASSERT_HASH=$(grep --only-matching "${HASH_ACTUAL}" "${GITIAN_ASSERT_FILE}")
if [[ "x${GITIAN_ASSERT_HASH}" == "x${HASH_ACTUAL}" ]]; then
  echo "  * Gitian:   ${GITIAN_ASSERT_HASH}"
  echo "Hashes match."
else
  echo "ERROR: Gitian hash DOES NOT match ours.
You can manually verify by comparing hash above to those found here:
  ${GITIAN_ASSERT_URL}

${WARNING_MSG}"
  exit 1
fi

# FINISHED CHECKING HASHES

echo -en "
Extracting files from ${NEW_BZIP}... "
if tar --extract --bzip2 --file "${NEW_BZIP}"; then
  echo "Done."
  echo -n "  - Renaming extracted folder..."
  if [[ -d "${NEW_VERSION_FOLDER}" ]]; then
    echo -en " [cleaning up old files] "
    rm -rf "${NEW_VERSION_FOLDER}"
  fi
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
