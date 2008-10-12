package Continuity::Monitor::Plugin::Exit;

use Moose;
use Method::Signatures;
use Devel::StackTrace::WithLexicals;
use Data::Visitor::Callback;

with qw(
  MooseX::Coro
  MooseX::Continuity::Request
  MooseX::Continuity::CallbackLinks
);

method main {
  while(1) {
    $self->print("<div class=dialog title='Exit'>");
    $self->print($self->cb_link('EXIT' => sub {
      $self->print("<script>window.location = 'about:blank';</script>");
      $self->yield(0);
    }));
    $self->print("</div>");
    $self->yield(1);
    $self->process_callbacks;
  }
}

1;

