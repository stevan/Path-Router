use strict;
use warnings;
use inc::Module::Install;

name 'Path-Router';
all_from 'lib/Path/Router.pm';
license 'perl';

# prereqs
requires 'Moose'            => '0.74';
requires 'MooseX::Clone'    => '0.04';
requires 'File::Spec::Unix' => 0;

feature 'Path::Router::Shell',
    -default         => 1,
    'Term::ReadLine' => '0';

# things the tests need
build_requires 'Test::More'      => '0.62';
build_requires 'Test::Exception' => '0.21';
build_requires 'Test::Deep';
build_requires 'Test::Builder';

tests_recursive;

auto_install;

WriteAll();

