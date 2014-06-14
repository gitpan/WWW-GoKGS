use strict;
use warnings;
use xt::Util qw/:cmp_deeply/;
use Test::More;
use WWW::GoKGS::Scraper::TournGames;

if ( $ENV{AUTHOR_TESTING} ) {
    plan tests => 1;
}
else {
    plan skip_all => 'AUTHOR_TESTING is required';
}

my $tourn_games = WWW::GoKGS::Scraper::TournGames->new;
my $got = $tourn_games->query( id => 879, round => 1 );

my %user = (
    name => sub { /^[a-zA-Z][a-zA-Z0-9]{0,9}$/ },
    rank => sub { /^(?:\-|\?|[1-9](?:p|d\??|k\??)|[12][0-9]k\??|30k\??)$/ },
);

cmp_deeply $got, hash(
    name => sub { defined },
    round => [ integer(), sub { $_[0] >= 1 } ],
    games => array(hash(
        sgf_uri => [ uri(), sub { $_[0]->path =~ /\.sgf$/ } ],
        black => hash( %user ),
        white => hash( %user ),
        board_size => [ integer(), sub { $_[0] >= 2 && $_[0] <= 38 } ],
        handicap => [ integer(), sub { $_[0] >= 2 } ],
        start_time => datetime( '%Y-%m-%dT%H:%MZ' ),
        result => sub { /^(?:Unfinished|Draw|(?:B|W)\+(?:Resign|Forfeit|Time|\d+(?:\.\d+)?))$/ },
    )),
    byes => array(hash(
        %user,
        type => sub { /^(?:System|No show|Requested)$/ },
    )),
    next_round_uri => [ uri(), sub { $_[0]->path eq '/tournGames.jsp' } ],
    previous_round_uri => [ uri(), sub { $_[0]->path eq '/tournGames.jsp' } ],
    links => hash(
        rounds => array(hash(
            round => [ integer(), sub { $_[0] >= 1 } ],
            start_time => datetime( '%Y-%m-%dT%H:%MZ' ),
            end_time => datetime( '%Y-%m-%dT%H:%MZ' ),
            uri => [ uri(), sub { $_[0]->path eq '/tournGames.jsp' } ],
        )),
    ),
);
