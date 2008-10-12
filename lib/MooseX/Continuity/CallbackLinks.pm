
package MooseX::Continuity::CallbackLinks;

use 5.10.0;
use Moose::Role;
use Data::UUID;

has 'uuid'   => (
  is      => 'ro', 
  isa     => 'Str', 
  default => sub { Data::UUID->new->create_str }
);

has callback => (is => 'rw', default => sub{{}});

# Given a name generate a unique field ID
sub field_name {
  my ($self, $name) = @_;
  return $self->uuid . '-' . $name;
}

sub cb_link {
  my ($self, $text, $subref) = @_;
  my $name = scalar $subref;
  $name =~ s/CODE\(0x(.*)\)/$1/;
  $self->callback->{$name} = $subref;
  return qq{<a href="?callback=$name">$text</a>};
}

sub cb_button {
  my ($self, $text, $subref) = @_;
  my $name = scalar $subref;
  $name =~ s/CODE\(0x(.*)\)/$1/;
  $self->callback->{$name} = $subref;
  return qq{<input type=submit name="$name" value="$text">};
}

sub process_callbacks {
  my ($self, $clear) = @_;
  $clear //= 1;
  my $name = $self->param('callback');
  if($name && defined $self->callback->{$name}) {
    $self->callback->{$name}->();
    $self->callback({}) if $clear;
    return 1;
  }
  foreach my $name (keys %{ $self->callback }) {
    if($self->param($name)) {
      $self->callback->{$name}->();
      $self->callback({}) if $clear;
      return 1;
    }
  }
  # Reset callback hash
  $self->callback({}) if $clear;
  return 0;
}


1;

