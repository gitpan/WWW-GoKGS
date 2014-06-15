use strict;
use warnings;
use xt::Util qw/:cmp_deeply/;
use Path::Class qw/file/;
use Test::More;
use WWW::GoKGS::Scraper::TournEntrants;

plan skip_all => 'AUTHOR_TESTING is required' unless $ENV{AUTHOR_TESTING};
plan tests => 2;

subtest 'relaxed' => sub {
    plan tests => 3;

    my $tourn_entrants = WWW::GoKGS::Scraper::TournEntrants->new;

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
            name => user_name(),
            rank => user_rank(),
            standing => sub { defined },
        )),
        links => $links,
    );

    my $swiss_or_mcmahon = hash(
        name => sub { defined },
        entrants => array(hash(
            position => [ integer(), sub { $_[0] >= 1 } ],
            name => user_name(),
            rank => user_rank(),
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
            name => user_name(),
            rank => user_rank(),
            score => [ real(), sub { $_[0] >= 0 } ],
            notes => sub { defined },
        )),
        results => hash(),
        links => $links,
    );

    cmp_deeply
        $tourn_entrants->query( id => 885, sort => 'n' ),
        $single_or_double_elimination,
        'id=885&sort=n';

    cmp_deeply
        $tourn_entrants->query( id => 887, sort => 'n' ),
        $swiss_or_mcmahon,
        'id=887&sort=n';

    cmp_deeply
        $tourn_entrants->query( id => 525, sort => 'n' ),
        $round_robin,
        'id=525&sort=n';
};

subtest 'paranoid' => sub {
    plan tests => 3;

    my $tourn_entrants = WWW::GoKGS::Scraper::TournEntrants->new;

    my $swiss = do +file(
        'xt',
        'data',
        'TournEntrants',
        '20140616-id-857-sort-n.pl',
    );

    my $round_robin = do +file(
        'xt',
        'data',
        'TournEntrants',
        '20140616-id-104-sort-n.pl',
    );

    my $single_elimination = do +file(
        'xt',
        'data',
        'TournEntrants',
        '20140616-id-12-sort-n.pl',
    );

    is_deeply
        $tourn_entrants->query( id => 857, sort => 'n' ),
        $swiss,
        'id=857&sort=n';

    is_deeply
        $tourn_entrants->query( id => 104, sort => 'n' ),
        $round_robin,
        'id=104&sort=n';

    is_deeply
        $tourn_entrants->query( id => 12, sort => 'n' ),
        $single_elimination,
        'id=12&sort=n';
};
