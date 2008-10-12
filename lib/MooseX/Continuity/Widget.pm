package MooseX::Continuity::Widget;

use Moose;

with qw(
  MooseX::Coro
  MooseX::Continuity::Request
  MooseX::Continuity::CallbackLinks
);

after yield => sub {
  my $self = shift;
  $self->process_callbacks;
  return 1;
};

1;

