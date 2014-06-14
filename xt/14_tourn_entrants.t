use strict;
use warnings;
use xt::Util qw/:cmp_deeply/;
use Test::More;
use WWW::GoKGS::Scraper::TournEntrants;

if ( $ENV{AUTHOR_TESTING} ) {
    plan tests => 3;
}
else {
    plan skip_all => 'AUTHOR_TESTING is required';
}

my $links = hash(
    rounds => array(hash(
        round => [ integer(), sub { $_[0] >= 1 } ],
        start_time => datetime( '%Y-%m-%dT%H:%MZ' ),
        end_time => datetime( '%Y-%m-%dT%H:%MZ' ),
        uri => [ uri(), sub { $_[0]->path eq '/tournGames.jsp' } ],
    )),
);

my $single_or_double_elimination = hash(
    name => sub { defined },
    entrants => array(hash(
        name => sub { /^[a-zA-Z][a-zA-Z0-9]{0,9}$/ },
        rank => sub { /^(?:\-|\?|[1-9](?:p|d\??|k\??)|[12][0-9]k\??|30k\??)$/ },
        standing => sub { defined },
    )),
    links => $links,
);

my $swiss_or_mcmahon = hash(
    name => sub { defined },
    entrants => array(hash(
        position => [ integer(), sub { $_[0] >= 1 } ],
        name => sub { /^[a-zA-Z][a-zA-Z0-9]{0,9}$/ },
        rank => sub { /^(?:\-|\?|[1-9](?:p|d\??|k\??)|[12][0-9]k\??|30k\??)$/ },
        score => [ real(), sub { $_[0] >= 0 } ],
        sos => [ real(), sub { $_[0] >= 0 } ],
        sodos => [ real(), sub { $_[0] >= 0 } ],
        notes => sub { defined },
    )),
    links => $links,
);

my $round_robin = hash(
    name => sub { defined },
    entrants => array(hash(
        position => [ integer(), sub { $_[0] >= 1 } ],
        name => sub { /^[a-zA-Z][a-zA-Z0-9]{0,9}$/ },
        rank => sub { /^(?:\-|\?|[1-9](?:p|d\??|k\??)|[12][0-9]k\??|30k\??)$/ },
        score => [ real(), sub { $_[0] >= 0 } ],
        notes => sub { defined },
    )),
    results => hash(),
    links => $links,
);

my $tourn_entrants = WWW::GoKGS::Scraper::TournEntrants->new;

cmp_deeply
    $tourn_entrants->query( id => 885, sort => 'n' ),
    $single_or_double_elimination,
    'Single or Double Elimination';

cmp_deeply
    $tourn_entrants->query( id => 887, sort => 'n' ),
    $swiss_or_mcmahon,
    'Swiss or McMahon';

cmp_deeply
    $tourn_entrants->query( id => 525, sort => 'n' ),
    $round_robin,
    'Round Robin';
