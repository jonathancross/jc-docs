#!/usr/bin/perl
#
# Search for keys signed by the provided key ID.
# Includes all keys where the signature has not been revoked, even if the source
# key you provide itself has expired.
#
# USAGE:
#   ./gpg-keys-signed-by.pl C0C076132FFA7695
#
# TODO:
#  • Add option to show all keys with expired sigs.
#  • May not need to check if key is in keyring anymore, check database instead.
#  • TODO: CHECK: Are sigs on revoked UIDs must excluded?
#
# Key database structure:
#   pub (primary key information such as key ID, expiration, key length, etc)
#     fpr (full fingerprint of the primary key)
#     uid (1+ user IDs: creation timestamp, hash of ID and string ID)
#       rev (timestamp of revocation -- if it was revoked)
#       sig (timestamp and optional expiration of signature on this UID)
#     sub (1+ subkeys: key length, creation timestamp, key ID)
#       fpr (full fingerprint of the subkey)
#         rev (timestamp of revocation -- if it was revoked)
#         sig (timestamp and optional expiration of signature on this subkey)
#
# NOTE: Revoked keys and UIDs will not show up in the list.  Revoked sigs will!
#       Revocation is listed *before* the key signature being revoked!
################################################################################

use strict;
use warnings;

my $GPG_DATA_FILE = "/tmp/gpg-key-data.txt";
my $IS_DEBUG = 0;   # Flag for verbose debug mode.TODO: Make commandline option.
my @raw_data;       # Data dump from gpg keychain.
my $KEY_ID = '';    # Source key whose sigs we are looking for on other keys.
my $KEY_FPR = '';   # Full fingerprint of source key.
my $SIGNED_KEY_TMP; # Current key whose sigs we're checking for a $KEY_ID match.
my $IS_PRIMARY;     # {boolean} Is SIGNED_KEY_TMP the PRIMARY key (not a subkey)
my $UID_TMP;        # Current UID (uid|uat) whose sigs we are checking.
my $LATEST_SIG_REV_TIME; # Timestamp of latest sig or rev found so far.
my $NOW = time();   # Current timestamp used to check for sig expiration.
my $NO_EXPIRE = $NOW + 999999999; # A date guaranteed to be in the future.
my %SIGNED_UIDS;    # "KeyFpr:UID" : {bool} true if signed by non-revoked sig.
my %UIDS;           # "UID hash": "UID string" Mapping of UID hashes to strings.

validate_args();
@raw_data = get_raw_data();
parse_raw_data();
print_signed_keys();

################################################################################
# FUNCTIONS
################################################################################

sub print_debug {
  my ($message) = @_;
  $IS_DEBUG && print STDERR "DEBUG: $message";
}

# Parse command line arguments. Show help if needed.
# TODO: https://perldoc.perl.org/Getopt/Long.html#Getting-Started-with-Getopt%3a%3aLong
sub validate_args {
  my $error = 0;
  if (defined($ARGV[0]) && ($ARGV[0] ne '') ) {
    $KEY_ID = $ARGV[0];
    print_debug("KEY_ID: $KEY_ID\n");
  } else {
    $error = 1;
  }
  # Remove '0x' prefix if needed:
  $KEY_ID =~ s/^0x//;
  # Uppercase
  $KEY_ID = uc $KEY_ID;
  # Test if we already have full fingerprint:
  if ($KEY_ID =~ /^[0-9A-F]{40}$/) {
    $KEY_FPR = $KEY_ID;
  }
  # Reduce fingerprint to last 16 chars (gpg's "long" key ID) if needed:
  $KEY_ID =~ s/.*([0-9A-F]{16})$/$1/;
  # Make sure we have a valid looking key of 16 hex chars:
  if ($KEY_ID =~ /^[0-9A-F]{16}$/) {
    # Check if key is in our local keyring, if so, normalize to uppercase 16:
    my $command = "gpg --list-keys --keyid-format long ${KEY_ID} 2> /dev/null |".
                  "grep --extended-regexp --only-matching '[0-9A-F]*${KEY_ID}'";
    chomp( my $keyid_test = `$command` );
    if ($KEY_ID ne $keyid_test) {
       $error = 1;
       print STDERR "ERROR: key '${KEY_ID}' not found in your local keyring.\n";
    }
  } elsif ($KEY_ID ne '') {
    print STDERR "ERROR: key '${KEY_ID}' has wrong format or length.\n";
    $error = 1;
  }

  if ($error) {
    print STDERR
        "Please supply the long key ID (or full fingerprint with no ".
        "spaces) of the key whose signatures we are to search for.\n".
        "Examples:\n".
        "./gpg-keys-signed-by.pl C0C076132FFA7695\n".
        "./gpg-keys-signed-by.pl 9386A2FB2DA9D0D31FAF0818C0C076132FFA7695\n";
    exit 1;
  }
}

# Create the database file.
sub create_database {
  # Export gpg signature data:
  my $command = "gpg --with-colons --fast-list-mode --fingerprint --list-sigs ".
                "> ${GPG_DATA_FILE} 2> /dev/null";
  print_debug("Creating keyring database (${GPG_DATA_FILE})...");
  system($command);
  print_debug(" [DONE]\n");
}

# Load data from database and create it if needed.
# returns @raw_data
sub get_raw_data {
  # Create the database if it doesn't exist yet.
  if (! -e $GPG_DATA_FILE) {
    create_database();
  } else {
    print_debug("Found '$GPG_DATA_FILE'\n");
  }
  # Dump data file into array of lines
  open(DATA, $GPG_DATA_FILE) or die "ERROR: Can't open: '$GPG_DATA_FILE'.\n";
  @raw_data = <DATA>;
  close(DATA);
  return @raw_data;
}

# Parse each line of the database file.
sub parse_raw_data {
  # Process the database contents.
  foreach my $line (@raw_data) {
    parse_raw_data_line($line);
  }
}

# Parses a line of data from our database.
sub parse_raw_data_line {
  my ($line) = @_;
  my @items = split(/:/, $line);
  my $packet_type = $items[0];

  if ($packet_type eq 'pub') {
    # Primary key.
    $IS_PRIMARY = 1;
  } elsif ($packet_type eq 'sub') {
    # Subkey.
    $IS_PRIMARY = 0;
  } elsif ($IS_PRIMARY && $packet_type eq 'fpr') {
    # Primary key fingerprint.
    $SIGNED_KEY_TMP = $items[9];
    # Here we expand KEY_ID into the full fingerprint KEY_FPR:
    if ($KEY_FPR eq '' && $SIGNED_KEY_TMP =~ /${KEY_ID}$/) {
      $KEY_FPR = $SIGNED_KEY_TMP;
      print_debug("Expanded: ${KEY_ID} into ${KEY_FPR}\n");
    }
  } elsif ($IS_PRIMARY && $packet_type =~ /^(sig|rev)$/) {
    # Handle line of database containing signature OR revocation data.
    parse_raw_data_sigrev($packet_type, $items[4], $items[5], $items[6]);
  } elsif ($packet_type =~ /^(uid|uat)$/) {
    # Add to map of UID hash => human-readable UID:
    $UIDS{$items[7]} = $items[9];
    # User ID or picture UID will be saved for use in parse_raw_data_line_sig().
    $UID_TMP = $items[7];
    # Reset current signature timestamp as we begin a new UID with its sigs.
    $LATEST_SIG_REV_TIME = 0;
  }
}

# Handles a line of database containing signature OR revocation of a signature.
sub parse_raw_data_sigrev {
  my ($packet_type, $issued_by, $time, $sig_expire) = @_;
  if ($issued_by ne $KEY_ID) {
    return;
  }
  if ($packet_type eq 'sig') {
    # Signature on primary key.
    parse_raw_data_line_sig($time, $sig_expire);
  } elsif ($packet_type eq 'rev') {
    # Revocation of previous sig on primary key.
    parse_raw_data_line_rev($time);
  }
}

# Parses a single line of database containing signature data ONLY.
sub parse_raw_data_line_sig {
  my ($sig_time, $sig_expire) = @_;
  if ($sig_expire eq '') {
    $sig_expire = $NO_EXPIRE;
  }
  my $is_latest_sig = ($sig_time > $LATEST_SIG_REV_TIME) ? 1 : 0;
  my $sig_not_expired = ($sig_expire > $NOW) ? 1 : 0;
  if (! $sig_not_expired && $is_latest_sig) {
    print_debug("  EXPIRED SIG on: ${SIGNED_KEY_TMP}:$UIDS{$UID_TMP}\n");
  }
  if ($is_latest_sig) {
    # New "latest" value for latest sig / rev timestamp:
    $LATEST_SIG_REV_TIME = $sig_time;
  }
  # Check if sig is not expired and not revoked:
  if ($sig_not_expired && $is_latest_sig) {
    # Prefix the UID with the key it belongs to:
    my $qualified_uid = "${SIGNED_KEY_TMP}:${UID_TMP}";
    # Set key to UID and value to 1 (true) if signed, otherwise 0 if revoked.
    # Because there may be multiple sigs and revs on the same UID, this will
    # be overwritten until the last one wins (by date signed).
    # TODO: Check if above statement is actually true still?
    $SIGNED_UIDS{$qualified_uid} = 1;
  }
}

# Parses a single line of database containing revocation data.
sub parse_raw_data_line_rev {
  my ($rev_time) = @_;
  # Check if revocation happened after the last sig:
  my $sig_revoked = ($rev_time > $LATEST_SIG_REV_TIME) ? 1 : 0;
  if ($sig_revoked) {
    print_debug("  REVOKED SIG on: ${SIGNED_KEY_TMP}:$UIDS{$UID_TMP}\n");
    # New value for latest rev timestamp:
    $LATEST_SIG_REV_TIME = $rev_time;
    # Prefix the UID with the key it belongs to:
    my $qualified_uid = "${SIGNED_KEY_TMP}:${UID_TMP}";
    # Set key to UID and value to 0 (false) as sig has been revoked.
    # Because there may be multiple sigs and revs on the same UID, this will
    # be overwritten until the last one wins (by date signed).
    # TODO: Check if above statement is actually true still?
    $SIGNED_UIDS{$qualified_uid} = 0;
  }
}

# Print out the final list of keys that are properly signed by the provided key.
sub print_signed_keys {
  my $prev_signed_key = '';
  foreach my $qualified_uid (sort keys %SIGNED_UIDS) {
    # All SIGNED_UIDS were signed, but here we filter out any that were revoked.
    # Remember: if *any* UID is signed, then the whole key is "signed".
    if ($SIGNED_UIDS{$qualified_uid}) {
      my ( $signed_key, $uid ) = split(/:/, $qualified_uid);
      # Only print unique key fingerprints (remove duplicates caused by multiple
      # signed UIDs).  Also filter out the key provided by the user.
      if ($signed_key ne $prev_signed_key && $signed_key ne $KEY_FPR) {
        print $signed_key."\n";
        print_debug(" ↑ from UID: $UIDS{$uid}\n");
        $prev_signed_key = $signed_key;
      }
    }
  }
}
