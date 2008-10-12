#!/usr/bin/perl

use strict;
use lib '../lib';
use Continuity::Monitor::CGI qw( inspect );

my $x = 5;

sub print_header {
  print "Content-type: text/html\n\n";
}

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

#chdir('..');
print_header();
print_page();

print "<br>x=$x<br><br>\n";
print "Goodbye!\n";


