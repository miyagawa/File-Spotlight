use inc::Module::Install;
name 'File-Spotlight';
all_from 'lib/File/Spotlight.pm';

if (eval { require Foundation }) {
    requires 'Mac::Tie::PList';
} else {
    requires 'Mac::PropertyList';
}

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
