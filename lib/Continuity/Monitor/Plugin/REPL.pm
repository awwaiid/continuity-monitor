package Continuity::Monitor::Plugin::REPL;

our $VERSION = '0.01';

=head1 NAME

Continuity::Monitor::REPL - Web based REPL

=head1 SYNOPSYS

  use strict;
  use Continuity;
  use Continuity::REPL;

  use vars qw( $repl $server );

  $repl = Continuity::REPL->new;
  $server = Continuity->new( port => 8080 );
  $server->loop;

  sub main {
    my $request = shift;
    my $count = 0;
    while(1) {
      $count++;
      $print("Count: $count");
      $request->next;
    }
  }

The command line interaction looks like this:

  main:001:0> $server
  $Continuity1 = Continuity=HASH(0x86468c8);

  main:002:0> $server->{mapper}->{sessions}
  $HASH1 = {
             19392613106888830468 => Coro::Channel=ARRAY(0x8d82038),
             58979072056380208100 => Coro::Channel=ARRAY(0x8d78890)
           };

  main:003:0> Coro::State::list()                                                
  $ARRAY1 = [
              Coro=HASH(0x8d82208),
              Coro=HASH(0x8d78aa0),
              Coro=HASH(0x8d38b98),
              Coro=HASH(0x8d38a38),
              Coro=HASH(0x8b99248),
              Coro=HASH(0x825d6c8),
              Coro=HASH(0x81d7568),
              Coro=HASH(0x81d7518),
              Coro=HASH(0x81d7448)
            ];

=head1 DESCRIPTION

This provides a Devel::REPL shell for Continuity applications.

For now it is just amusing, but it will become useful once it can run the shell
within the context of individual sessions. Then it might be a nice diagnostic
or perhaps even development tool. Heck... maybe we can throw in a web interface
to it...

Also, this library forces the PERL_RL environment variable to 'Perl' since I
haven't been able to figure out how to hack Term::ReadLine::Gnu yet.

=cut

{
  package Devel::REPL::Continuity;
  use Moose;
  use Method::Signatures;
  extends 'Devel::REPL';
  with qw(
    MooseX::Coro
    MooseX::Continuity::CallbackLinks
  );

  has request => ( is => 'rw' );
  has output_result => (is => 'rw', default => '');

  has 'term' => (
    is => 'rw', required => 1,
    default => sub { }
  );

  no warnings 'redefine';

  sub print {
    my ($self, @ret) = @_;
    my $out = "@ret";
    #$out =~ s/\n/<br>/g;
    $out .= "\n";
    $self->output_result( $self->output_result . $out);
  }

  sub read {
    my ($self) = @_;
    my $prompt = $self->prompt;
    $self->output_result(
      $self->output_result
      . "\n"
      . $self->prompt
    );
    my $out = $self->output_result;
    my $id = $self->request->session_id;
    $self->request->print(qq{
      <div class=dialog id=repl title='Read-Eval-Print'>
        <pre>$out<input type=text name=cmd id=cmd size=60><input type=submit name=send value="Send">
        </pre>
        <script>document.getElementById('cmd').focus()</script>
      </div>
    });
    $self->yield(1);
    my $cmd = $self->request->param('cmd');
    $self->yield(0) if $cmd && $cmd eq 'exit';
    $self->output_result(
      $self->output_result
      . $cmd
      . '<br>'
    ) if $cmd;
    $cmd = undef if $cmd && $cmd eq 'exit';
    return $cmd;
  }

  method main {
    while($self->run_once) { }
  }
}

use Moose;
use Method::Signatures;

# For now we'll force Term::ReadLine::Perl since GNU doesn't work here
BEGIN { $ENV{PERL_RL} = 'Perl' }

use Devel::REPL;
use Coro;
use Coro::Event;

has repl => (is => 'rw');
has request => (is => 'rw');

=head1 METHODS

=head2 $c_repl = Continuity::REPL->new( repl => $repl );

Create and start a new REPL on the command line. Optionally pass your own Devel::REPL object. If you don't pass in $repl, a default is created.

=cut

sub BUILD {
  my $self = shift;
  unless($self->repl) {
    $self->repl( $self->default_repl );
  }
     # my $timer = Coro::Event->timer(interval => 0 );
  # async {
     # while ($timer->next) {
       # $self->repl->run_once;
     # }
  # };
  return $self;
}

=head2 default_repl

This internal method creates the default REPL if one isn't specified.

=cut

sub default_repl {
  my $self = shift;

  my $repl = Devel::REPL::Continuity->new( request => $self->request );
  $repl->load_plugin($_) for qw(
    FancyPrompt
    Packages
    Refresh
    Interrupt
    ShowClass
    History
    MultiLine::PPI
    LexEnv
    DDS
  );
    # Carp::REPL
    # DebugHelp
    # Colors
    # Completion CompletionDriver::LexEnv
    # CompletionDriver::Keywords

  $repl->fancy_prompt(sub {
    my $self = shift;
    sprintf '%s:%03d%s&gt; ',
      $self->can('current_package') ? $self->current_package : 'main',
      $self->lines_read,
      $self->can('line_depth') ? ':' . $self->line_depth : '';
  });

  $repl->fancy_continuation_prompt(sub {
    my $self = shift;
    my $pkg = $self->can('current_package') ? $self->current_package : 'main';
    $pkg =~ s/./ /g;
    sprintf '%s     %s* ',
      $pkg,
      $self->lines_read,
      $self->can('line_depth') ? $self->line_depth : '';
  });

  $repl->current_package('main');

  return $repl;
}

method process {
  return $self->repl->process();
}


=head1 SEE ALSO

L<Continuity>, L<Devel::REPL>, L<Coro::Debug>

=head1 AUTHOR

  Brock Wilcox <awwaiid@thelackthereof.org> - http://thelackthereof.org/

=head1 COPYRIGHT

  Copyright (c) 2008 Brock Wilcox <awwaiid@thelackthereof.org>. All rights
  reserved.  This program is free software; you can redistribute it and/or modify
  it under the same terms as Perl 5.10 or later.

=cut

1;

