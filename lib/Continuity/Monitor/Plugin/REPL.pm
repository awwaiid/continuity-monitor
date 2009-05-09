package Continuity::Monitor::Plugin::REPL;

use strict;
use base 'Continuity::Monitor::Plugin';
use PadWalker qw(peek_my);
use Data::Alias;

our $VERSION = '0.01';

sub process {
  my $self = shift;

  my $output = $self->{output} || '';

  # Find depth
  my $level = 0;
  while(1) {
    my ($package, $filename, $line) = caller($level);
    last if $package !~ /^(Continuity|Coro)/;
    $level++;
  }

  # Get our my vars at that depth
  my $peekaboo = peek_my($level + 1);

  # For each of them, we'll construct an alias to use as part of our eval
  my $alias_eval = '';
  foreach my $var (keys %$peekaboo) {
    $alias_eval .= "my $var; alias $var = \${ \$peekaboo->{'$var'} };";
  }

  if(my $code = $self->param('cmd')) {
      my $new_output = "\n> " . $code . "\n";
      $new_output .= eval($alias_eval . $code);
      $new_output .= "Error: $@\n" if $@;
      $new_output =~ s{<}{\&lt;}g;
      $output .= $new_output;
  }
  $self->{output} = $output;

  $output = qq{
    <div class=dialog id=repl title='Read-Eval-Print'>
      <pre>
        $output
      </pre>
      &gt; <input type=text name=cmd id=cmd size=40>
      <input type=submit name=send value="Send"></pre>
      <script>document.getElementById('cmd').focus()</script>
    </div>
  };

  return $output;
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

