#!/usr/bin/perl

use strict;
use lib '../lib';
use Continuity::Monitor::CGI qw( inspect );
print "Content-type: text/html\n\n";

my $x = 5;

sub print_page {
  my $y = 23;
  print "printing page...<br>\n";
  print_hello();
}

sub print_hello {
  my $y = 'hiya';
  my $h = {
    a => 1,
    b => 2,
  };
  print "Hello...\n";
  inspect();
  print "world!";
}

print_page();

print "<br>x=$x<br><br>\n";
print "Goodbye!\n";

