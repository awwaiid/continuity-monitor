package Continuity::Monitor::CGI;

use lib '/home/awwaiid/projects/perl/Continuity/lib';
#use lib '/home/awwaiid/projects/perl/third-party/Carp-REPL-0.13/lib';
use Moose;
use Method::Signatures;

use IO::Handle;

use Continuity;
use Continuity::Monitor::REPL;

#use PadWalker qw( peek_my peek_our peek_sub closed_over );
use Devel::StackTrace::WithLexicals;

use Sub::Exporter;
Sub::Exporter::setup_exporter({
  exports => [qw( inspect )]
});

has trace => ( is => 'rw' );
has request => ( is => 'rw' );

sub inspect {
  print STDERR "Starting inspector...\n";
  STDERR->autoflush(1);
  STDOUT->autoflush(1);
  my $self = Continuity::Monitor::CGI->new(@_);
  $self->start_inspecting;
}

method start_inspecting {
  $self->trace( Devel::StackTrace::WithLexicals->new );
  my $server = Continuity->new(
    callback => \&main,
    port => 8080,
    debug_callback => sub { STDERR->print("@_\n") },
    callback => sub { $self->main(@_) },
  );
  $server->loop;
  print STDERR "Done inspecting!\n";
}

method scope_inspector($request) {
  my @pad = ();
  my $i = 0;
  while(!$@) {
    push @pad, peek_my $i++;
  }
}

method main($request) {
  $self->request($request);
  my $repl = Continuity::Monitor::REPL->new( request => $request );
  while($repl->repl->run_once) {
    $request->print("<pre>" . $self->trace->as_string . "</pre>");
  }
  Coro::Event::unloop();
  $request->print("Exiting...");
  $request->end_request;
}


1;

