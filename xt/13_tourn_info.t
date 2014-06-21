use strict;
use warnings;
use xt::Util qw/:cmp_deeply/;
use Path::Class qw/file/;
use Test::More;
use WWW::GoKGS::Scraper::TournInfo;

plan skip_all => 'AUTHOR_TESTING is required' unless $ENV{AUTHOR_TESTING};
plan tests => 2;

subtest 'relaxed' => sub {
    plan tests => 1;

    my $tourn_info = WWW::GoKGS::Scraper::TournInfo->new;

    my $got = $tourn_info->query(
        id => 885,
    );

    my $expected = hash(
        name => sub { defined },
        description => sub { defined },
        links => hash(
            rounds => array_of_hashes(
                round => [ integer(), sub { $_[0] >= 1 } ],
                start_time => datetime( '%Y-%m-%dT%H:%MZ' ),
                end_time => datetime( '%Y-%m-%dT%H:%MZ' ),
                uri => [ uri(), sub { $_[0]->path eq '/tournGames.jsp' } ],
            ),
        ),
    );

    cmp_deeply $got, $expected, 'id=885';
};

subtest 'paranoid' => sub {
    plan tests => 1;

    my $tourn_info = WWW::GoKGS::Scraper::TournInfo->new;

    my $got = $tourn_info->query(
        id => 857,
    );

    my $expected = do +file(
        'xt',
        'data',
        'TournInfo',
        '20140616-id-857.pl',
    );

    is_deeply $got, $expected, 'id=857';
};
