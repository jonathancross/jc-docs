#!/bin/bash
#
# Bash script used to install a new version of the Monero daemon on Linux.
# You must configure the variables below to match your version.
# Tested with v0.11 - v0.14.0.2
################################################################################
# AUTHOR:  Jonathan Cross 0xC0C076132FFA7695 (jonathancross.com)
# LICENSE: WTFPL - https://github.com/jonathancross/jc-docs/blob/master/LICENSE
################################################################################
#
# EXAMPLE USAGE:
# ./upgrade-monero.sh
#
# Upgrading the Monero daemon
# ===========================
#   • Downloading Hashes: https://www.getmonero.org/downloads/hashes.txt
#     Saved as: /home/user/tmp/monero_hashes_19813.txt
#     Signature data?:  [CONFIRMED]
#   • New version: v0.14.0.2
#   • Destination: /home/user/bin/
#   • Downloading Release: https://downloads.getmonero.org/cli/monero-linux-x64-v0.14.0.2.tar.bz2
#     Saved as: /home/user/tmp/monero-linux-x64-v0.14.0.2.tar.bz2
#
# Verifying signature in monero_hashes_19813.txt:
# gpg: Signature made Fri 08 Mar 2019 08:48:10 PM CET
# gpg:                using RSA key 94B738DD350132F5ACBEEA1D55432DF31CCD4FCD
# gpg: Good signature from "Riccardo Spagni <ric@spagni.net>" [unknown]
# Primary key fingerprint: BDA6 BD70 42B7 21C4 67A9  759D 7455 C5E3 C0CD CEB9
#      Subkey fingerprint: 94B7 38DD 3501 32F5 ACBE  EA1D 5543 2DF3 1CCD 4FCD
#
# Verifying hashes:
#   • Expected: 4dd5cd9976eda6b33b16821e79e671527b78a1c9bfb3d973efe84b824642dd21
#   • Actual:   4dd5cd9976eda6b33b16821e79e671527b78a1c9bfb3d973efe84b824642dd21
# Hashes match.
#
# Extracting files from monero-linux-x64-v0.14.0.2.tar.bz2... Done.
#
# Moving extracted folder to /home/user/bin... Done.
# Replacing soft links:
#   'monerod' -> 'monero-v0.14.0.2/monerod'
#   'monero-wallet-cli' -> 'monero-v0.14.0.2/monero-wallet-cli'
#   'monero-wallet-rpc' -> 'monero-v0.14.0.2/monero-wallet-rpc'
#
# Confirming installation... CONFIRMED: Monero 'Boron Butterfly' (v0.14.0.2-release)
# You can now delete the downloaded files in /home/user/tmp
#
# DONE.
################################################################################

# Folder locations, please change as needed:
LOC=~/Downloads # Folder (without trailing slash) where files downloaded to.
DEST=~/bin      # Destination (without trailing slash) where we will install.

# TODO: Add configuration options for commands needed such as openssl.

# Items below can be modified, but in most cases should work fine as-is.

# File containing release hashes.  This tells us the version number as well:
HASHES_URL="https://www.getmonero.org/downloads/hashes.txt"

# egrep pattern for download file:
NEW_VERSION_PATTERN='monero-linux-x64-v[0-9.]+.tar.bz2'

# URL prefix containing the release (without filename):
BZIP_URL_PREFIX="https://downloads.getmonero.org/cli/"

################################################################################
# END CONFIGURATION
################################################################################

echo "
Upgrading the Monero daemon
==========================="

# Make sure DEST exists:
if [[ ! -d "${DEST}/" ]]; then
  echo "ERROR: Could not find DEST ($DEST).
  You must configure this as path to the destination folder.";
  exit 1;
fi

# Make sure LOC exists:
if [[ ! -d "${LOC}/" ]]; then
  echo "ERROR: Could not find LOC ($LOC).
  You must configure this as a full path to the location of the new archive.";
  exit 1;
fi

cd "${LOC}"

# Temporary file name for hashes to make sure unique.
HASHES_FILE="monero_hashes_$$.txt"

# Get HASHES_FILE from HASHES_URL:
if [[ -f "${LOC}/${HASHES_FILE}" ]]; then
  echo "  • Signed Hashes:  ${LOC}/${HASHES_FILE}"
else
  echo "  • Downloading Hashes: ${HASHES_URL}"
  if curl --silent "${HASHES_URL}" --output "${HASHES_FILE}"; then
    echo "    Saved as: ${LOC}/${HASHES_FILE}"
    # Check if HASHES_FILE actually downloaded (they keep changing location)
    echo -n "    Signature data?: "
    if grep -q "BEGIN PGP SIGNED MESSAGE" "${HASHES_FILE}"; then
      echo " [CONFIRMED]"
    else
      echo " [ERROR: Not a GPG signature]"
      exit 1
    fi
  else
    echo "ERROR: Could not download ${LOC}/${HASHES_FILE}"
    exit 1
  fi
fi

# Extract version number and file name:
NEW_BZIP=$(egrep --only-matching "${NEW_VERSION_PATTERN}" "${HASHES_FILE}")
NEW_VER=${NEW_BZIP##*-}     # Strip off prefix
NEW_VER=${NEW_VER%.tar.bz2} # Strip off suffix
NEW_TAR="${NEW_VER}.tar"    # Add back the .tar suffix
NEW_VERSION_FOLDER="monero-${NEW_VER}"
BZIP_URL="${BZIP_URL_PREFIX}${NEW_BZIP}"

echo "  • New version: $NEW_VER"
echo "  • Destination: ${DEST}/"

# Download BZIP file:
if [[ -f "${LOC}/${NEW_BZIP}" ]]; then
  echo "  • Release file: ${LOC}/${NEW_BZIP}"
else
  echo "  • Downloading Release: ${BZIP_URL}"
  printf "    "
  if curl --progress-bar "${BZIP_URL}" --output "${LOC}/${NEW_BZIP}"; then
    echo "    Saved as: ${LOC}/${NEW_BZIP}"
  else
    echo "ERROR: Could not download ${LOC}/${NEW_BZIP}"
    exit 1
  fi
fi

echo -e "\nVerifying signature in ${HASHES_FILE}:"
RESULT="$(gpg --verify ${HASHES_FILE} 2>&1)"
# TODO: Better sig check
if ( echo "$RESULT" | grep -q 'Good signature from'; ); then
  # Just remove some noise.
  echo "$RESULT" | grep --invert-match --perl-regexp '(This key is not certified with a trusted signature|There is no indication that the signature belongs to the owner.)'
else
  echo "ERROR: Bad signature."
  echo "$RESULT"
  exit 1
fi

echo -e "\nVerifying hashes:"

HASH_EXPECTED="$(grep "${NEW_BZIP}" "${HASHES_FILE}" | cut -d ' ' -f 2)"
echo "  • Expected: ${HASH_EXPECTED}"

HASH_ACTUAL="$(openssl dgst -sha256 "${NEW_BZIP}" | cut -d ' ' -f 2)"
echo "  • Actual:   ${HASH_ACTUAL}"

if [[ "${HASH_EXPECTED}" == "${HASH_ACTUAL}" ]]; then
  echo "Hashes match."
else
  echo "ERROR: Hashes DO NOT match."
  exit 1
fi

echo -en "
Extracting files from ${NEW_BZIP}... "
if tar --extract --bzip2 --file "${NEW_BZIP}"; then
  echo "Done."
else
  echo "ERROR: Failed to expand ${NEW_BZIP}"
  exit 1
fi

# Create softlinks if possible:
if [[ -d "${NEW_VERSION_FOLDER}" ]]; then
  echo -en "\nMoving extracted folder to ${DEST}... "
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
    echo "You can now delete the downloaded files in $LOC"
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
