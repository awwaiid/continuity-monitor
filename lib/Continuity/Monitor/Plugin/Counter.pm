package Continuity::Monitor::Plugin::Counter;

use Moose;
use Method::Signatures;

extends 'MooseX::Continuity::Widget';

method main {
  my $counter = 1;
  while(1) {
    $self->print("<div class=dialog title='Counter'>");
    $counter++;
    $self->print("Count: $counter<br>");
    $self->print(
      $self->cb_link( 'Add 10' => sub {
        $counter += 10;
      })
    );
    $self->print("</div>");
    $self->yield(1);
  }
}

1;

