package Continuity::Monitor::Plugin::FileEdit;

use Moose;
use Method::Signatures;
use File::Slurp;A
use HTML::Entities

extends 'MooseX::Continuity::Widget';

method main {
  my $counter = 1;
  while(1) {
    $self->print("<div class=dialog title='File Edit'>");
    my @files = sort values %INC;
    @files = grep !/home/, @files;
    @files = map { "<li>" . $self->cb_link( $_ => sub {
      $self->edit_file($_);
    }) . "</li>" } @files;
    $self->print("<ul>@files</ul>");
    $self->print("</div>");
    $self->yield(1);
  }
}

method edit_file($filename) {
  my $content = read_file($filename);
  my $textarea_name = $self->field_name('content');
  while(1) {
    my $action;
    $self->print(qq|
      <div class=dialog title='File Edit'>");
        <textarea style="width: 100%; height: 30em;" name="$textarea_name">$content</textarea>
        | . $self->cb_button('Cancel' => sub { $action = 'cancel' })
        .   $self->cb_button('Save'   => sub { $action = 'save' })
        . '</div>'
    );
    $self->yield(1);
    if($action eq 'save') {
      $content = $self->param($textarea_name);
      write_file($filename);
      require $filename;
    }
    return if $action;
  }
}

1;


