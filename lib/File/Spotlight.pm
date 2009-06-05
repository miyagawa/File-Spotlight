package File::Spotlight;

use strict;
use 5.008_001;
our $VERSION = '0.04';

use Carp;
use String::ShellQuote;
use Scalar::Util qw(blessed);

sub new {
    my $class = shift;
    my($file) = @_;

    my $self = bless { path => $file }, $class;
    $self->init() if $file;

    return $self;
}

sub path {
    my $self = shift;
    if (@_) {
        $self->{path} = shift;
        $self->init;
    }
    $self->{path};
}

sub init {
    my $self = shift;

    my $plist = $self->parse_plist($self->path)
        or croak "Can't open savedSearch file " . $self->path;

    my $query = $plist->{RawQuery};
       $query = _get_value($query) if blessed $query;
    my @search_paths = map $self->_transform_path($_), @{ $plist->{SearchCriteria}{FXScopeArrayOfPaths} || [] };

    $self->{query} = $query;
    $self->{search_paths} = \@search_paths;
}

sub list {
    my $self = shift;

    if (@_) {
        # backward compatiblity
        $self = (ref $self)->new(@_);
    }

    my @files;
    for my $path (@{$self->{search_paths}}) {
        push @files, $self->_run_mdfind($path, $self->{query});
    }

    return @files;
}

sub parse_plist {
    my($self, $file) = @_;

    if (eval { require Mac::Tie::PList }) {
        return Mac::Tie::PList->new_from_file($file);
    } else {
        require Mac::PropertyList;
        Mac::PropertyList::parse_plist_file($file);
    }
}

sub _run_mdfind {
    my($self, $path, $query) = @_;

    my $cmd = 'mdfind -onlyin ' . shell_quote($path) . ' ' . shell_quote($query);

    my @files;
    for my $file (grep length, split /\n/, qx($cmd)) {
        chomp;
        push @files, $file;
    }

    return @files;
}

sub _transform_path {
    my($self, $path) = @_;
    $path = _get_value($path) if blessed $path;

    return $ENV{HOME} if $path eq 'kMDQueryScopeHome';
    return "/"        if $path eq 'kMDQueryScopeComputer';

    return $path;
}

my %decode = (amp => '&', quot => '"', lt => '<', gt => '>');

sub _get_value {
    my $string = shift;

    # Mac::PropertyList doesn't decode XML escapes
    $string = $string->value;
    $string =~ s/&(amp|quot|lt|gt);/$decode{$1}/eg;

    return $string;
}


1;
__END__

=encoding utf-8

=for stopwords savedSearch .savedSearch plist

=head1 NAME

File::Spotlight - List files from Smart Folder by reading .savedSearch files

=head1 SYNOPSIS

  use File::Spotlight;

  my $path = "$ENV{HOME}/Library/Saved Searches/New Smart Folder.savedSearch";

  my $folder = File::Spotlight->new($path);
  my @found  = $folder->list();

=head1 DESCRIPTION

File::Spotlight is a simple module to parse I<.savedSearch> Smart
Folder definition and get the result by executing the Spotlight query
by C<mdfind> command.

This is a low-level module to open and execute the saved search plist
files. In your application you might better wrap or integrate this
module with higher-level file system abstraction like L<IO::Dir>,
L<Path::Class::Dir> or L<Filesys::Virtual>.

=head1 METHODS

=over 4

=item new

  $folder = File::Spotlight->new("/path/to/foo.savedSearch");

Creates a new File::Spotlight object with the I<.savedSearch> file
path usually in C<~/Library/Saved Searches> folder.

=item list

  @files = $folder->list;

Executes the saved Spotlight query and returns the list of files found
in the smart folder.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://www.macosxhints.com/dlfiles/spotlightls.txt>

=cut
