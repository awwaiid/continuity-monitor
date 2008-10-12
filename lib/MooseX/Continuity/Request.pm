package MooseX::Continuity::Request;

use Moose::Role;

has request => (is => 'rw');

sub param {
  my ($self, @v) = @_;
  return $self->request->param(@v);
}

sub params {
  my ($self, @v) = @_;
  return $self->request->params(@v);
}

sub next {
  my ($self) = @_;
  $self->request->next;
  return $self;
}

sub print {
  my $self = shift @_;
  $self->request->print(@_);
}

1;

