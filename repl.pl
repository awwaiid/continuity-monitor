#!/usr/bin/perl

use strict;
use Continuity;
use Continuity::Monitor::REPL;

Continuity->new(
  port => 8080,
  cookie_session => 0,
  query_session => 'sid'
)->loop;

sub main {
  my $request = shift;
  my $repl = Continuity::Monitor::REPL->new( request => $request );
  $repl->repl->run;
  $request->print("exit detected!");
}

