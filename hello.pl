#!/usr/bin/perl

use strict;
use lib 'lib';
use Continuity::Monitor::CGI;

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
  print "Hello...\n";
  Continuity::Monitor::CGI::inspect();
}

print_header();
print_page();

print "Goodbye... $x\n";


