use inc::Module::Install;
name 'File-Spotlight';
all_from 'lib/File/Spotlight.pm';

requires 'Mac::Tie::PList';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
