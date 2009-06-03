package File::Spotlight;

use strict;
use 5.008_001;
our $VERSION = '0.02';

use Carp;
use Mac::Tie::PList;
use String::ShellQuote;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub list {
    my($self, $file) = @_;

    my $plist = Mac::Tie::PList->new_from_file($file)
        or croak "Can't open savedSearch file $file";

    my $query = $plist->{RawQuery};
    my @search_paths = map $self->_transform_path($_), @{ $plist->{SearchCriteria}{FXScopeArrayOfPaths} || [] };

    my @files;
    for my $path (@search_paths) {
        push @files, $self->_run_mdfind($path, $query);
    }

    return @files;
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

    return $ENV{HOME} if $path eq 'kMDQueryScopeHome';
    return "/"        if $path eq 'kMDQueryScopeComputer';

    return $path;
}

1;
__END__

=encoding utf-8

=for stopwords savedSearch .savedSearch plist

=head1 NAME

File::Spotlight - List files from Smart Folder by reading .savedSearch files

=head1 SYNOPSIS

  use File::Spotlight;

  my $search = "$ENV{HOME}/Library/Saved Searches/New Smart Folder.savedSearch";

  my $spotlight = File::Spotlight->new;
  my @found     = $spotlight->list($search);

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

Creates a new File::Spotlight object.

=item list

  @files = $spotlight->list($saved_search);

Given the file path to I<.savedSearch> (usually in C<~/Library/Saved
Searches/> folder), executes the query and returns the list of files
found in the smart folder.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://www.macosxhints.com/dlfiles/spotlightls.txt>

=cut
