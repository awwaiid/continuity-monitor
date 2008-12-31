package Continuity::Monitor::Plugin::CallStack;

use Moose;
use Method::Signatures;
use Devel::StackTrace::WithLexicals;
use Data::Visitor::Callback;

# has trace => ( is => 'rw' );

with qw(
  MooseX::Coro
  MooseX::Continuity::Request
  MooseX::Continuity::CallbackLinks
);

method print_trace {
  $self->print("<div class=dialog id=stacktrace title='Stacktrace'><ul>");
  # my @frames = $self->trace->frames;
  my $trace = Devel::StackTrace::WithLexicals->new(
    ignore_package => [qw( Devel::StackTrace Continuity::Monitor::CGI )]
  );  
  my @frames = $trace->frames;
  my $fieldnum = 0;
  foreach my $level (@frames) {
    $self->print("<li>" . $level->subroutine
      . " (" . $level->filename . ":" . $level->line . ")"
    );
    $self->print_lexicals($level->lexicals);
    $self->print("</li>");
  }
  $self->print("</ul></div>");
}

method print_lexicals {

  my $lexicals = Devel::StackTrace::WithLexicals->new(
    ignore_package => [qw( Devel::StackTrace Continuity::Monitor::CGI )]
  );

  my $fieldnum = 0;
  my $visitor = Data::Visitor::Callback->new(
    ignore_return_values => 1,

    scalar => sub {
      my ($v, $d) = @_;
      if(ref $d eq 'SCALAR') {
        my $fieldname = $self->field_name($fieldnum++);
        $self->print(qq|<input type=text name="$fieldname" value="|
          . $$d
          . qq|">|);
        $self->print($self->cb_button( Set => sub {
          $$d = $self->param($fieldname);
        }));
      } else {
        $self->print(ref $$d);
      }
    },

    hash => sub {
      my ($v, $d) = @_;
      $self->print("<ul>");
      foreach my $name (keys %$d) {
        $self->print("<li>$name: ");
        if(ref $d->{$name}) {
          $v->visit($d->{$name});
        } else {
          my $fieldname = $self->field_name($fieldnum++);
          $self->print(qq|<input type=text name="$fieldname" value="|
            . $d->{$name}
            . qq|">|);
          $self->print($self->cb_button( Set => sub {
            $d->{$name} = $self->param($fieldname);
          }));
        }
        $self->print("</li>\n");
      }
      $self->print("</ul>");
    }
  );
  $visitor->visit($lexicals);
  # use Data::Dumper;
  # print STDERR Dumper($lexicals);
}


method main {
  while(1) {
    $self->print_trace;
    $self->yield(1);
    $self->process_callbacks;
  }
}

1;

