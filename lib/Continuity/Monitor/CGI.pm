package Continuity::Monitor::CGI;

use Moose;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
  _export_to_main => 1,
  as_is => [\&inspect]
);

use Method::Signatures;

use IO::Handle;
use Data::Dumper;

use Devel::StackTrace::WithLexicals;

use Continuity;
    
use Continuity::Monitor::Plugin::CallStack;
use Continuity::Monitor::Plugin::REPL;
use Continuity::Monitor::Plugin::Exit;
use Continuity::Monitor::Plugin::Counter;
use Continuity::Monitor::Plugin::FileEdit;

has request => ( is => 'rw' );
has trace => ( is => 'rw' );

sub inspect {
  print STDERR "Starting inspector...\n";
  STDERR->autoflush(1);
  STDOUT->autoflush(1);
  my $self = Continuity::Monitor::CGI->new(@_);
  $self->start_inspecting;
}

method start_inspecting {
  my $trace = Devel::StackTrace::WithLexicals->new(
    ignore_package => [qw( Devel::StackTrace Continuity::Monitor::CGI )]
  );
  $self->trace( $trace );
  my $docroot = $INC{'Continuity/Monitor/CGI.pm'};
  $docroot =~ s/CGI.pm/htdocs/;
  my $server = Continuity->new(
    callback => \&main,
    port => 8080,
    docroot => $docroot,
    debug_callback => sub { STDERR->print("@_\n") },
    callback => sub { $self->main(@_) },
  );
  $server->loop;
  print STDERR "Done inspecting!\n";
}


method print_header {
  my $id = $self->request->session_id;
  $self->request->print(qq|
    <html>
      <head>
        <title>Continuity::Monitor</title>
        <link rel="stylesheet" type="text/css" href="htdocs/mon.css">
        <link rel="stylesheet" href="js/themes/flora/flora.dialog.css" type="text/css" media="screen">
        <link rel="stylesheet" href="js/jquery-treeview/jquery.treeview.css" />
        <script type="text/javascript" src="js/jquery-1.2.6.js"></script>
        <script type="text/javascript" src="js/jquery.ui.all.js"></script>
        <script type="text/javascript" src="js/jquery-treeview/jquery.treeview.js"></script>
        <script type="text/javascript" src="js/jquery.cookie.js"></script>
        <script type="text/javascript" src="mon.js"></script>
      </head>
      <body class=flora>
        <input type=hidden name=sid value="$id">
  |);
}

method print_footer {

  $self->request->print(qq|
      </body>
    </html>
  |);
}


our $t;
method main($request) {
  $self->request($request);
  $t = $self->trace;
  my @plugins = (
    Continuity::Monitor::Plugin::REPL->new( request => $request ),
    Continuity::Monitor::Plugin::CallStack->new( request => $request, trace => $t ),
    Continuity::Monitor::Plugin::Exit->new( request => $request ),
    Continuity::Monitor::Plugin::Counter->new( request => $request ),
    Continuity::Monitor::Plugin::FileEdit->new( request => $request ),
  );
  my $continue = 1;
  do {
    $self->print_header;
    foreach my $plugin (@plugins) {
      $continue &&= $plugin->process();
    }
    $self->print_footer;
    $self->request->next if $continue;

  } while($continue);
  Coro::Event::unloop();
  $request->print("Exiting...");
  $request->end_request;
}

1;

