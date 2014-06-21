use strict;
use warnings;
use xt::Util qw/:cmp_deeply/;
use Path::Class qw/file/;
use Test::More;
use WWW::GoKGS::Scraper::TournGames;

plan skip_all => 'AUTHOR_TESTING is required' unless $ENV{AUTHOR_TESTING};
plan tests => 2;

subtest 'relaxed' => sub {
    plan tests => 1;

    my $tourn_games = WWW::GoKGS::Scraper::TournGames->new;

    my $got = $tourn_games->query(
        id => 879,
        round => 1,
    );

    my %user = (
        name => user_name(),
        rank => user_rank(),
    );

    my $expected = hash(
        name => sub { defined },
        round => [ integer(), sub { $_[0] >= 1 } ],
        games => array_of_hashes(
            sgf_uri => [ uri(), sub { $_[0]->path =~ /\.sgf$/ } ],
            black => hash( %user ),
            white => hash( %user ),
            board_size => [ integer(), sub { $_[0] >= 2 && $_[0] <= 38 } ],
            handicap => [ integer(), sub { $_[0] >= 2 } ],
            start_time => datetime( '%Y-%m-%dT%H:%MZ' ),
            result => game_result(),
        ),
        byes => array_of_hashes(
            %user,
            type => sub { /^(?:System|No show|Requested)$/ },
        ),
        previous_round_uri => [ uri(), sub { $_[0]->path eq '/tournGames.jsp' } ],
        next_round_uri => [ uri(), sub { $_[0]->path eq '/tournGames.jsp' } ],
        links => hash(
            rounds => array_of_hashes(
                round => [ integer(), sub { $_[0] >= 1 } ],
                start_time => datetime( '%Y-%m-%dT%H:%MZ' ),
                end_time => datetime( '%Y-%m-%dT%H:%MZ' ),
                uri => [ uri(), sub { $_[0]->path eq '/tournGames.jsp' } ],
            ),
        ),
    );

    cmp_deeply $got, $expected, 'id=879&round=1';
};

subtest 'paranoid' => sub {
    plan tests => 1;

    my $tourn_games = WWW::GoKGS::Scraper::TournGames->new;

    my $got = $tourn_games->query(
        id => 488,
        round => 1,
    );

    my $expected = do +file(
        'xt',
        'data',
        'TournGames',
        '20140616-id-488-round-1.pl',
    );

    is_deeply $got, $expected, 'id=488&round=1';
};
