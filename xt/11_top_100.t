use strict;
use warnings;
use xt::Util qw/:cmp_deeply/;
use Test::More;
use WWW::GoKGS::Scraper::Top100;

if ( $ENV{AUTHOR_TESTING} ) {
    plan tests => 1;
}
else {
    plan skip_all => 'AUTHOR_TESTING is required';
}

my $top_100 = WWW::GoKGS::Scraper::Top100->new;
my $got = $top_100->query;

cmp_deeply $got, hash(
    players => array(hash(
        position => [ integer(), sub { $_[0] >= 1 && $_[0] <= 100 } ],
        name => sub { /^[a-zA-Z][a-zA-Z0-9]{0,9}$/ },
        rank => sub { /^[1-9]d$/ },
        uri => [ uri(), sub { $_[0]->path eq '/graphPage.jsp' } ],
    )),
);
