use strict;
use warnings;
use xt::Util qw/:cmp_deeply/;
use Test::More;
use WWW::GoKGS::Scraper::TournList;

if ( $ENV{AUTHOR_TESTING} ) {
    plan tests => 1;
}
else {
    plan skip_all => 'AUTHOR_TESTING is required';
}

my $tourn_list = WWW::GoKGS::Scraper::TournList->new;
my $got = $tourn_list->query;

cmp_deeply $got, hash(
    tournaments => array(hash(
        name => sub { defined },
        uri => [ uri(), sub { $_[0]->path eq '/tournInfo.jsp' } ],
    )),
    year_index => array(hash(
        year => [ integer(), sub { $_[0] >= 2001 } ],
        uri => [ uri(), sub { $_[0]->path eq '/tournList.jsp' } ],
    )),
);
