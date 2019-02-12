#!/usr/bin/perl
#
# Search for keys signed by the provided key ID.
#
# USAGE:
#   ./gpg-keys-signed-by.pl C0C076132FFA7695
#
# TODO:
#  • Filter out the requested key itself.
#  • Test if sigs on expired UIDs are handled correctly.
#  • BUG: Need to filter out sigs from expired keys.
#
# Key database structure:
#   pub
#     fpr
#     uid
#       sig
#       rev
#     sub
#       fpr
#         sig
#         rev
################################################################################

use strict;
use warnings;

my $GPG_DATA_FILE = "/tmp/gpg-key-data.txt";

my @raw_data;       # Data dump from gpg keychain.
my $KEY_ID = '';    # Source key whose sigs we are looking for on other keys.
my $SIGNED_KEY_TMP; # Current key whose sigs we're checking for a $KEY_ID match.
my $IS_PRIMARY;     # {boolean} Is SIGNED_KEY_TMP the PRIMARY key (not a subkey)
my $UID_TMP;        # Current UID (uid|uat) whose sigs we are checking.
my $SIG_REV_TIME;   # Timestamp to determine if sig is revoked
my %signed_uids;    # KEY:UID: {boolean} true if signed by non-revoked sig.

validate_args();
@raw_data = get_raw_data();
parse_raw_data();
print_signed_keys();

################################################################################
# FUNCTIONS
################################################################################

# Parse command line arguments. Show help if needed.
sub validate_args {
  my $error = 0;
  if (defined($ARGV[0]) && ($ARGV[0] ne '') ) {
    $KEY_ID = $ARGV[0];
    print STDERR "DEBUG: KEY_ID: $KEY_ID\n";
  } else {
    $error = 1;
  }

  # Remove '0x' prefix if needed:
  $KEY_ID =~ s/^0x//;

  # Uppercase
  $KEY_ID = uc $KEY_ID;

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
  # Export gpg signature data
  my $command = "gpg --with-colons --fast-list-mode --fingerprint --list-sigs ".
                "> ${GPG_DATA_FILE} 2> /dev/null";
  print STDERR "Creating keyring database (${GPG_DATA_FILE})...";
  system($command);
  print STDERR " [DONE]\n";
}

# Load data from database and create it if needed.
sub get_raw_data {
  # Create the database if it doesn't exist yet.
  if (! -e $GPG_DATA_FILE) {
    create_database();
  } else {
    print STDERR "DEBUG: Found '$GPG_DATA_FILE'\n";
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
  } elsif ($IS_PRIMARY && $packet_type =~ /^(sig|rev)$/) {
    # Signature or revocation on primary key.
    parse_raw_data_line_sig($packet_type, $items[4], $items[5]);
  } elsif ($packet_type =~ /^(uid|uat)$/) {
    # User ID or picture UID will be saved for use in parse_raw_data_line_sig().
    $UID_TMP = $items[7];
    # Reset current revocation time as we begin a new UID with its sigs.
    $SIG_REV_TIME = 0;
  }
}

# Parses a single line of data containing signature / revocation data.
sub parse_raw_data_line_sig {
  my ($packet_type, $issued_by, $sig_time) = @_;
  if ($issued_by eq $KEY_ID) {
    # print STDERR "Filtering: $SIGNED_KEY_TMP: $UID_TMP : $packet_type: $sig_time\n";
    if ($sig_time > $SIG_REV_TIME) {
      # New value for latest sig / rev timestamp:
      $SIG_REV_TIME = $sig_time;

      # Prefix the UID with the key it belongs to:
      my $qualified_uid = "${SIGNED_KEY_TMP}:${UID_TMP}";

      # Set key to UID and value to 1 if signed, otherwise 0 if revoked.
      # Because there may be multiple sigs and rev from the same key on a UID,
      # this will be overwritten until the last one wins (by date signed).
      $signed_uids{$qualified_uid} = ($packet_type eq 'sig') ? 1 : 0;
    }
  }
}

# Print out the final list of keys that were signed by the provided key.
sub print_signed_keys {
  my $prev_signed_key = '';
  foreach my $qualified_uid (sort keys %signed_uids) {
    # All signed_uids were signed, but here we filter out any that were revoked.
    # Remember: if *any* UID is signed, then the whole key is "signed".
    if ($signed_uids{$qualified_uid}) {
      my ( $signed_key, $uid ) = split(/:/, $qualified_uid);
      # Only print unique key fingerprints (remove duplicates caused by multiple
      # signed UIDs)
      if ($signed_key ne $prev_signed_key) {
        print $signed_key."\n";
        $prev_signed_key = $signed_key;
      }
    }
  }
}
