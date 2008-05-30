#!/usr/bin/perl

use strict;
use Continuity;

Continuity->new( port => 8080 )->loop;

sub main {
  my $r = shift;
  my $browser = Browse->new( request => $r );
  $browser->main;
}

package Browse;

use PPI;
use PPI::HTML;
use Data::Dumper;

sub new {
  my ($class, %options) = @_;
  my $self = { %options };
  bless $self, $class;
  return $self;
}

sub display {
  my ($self, $content) = @_;
  $self->{request}->print($content);
  $self->{request}->next;
  $self->{request}->param; # Force params internal generation
  my %f = @{$self->{request}{request}{params}};
  return %f;
}

sub main {
  my ($self) = @_;
  while(1) {
    my $filename = $self->get_filename;
    $self->browse_file($filename);
  }
}

sub get_filename {
  my ($self) = @_;
  return "browse.pl";
}

sub browse_file {
  my ($self, $filename) = @_;
  my $doc = PPI::Document->new($filename);

  # Remove all that nasty documentation
  $doc->prune('PPI::Token::Pod');
  $doc->prune('PPI::Token::Comment');

  my $highlight = PPI::HTML->new(
    colors => {
    }
  );

  my $html = $highlight->html($doc);

  $self->display(qq|
<style>
body {
  background-color: #000;
  color: #fff;
}
.pod { color: #008080 }
.comment { color: #008080 }
.operator { color: #DD7700 }
.single { color: #999999 }
.double { color: #999999 }
.literal { color: #999999 }
.interpolate { color: #999999 }
.words { color: #999999 }
.regex { color: #9900FF }
.match { color: #9900FF }
.substitute { color: #9900FF }
.transliterate { color: #9900FF }
.number { color: #990000 }
.magic { color: #0099FF }
.cast { color: #339999 }
</style>
    <h1>Browse</h1>
    $html
  |);
}

