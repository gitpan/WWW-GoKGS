use strict;
use warnings;
use xt::Util qw/:cmp_deeply/;
use Path::Class qw/file/;
use Test::More;
use WWW::GoKGS::Scraper::TournList;

plan skip_all => 'AUTHOR_TESTING is required' unless $ENV{AUTHOR_TESTING};
plan tests => 2;

subtest 'relaxed' => sub {
    plan tests => 1;

    my $tourn_list = WWW::GoKGS::Scraper::TournList->new;

    my $got = $tourn_list->query;

    my $expected = hash(
        tournaments => array_of_hashes(
            name => sub { defined },
            uri => [ uri(), sub { $_[0]->path eq '/tournInfo.jsp' } ],
        ),
        year_index => array_of_hashes(
            year => [ integer(), sub { $_[0] >= 2001 } ],
            uri => [ uri(), sub { $_[0]->path eq '/tournList.jsp' } ],
        ),
    );

    cmp_deeply $got, $expected, 'no arguments';
};

subtest 'paranoid' => sub {
    my $tourn_list = WWW::GoKGS::Scraper::TournList->new;

    my $got = $tourn_list->query(
        year => 2013,
    );

    my $expected = do +file(
        'xt',
        'data',
        'TournList',
        '20140616-year-2013.pl',
    );

    is_deeply $got->{tournaments}, $expected->{tournaments}, '$hash->{tournaments}';
    
    isa_ok $got->{year_index}, 'ARRAY', '$hash->{year_index}';

    my $i = 0;
    for my $index ( @{$got->{year_index}} ) {
        my $name = "\$hash->{year_index}->[$i]";

        isa_ok $index, 'HASH', $name;

        if ( exists $index->{uri} ) {
            isa_ok $index->{uri}, 'URI', "$name\->{uri}";
            is $index->{uri}->path, '/tournList.jsp', "$name\->{uri}->path";
        }
        else {
            is $index->{year}, 2013, "$name\->{year}";
            next;
        }

        my %got = $index->{uri}->query_form;

        my %expected = (
            year => $index->{year},
        );

        is_deeply \%got, \%expected, "$name\->{uri}->query_fom";

    }
    continue {
        $i++;
    }

    done_testing;
};
