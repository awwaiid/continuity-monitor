package MooseX::Coro;

use Moose::Role;
use Coro::Generator;

has 'cont'   => (is => 'rw');
has 'output' => (is => 'rw');
has 'input'  => (is => 'rw');

sub process {
  my ($self, $input) = @_;
  $self->input($input);
  $self->{cont} ||= generator { while(1) { $self->main } };
  $self->{cont}->();
  return $self->output;
}

no warnings 'redefine';
sub yield {
  my ($self, $output) = @_;
  $self->output($output);
  Coro::Generator::yield();
  return $self->input;
}

1;

