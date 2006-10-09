use Module::Build;

use strict;

my $build = Module::Build->new(
    module_name => 'Path::Router',
    license => 'perl',
    requires => {
        'Moose'            => 0,     
        'File::Spec::Unix' => 0,
    },
    optional => {
        'Term::ReadLine' => 0,
        'Data::Dumper'   => 0,        
        'Sub::Exporter'  => 0,
        'Test::Builder'  => 0,
        'Test::Deep'     => 0,        
    },
    build_requires => {
        'Test::More'       => '0.62',
        'Test::Exception'  => '0.21',
    },
    create_makefile_pl => 'traditional',
    recursive_test_files => 1,
    add_to_cleanup => [
        'META.yml', '*.bak', '*.gz', 'Makefile.PL',
    ],
);

$build->create_build_script;

