#!/usr/bin/perl
# Drop-in replacement for /usr/bin/mail that uses Mail.app (via an
# applescript) rather than sendmail to send mail.  Unlike /usr/bin/mail,
# you can't use it for reading mail.
#
# usage: mail [<options>] <recipients>
#   options:
#     -v       be verbose
#     -g       activate Mail.app to approve the message
#     -F <from>  specify the From: address
#     -R <replyto> specify the Reply-To: address
#     -b <bcc>   specify Bcc: recipients in a comma-separated list
#     -c <cc>    specify Cc: recipients in a comma-separated list
#     -s <subject> specify the message subject
#
# The body of the message is read from standard input.
#
# Author: Nathaniel Nystrom <nystrom@cs.cornell.edu>
# This software is in the public domain.
#
# Support for attachments added by Jonathan Cross (jonathancross.com) - WTFPL
# https://github.com/jonathancross/jc-docs/blob/master/apple-mail.pl

use strict;
use Cwd 'abs_path';
$|++;

my ($verbose, $gui);
my ($from, $replyto, @to, @cc, @bcc, $subject, $body, $attachment);
my $prog;
($prog = $0) =~ s|.*/||;

while (@ARGV) {
  my $arg = shift @ARGV;

  if ($arg eq '-v') {
    $verbose++;
  }
  elsif ($arg eq '-g') {
    $gui++;
  }
  elsif ($arg eq '-F') {
    $from = shift @ARGV || &usage("missing sender");
  }
  elsif ($arg eq '-R') {
    $replyto = shift @ARGV || &usage("missing reply-to address");
  }
  elsif ($arg eq '-i' || $arg eq '-l' || $arg eq '-n') {
    # ignore; for /usr/bin/mail compatibility
  }
  elsif ($arg eq '-N' || $arg eq '-f' || $arg eq '-u') {
    &usage("invalid option $arg; $prog cannot be used for reading mail");
  }
  elsif ($arg eq '-s') {
    $subject = shift @ARGV || &usage("missing subject");
  }
  elsif ($arg eq '-c') {
    my $list = shift @ARGV || &usage("missing Cc list");
    @cc = split /\s*,\s*/, $list;
  }
  elsif ($arg eq '-b') {
    my $list = shift @ARGV || &usage("missing Bcc list");
    @bcc = split /\s*,\s*/, $list;
  }
  elsif ($arg eq '-a') {
    $attachment = abs_path(shift @ARGV) || &usage("missing attachment path");
  }
  elsif ($arg =~ /^-/) {
    &usage("invalid option $arg");
  }
  else {
    @to = ($arg, @ARGV);
    last;
  }
}

if ($attachment && ! -f $attachment) {
  &usage("attachment file '$attachment' does not exist")
}

&usage("missing recipients") unless @to;

unless (defined $subject) {
  print "Subject: ";
  $subject = <STDIN> || '';
  chomp $subject;
}

$body = '';

while (<STDIN>) {
  $body .= $_;
}

$replyto = $replyto || $from;

my $script = <<"EOS";
tell application "Mail"
  set newMessage to make new outgoing message
  tell newMessage
    set subject to "$subject"
EOS

$script .= &get_formatted_body($body, $attachment);

for (@to)  { $script .= &recipient('to', $_); }
for (@cc)  { $script .= &recipient('cc', $_); }
for (@bcc) { $script .= &recipient('bcc', $_); }

my $visible = $gui ? "true" : "false";
my $activate = $gui ? "activate" : "send newMessage";
my $fromln = $from ? "set sender to \"$from\"" : "";
my $replytoln = "";

# Doesn't work!  Anyone know why?
#my $replytoln = $replyto ? "set reply to to \"$replyto\"" : "";

$script .= <<"EOS";
    $fromln
    $replytoln
    set visible to $visible
  end tell
  $activate
end tell
EOS

$script .= &plain_text_hack();

if ($verbose >= 1) {
  print "From: $from\n" if $from;
  print "Reply-To: $replyto\n" if $replyto;
  print "To: ", join(',', @to), "\n" if @to;
  print "Cc: ", join(',', @cc), "\n" if @cc;
  print "Bcc: ", join(',', @bcc), "\n" if @bcc;

  if ($verbose >= 2) {
    print "Script >>>\n";
    print $script;
    print "<<<\n";
    print "\n";
    print $body;
  }
}

exec("osascript -e '$script' > /dev/null");
exit 0;

sub plain_text_hack {
  return <<"EOS";
  delay 0.9
  -- Set message format to plain text:
  tell application "System Events" to keystroke "t" using {command down, shift down}
EOS
}

sub get_formatted_body {
  my ($body, $attachment) = @_;
  if ($attachment) {
    return <<"EOS";
    set content to "$body" & return & return
    make new attachment with properties {file name:"$attachment"} at after the last word of the last paragraph
EOS
  }
  return <<"EOS";
    set content to "$body"
EOS
}

sub recipient {
  my ($type,$addr) = @_;
  return <<"EOS"
    make new $type recipient at end of $type recipients with properties {address: "$addr"}
EOS
}

sub usage {
  my $error = shift;
  print STDERR "Error: $error\n" if $error;
  print STDERR <<"EOS";
usage: $prog [<options>] <recipients>
  options:
    -v           be verbose
    -g           activate Mail.app to approve the message
    -a <path>    full path to a file attachment
    -F <from>    specify the From: address
    -R <replyto> specify the Reply-To: address
    -b <bcc>     specify Bcc: recipients in a comma-separated list
    -c <cc>      specify Cc: recipients in a comma-separated list
    -s <subject> specify the message subject
EOS
  exit 1;
}
