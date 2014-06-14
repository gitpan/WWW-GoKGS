use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license => 'perl',
    dynamic_config => 0,
    module_name => 'WWW::GoKGS',
    create_readme => 1,
    requires => {
        'perl' => '5.8.9',
        'Carp' => 0,
        'parent' => 0,
        'URI' => 0,
        'Web::Scraper' => 0,
        'Exporter' => 0,
        'LWP::UserAgent' => 0,
        'Scalar::Util' => 0,
        'String::CamelCase' => 0,
    },
    test_requires => {
        'Test::More' => '0.98',
        'Test::Exception' => 0,
        'Test::Pod' => '1.45',
        'Time::Piece' => 0,
    },
    test_files => [ 't/', 'xt/' ],
    meta_merge => {
        no_index => {
            directory => [ 'inc', 't', 'tx', 'examples' ],
        },
	resources => {
            repository => 'git://github.com/anazawa/p5-WWW-GoKGS.git',
	},
    },
);

$build->create_build_script;
