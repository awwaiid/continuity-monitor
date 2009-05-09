package Continuity::Monitor::CGI;

=head1 NAME

Continuity::Monitor::CGI - Inspect and debug CGI apps with an in-browser UI

=head1 SYNOPSIS

  use CGI;
  use Continuity::Monitor::CGI;

  print "Content-type: text/html\n\n";
  for my $i (1..10) {
    print "$i cookies...<br>";
    inspect() if $i == 5;
  }

=head1 DESCRIPTION

This class is a drop-in web based inspector for plain CGI (or other CGI-based)
applications. Include the library, and then call inspect(). In your server
error logs you'll see something like "Please connect to localhost:8080". When
you do, you'll be greeted with an inspection UI which includes a stack trace,
REPL, and other goodies.

=cut

use strict;
use Continuity;
use Continuity::RequestCallbacks;
use Sub::Exporter -setup => {
  exports => [ qw(inspect ) ]
};

=head1 EXPORTED SUBS

=head2 inspect()

This starts the Continuity server and inspector on the configured port
(defaulting to 8080).

=cut

sub inspect {
  print STDERR "Starting inspector...\n";
  require IO::Handle;
  STDERR->autoflush(1);
  STDOUT->autoflush(1);
  my $self = Continuity::Monitor::CGI->new(@_);
  $self->start_inspecting;
}

=head1 METHODS

These methods are all internal. All you have to do is call inspect().

=head2 Continuity::Monitor::CGI->new()

Create a new monitor object.

=cut

sub new {
  my ($class, %params) = @_;
  my $self = {
    port => 8080,
    plugins => [qw(
      Exit REPL
    )],
    # REPL CallStack Exit Counter FileEdit
    plugin_objects => [],
    html_headers => [],
    %params
  };
  bless $self, $class;
  return $self;
}

=head2 $self->start_inspecting

Load plugins and start inspecting!

=cut

sub start_inspecting {
  my ($self) = @_;
  $self->load_plugins;
  $self->start_server;
}
  
  # use Devel::StackTrace::WithLexicals;
  # my $trace = Devel::StackTrace::WithLexicals->new(
    # ignore_package => [qw( Devel::StackTrace Continuity::Monitor::CGI )]
  # );
  # $self->trace( $trace );

=head2 $self->start_server

Initialize the Continuity server, and begin the run loop.

=cut

sub start_server {
  my ($self) = @_;
  my $docroot = $INC{'Continuity/Monitor/CGI.pm'};
  $docroot =~ s/CGI.pm/htdocs/;
  my $server = Continuity->new(
    port => $self->{port},
    docroot => $docroot,
    callback => sub { $self->main(@_) },
    #debug_callback => sub { STDERR->print("@_\n") },
  );
  $server->loop;
  print STDERR "Done inspecting!\n";
}

=head2 $self->display

Display the current page, based on $self->{content}

=cut

sub display {
  my ($self, $content) = @_;
  my $id = $self->request->session_id;
  my $html_headers = join '', @{ $self->{html_headers} };
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
        $html_headers
      </head>
      <body class=flora>
        <input type=hidden name=sid value="$id">
        $content
      </body>
    </html>
  |);
}

=head2 $self->request

Returns the current request obj

=cut

sub request {
  my ($self) = @_;
  return $self->{request};
}

=head2 $self->load_plugins

Load all of our plugins.

=cut

sub load_plugins {
  my ($self) = @_;
  my $base = "Continuity::Monitor::Plugin::";
  foreach my $plugin (@{ $self->{plugins} }) {
    my $plugin_pkg = $base . $plugin;
    eval "use $plugin_pkg";
    my $plugin_instance = $plugin_pkg->new( manager => $self );
    push @{ $self->{plugin_objects} }, $plugin_instance;
  }
}

=head2 $self->main

This is executed as the entrypoint for inspector sessions.

=cut

sub main {
  my ($self, $request) = @_;
  $self->{request} = $request; # For plugins to use
  $self->{do_exit} = 0;
  do {
    my $content = '';
    foreach my $plugin (@{$self->{plugin_objects}}) {
      $content .= $plugin->process();
    }
    $self->display($content);
    $request->next->execute_callbacks
      unless $self->{do_exit};
  } until($self->{do_exit});
  Coro::Event::unloop();
  $request->print("Exiting...");
  $request->end_request;
}

1;

