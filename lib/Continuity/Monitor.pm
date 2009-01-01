package Continuity::Monitor;

use strict;
use warnings;
no warnings 'redefine';

use Continuity;
use Continuity::Inspector;
use Data::Dumper;
use HTML::Entities;
use PadWalker 'peek_my';
use Moose;

use Method::Signatures;

use IO::Handle;
use Data::Dumper;

use Devel::StackTrace::WithLexicals;

use Continuity::Monitor::Plugin::CallStack;
use Continuity::Monitor::Plugin::REPL;
use Continuity::Monitor::Plugin::Exit;
use Continuity::Monitor::Plugin::Counter;
use Continuity::Monitor::Plugin::FileEdit;


our $VERSION = '0.02';

=head1 NAME

Continuity::Monitor - monitor and inspect a Continuity server

=head1 SYNOPSIS

  #!/usr/bin/perl

  use strict;
  use Continuity;
  use Continuity::Monitor;

  my $server = new Continuity( port => 8080 );
  my $monitor = Continuity::Monitor->new( server => $server, port => 8081,  );
  $server->loop;

=head1 DESCRIPTION

B<NOTE: Currently this is broken, only Continuity::Monitor::CGI works. But I wanted to get it out on CPAN anyway.>

This is an application to monitor and inspect your running application. It has
its own web interface on a separate port. It is very rough!

The monitor does several things. First, this is a monitoring tool for working
with the sessions your server is running. You can view and kill each session.
Secondly it is an inspector for each session -- letting you see the current
state including variables. And third, it will let you actually change the
values of these sessions, or even run code in their context.

(well... it _will_ do all those things :) )

=head1 METHODS

=head2 $monitor = Continuity::Monitor->new( server => $server, ... )

This is just like Continuity->new, and takes all of the same parameters, except
that instead of running your code it is a self-contained application.

=cut

sub new {
  my ($class, %ops) = @_;
  $ops{server} or die "server is a required parameter; pass in the Continuity server for C::Monitor to inspect";
  my $self = {
    port => 8081, # override default port to avoid a conflict
    %ops,
  };

  # We don't save the server... because we don't need it and because weird
  # things happen when we do :)
  $self->{continuity} = Continuity->new(
      port => $self->{port},
      cookie_session => 'monitor_sid',
      callback => sub { $self->main(@_) },
  );

  bless $self, $class;

}

has request => ( is => 'rw' );
has trace => ( is => 'rw' );

method main ($request) {
  $self->request($request);
  my $sessions = $self->{server}->{mapper}->{sessions} or die;
  my $session_count = scalar keys %$sessions;
  my @sess = sort keys %$sessions;
  $request->print(
    qq{$session_count sessions:<br><ul>}, 
    map({ qq{<li><a href="?inspect_sess=$_">$_</a></li>\n} } @sess),
    qq{/ul>}
  );
  $request->next;
  my $session = $request->param('inspect_sess');

#  my $trace = Devel::StackTrace::WithLexicals->new(
#    ignore_package => [qw( Devel::StackTrace Continuity::Monitor::CGI )]
#  );
  my @plugins = (
    Continuity::Monitor::Plugin::REPL->new( request => $request ),
    # Continuity::Monitor::Plugin::CallStack->new( request => $request, trace => $trace ), # XXX silly!
    Continuity::Monitor::Plugin::CallStack->new( request => $request ),
    Continuity::Monitor::Plugin::Exit->new( request => $request ),
    Continuity::Monitor::Plugin::Counter->new( request => $request ),
    Continuity::Monitor::Plugin::FileEdit->new( request => $request ),
  );
  my $continue = 1;
  do {
    $self->print_header;
    foreach my $plugin (@plugins) {
      # $continue &&= $plugin->process();
      Continuity::Inspector->new( callback => sub {
          $continue &&= $plugin->process();
      })->inspect( $sessions->{$session} );
    }
    $self->print_footer;
    $self->request->next if $continue;

  } while($continue);
  $request->print("Exiting...");
  # sdw don't think unlook or $request->finish are needed... in fact more likely to cause problems.
}

method print_header {
$SIG{__DIE__} = sub { use Carp; Carp::confess; };
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

1;


__END__

the old stuff:

sub main {
  my ($self, $request) = @_;
  $self->{request} = $request;
  while(1) {
    my $sessions = $self->{server}->{mapper}->{sessions} or die;
    my $session_count = scalar keys %$sessions;
    my @sess = sort keys %$sessions;
    @sess = map { qq{<li><a href="?inspect_sess=$_">$_</a></li>\n} } @sess;
    $request->print("$session_count sessions:<br><ul>@sess</ul>");
    $request->next;
    my $sess = $request->param('inspect_sess');
    if($sess) {
      $self->inspect_session($sessions->{$sess});
    }
  }
}

sub get_session_vars {
  my ($self, $session) = @_;
  my $request = $self->{request};
  my @vars;
  my $inspector = Continuity::Inspector->new( callback => sub {
    $Data::Dumper::Sortkeys = 1;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Maxdepth = 2;
    for my $i (1..100) { 
      my $vars = eval { peek_my($i) } or last;
      my ($package, $filename, $line, $subroutine) = caller($i-1);
      my ($package2, $filename2, $line2, $subroutine2) = caller($i);
      # Skip over Continuity and Coro specific frames
      next if $package =~ /^(Continuity|Coro)/;
      next if $subroutine2 =~ /^(Continuity|Coro)::/;
      push @vars, {
        level => $i,
        package => $package,
        filename => $filename,
        line => $line,
        subroutine => $subroutine2,
        vars => $vars,
        expand => 0,
      };
    }
  });
  $inspector->inspect( $session );
  return @vars;
}


sub inspect_session {
  my ($self, $session) = @_;
  my $request = $self->{request};

  my @explore = $self->get_session_vars($session);

  #$Data::Dumper::Maxdepth = 4;
  #$request->print("<pre>DUMP:\n\n" . Dumper(\@explore) . "\n\n");

  while(1) {
    $request->print(qq{
      <a href="?action=exit">Exit</a><br>
      <a href="?action=repl">REPL</a><br>
      <ul>
    });
    my $offset = 0;
    my $tree = [];
    foreach my $scope (@explore) {
      $request->print(qq{
        <li>
          <a href="?toggle=$offset">+</a>
          $scope->{subroutine} ($scope->{filename}:$scope->{line})
      });
      if($scope->{expand}) {
        $request->print("<ul><li><pre>");
        my $var_dump = join '</pre></li><li><pre>',
        map { encode_entities("$_ = " . Dumper($scope->{vars}{$_})) } keys %{$scope->{vars}};
        $request->print($var_dump);
        $request->print("</li></ul>");
      }
      $request->print("</li>");
      $offset++;
    }
    $request->print('</ul>');
    $request->next;
    last if $request->param('action') eq 'exit';
    if($request->param('action') eq 'repl') {
      $self->repl($session);
    }
    my $scope = $request->param('toggle');
    $explore[$scope]->{expand} += 1;
    $explore[$scope]->{expand} %= 2;
  }
}

sub repl {
  my ($self, $session) = @_;
  my $inspector = Continuity::Inspector->new( callback => sub {
    my $repl = Continuity::Monitor::REPL->new( request => $self->{request} );
    $repl->repl->run;
  });
  $inspector->inspect( $session );
}


1;

