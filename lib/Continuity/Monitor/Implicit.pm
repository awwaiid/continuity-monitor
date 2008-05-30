package Continuity::Monitor::Implicit;

=head1 NAME

Continuity::Monitor::Implicit - Start a Continuity::Monitor from the shell

=head1 SYNOPSIS

  perl -MContinuity::Monitor::Implicit application.pl

=head1 DESCRIPTION

This allows you to use Continuity::Monitor even on programs that don't
explicitly start a monitor for themselves. For now the one catch is that the
program's continuity server must be set as the $main::server package variable
(like "use vars qw( $server )").

=cut

use strict;
use Continuity::Monitor;

Continuity::Monitor->new( port => 8081 );

1;

