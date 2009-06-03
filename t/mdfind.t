use strict;
use Test::Base;
use File::Spotlight;

plan tests => 1 * blocks;
filters { query => 'chomp' };

no warnings 'redefine';

run {
    my $block = shift;

    local *File::Spotlight::_run_mdfind = sub {
        my($self, $path, $query) = @_;
        is $query, $block->query;
    };

    File::Spotlight->new->list($block->file);
};

__DATA__
===
--- file: t/textapp.savedSearch
--- query
((((_kMDItemGroupId = 8))) && (true)) && ((kMDItemDisplayName = "text*"cdw))
