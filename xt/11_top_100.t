use strict;
use warnings;
use xt::Util qw/:cmp_deeply/;
use Test::More;
use WWW::GoKGS::Scraper::Top100;

plan skip_all => 'AUTHOR_TESTING is required' unless $ENV{AUTHOR_TESTING};
plan tests => 1;

subtest 'relaxed' => sub {
    plan tests => 1;

    my $top_100 = WWW::GoKGS::Scraper::Top100->new;

    my $got = $top_100->query;

    my $expected = hash(
        players => array_of_hashes(
            position => [ integer(), sub { $_[0] >= 1 && $_[0] <= 100 } ],
            name => sub { /^[a-zA-Z][a-zA-Z0-9]{0,9}$/ },
            rank => sub { /^[1-9]d$/ },
            uri => [ uri(), sub { $_[0]->path eq '/graphPage.jsp' } ],
        ),
    );

    cmp_deeply $got, $expected, 'no arguments';
};
