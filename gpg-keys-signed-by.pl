#!/usr/bin/perl
#
# Search for keys signed by the provided key ID.
#
# USAGE:
#   ./gpg-keys-signed-by.pl C0C076132FFA7695
#
# TODO:
#  • Filter out subkeys owned by the requested key.
#  • Test if sigs on expired UIDs are handled correctly.
#  • If signed_keys was a hash instead of array, we wouldn't need uniq()
#
# Key database structure:
#   pub
#     fpr
#     uid|uid
#       sig
#       rev
#     sub
################################################################################

use strict;
use warnings;

my $GPG_DATA_FILE = "/tmp/gpg-key-data.txt";

my $ERROR = 0;
my @raw_data;       # Data dump from gpg keychain.
my @signed_keys;    # Array of key fingerprints representing signed keys.
my $KEY_ID = '';    # Source key whose sigs we are looking for on other keys.
my $SIGNED_KEY_TMP; # Current key whose sigs we're checking for a $KEY_ID match.
my $UID_TMP;        # Current UID (uid|uat) whose sigs we are checking.
my $SIG_REV_TIME;   # Timestamp to determine if sig is revoked
my %signed_uids;    # UID: boolean indicating if signed by non-revoked sig.
my %keys_by_uid;    # UID: mapped to key fingerprint.

validate_key_args();
@raw_data = get_raw_data();
parse_raw_data();
verify_signed_uids();

foreach my $key (sort(uniq(@signed_keys))) {
  print "$key\n"
}

################################################################################
# FUNCTIONS
################################################################################
# Commandline args
sub validate_key_args {

  if (defined($ARGV[0]) && ($ARGV[0] ne '') ) {
    $KEY_ID = $ARGV[0];
    print STDERR "DEBUG: KEY_ID: $KEY_ID\n";
  } else {
    $ERROR = 1;
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
       $ERROR = 1;
       print STDERR "ERROR: key '${KEY_ID}' not found in your local keyring.\n";
    }
  } elsif ($KEY_ID ne '') {
    print STDERR "ERROR: key '${KEY_ID}' has wrong format or length.\n";
    $ERROR = 1;
  }

  if ($ERROR) {
    print STDERR
        "Please supply the long key ID (or full fingerprint with no ".
        "spaces) of the key whose signatures we are to search for.\n".
        "Examples:\n".
        "./gpg-keys-signed-by.pl C0C076132FFA7695\n".
        "./gpg-keys-signed-by.pl 9386A2FB2DA9D0D31FAF0818C0C076132FFA7695\n";
    exit 1;
  }
}

sub create_database {
  # Export gpg signature data
  my $command = "gpg --with-colons --fast-list-mode --fingerprint --list-sigs ".
                "> ${GPG_DATA_FILE} 2> /dev/null";
  print STDERR "Creating keyring database (${GPG_DATA_FILE})...";
  system($command);
  print STDERR " [DONE]\n";
}

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

sub parse_raw_data {
  # Process the database contents.
  foreach my $line (@raw_data) {
    parse_raw_data_line($line);
  }
}

sub verify_signed_uids {
  # Filter through signed_uids and add the key for each signed ID to signed_keys
  foreach my $uid (sort keys %signed_uids) {
    print STDERR "$keys_by_uid{$uid}: $uid = $signed_uids{$uid}\n";
    # All signed_uids were signed, but here we filter out any that were revoked.
    if ($signed_uids{$uid}) {
      push(@signed_keys, $keys_by_uid{$uid});
    }
  }
}

sub parse_raw_data_line {
  my ($line) = @_;
  my @items = split(/:/, $line);
  my $packet_type = $items[0];
  if ($packet_type eq 'fpr') { # Key fingerprint.  This also includes subkeys.
    $SIGNED_KEY_TMP = $items[9];
  } elsif ($packet_type =~ /^(sig|rev)$/) { # Signature or revocation.
    my $issued_by = $items[4];
    my $sig_time = $items[5];
    if ($issued_by eq $KEY_ID) {
      if ($sig_time > $SIG_REV_TIME) {
        # New value for latest sig / rev timestamp:
        $SIG_REV_TIME = $sig_time;
        # Set key to UID and value to 1 if signed, otherwise 0 if revoked.
        # Because there may be multiple sigs and rev from the same key, this
        # will be overwritten until the last one wins (by date signed).
        $signed_uids{$UID_TMP} = ($packet_type eq 'sig') ? 1 : 0;
      }
    }
  } elsif ($packet_type =~ /^(uid|uat)$/) { # User ID or picture.
    # Reset these values as we begin a new UID with sigs.
    $SIG_REV_TIME = 0;
    $UID_TMP = $items[7];
    $keys_by_uid{$UID_TMP} = $SIGNED_KEY_TMP;
  }
}

sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

