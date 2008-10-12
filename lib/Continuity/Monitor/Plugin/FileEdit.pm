package Continuity::Monitor::Plugin::FileEdit;

use Moose;
use Method::Signatures;
use File::Slurp;
use HTML::Entities;

extends 'MooseX::Continuity::Widget';

method main {
  my $counter = 1;
  while(1) {
    $self->print("<div class=dialog title='File Edit'>");
    my @files = sort values %INC;
    @files = grep !/home/, @files;
    @files = map { my $f = $_; "<li>" . $self->cb_link( $f => sub {
      $self->edit_file($f);
    }) . "</li>" } @files;
    $self->print("<ul>@files</ul>");
    $self->print($self->cb_button('gah'   => sub { print STDERR "Gah\n" }));
    $self->print("</div>");
    $self->yield(1);
  }
}

method edit_file($filename) {
  my $content = read_file($filename);
  $content = encode_entities($content);
  my $textarea_name = $self->field_name('content');
  while(1) {
    my $action = '';
    $self->print(qq|
      <div class=dialog title='File Edit'>
        <textarea style="width: 100%; height: 30em;" name="$textarea_name">$content</textarea>
        | . $self->cb_button('Cancel' => sub { print STDERR "Got cancel\n"; $action = 'cancel' })
        .   $self->cb_button('Save'   => sub { $action = 'save' })
        .   $self->cb_link('gah'   => sub { print STDERR "Gah\n" })
        . '</div>'
    );
    $self->yield(1);
    print STDERR "Action: $action\n\n";
    if($action eq 'save') {
      $content = $self->param($textarea_name);
      write_file($filename);
      require $filename;
    }
    return if $action;
  }
}

1;


