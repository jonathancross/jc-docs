#!/usr/bin/perl
#
# Search for keys signed by the provided key ID.
#
# Key database structure:
#   pub:u:4096:1:C0C076132FFA7695:... etc
#   fpr:::::::::9386A2FB2DA9D0D31FAF0818C0C076132FFA7695:
#   various: sub, sig, rev, uid, uat.
#   (each sub has a fpr as well)
################################################################################

use strict;
use warnings;

my $GPG_DATA_FILE = "/tmp/gpg-key-data.txt";

my $ERROR = 0;
my @raw_data;
my @signed_keys;
my $KEY_ID = '';
my $SIGNED_KEY_TMP;

validate_key_args();
@raw_data = get_raw_data();
parse_raw_data();

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
    print STDERR "Please supply the long key ID (or full fingerprint with no ".
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

sub parse_raw_data_line {
  my ($line) = @_;
  my @items = split(/:/, $line);
  my $packet_type = $items[0];
  if ($packet_type eq 'fpr') {
    $SIGNED_KEY_TMP = $items[9];
    #print "${SIGNED_KEY_TMP} ";
  } elsif ($packet_type eq 'sig') {
    my $issued_by = $items[4];
    if ($issued_by eq $KEY_ID) {
      #print " match: $line\n";
      push(@signed_keys, $SIGNED_KEY_TMP);
    }
  } elsif ($packet_type eq 'rev') {
    # TODO: Previous sig from $issued_by was revoked, so delete it.
    my $revoked_by = $items[4];
  }
}

sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

