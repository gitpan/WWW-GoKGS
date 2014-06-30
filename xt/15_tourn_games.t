use strict;
use warnings;
use xt::Util qw/:cmp_deeply/;
use Encode qw/decode_utf8/;
use Test::Base;
use WWW::GoKGS;

spec_file 'xt/15_tourn_games.spec';

plan skip_all => 'AUTHOR_TESTING is required' unless $ENV{AUTHOR_TESTING};
plan tests => 1 * blocks;

my $gokgs = WWW::GoKGS->new( from => 'anazawa@cpan.org' );
   $gokgs->user_agent->delay( 1/60 );

my $expected = do {
    my %user = (
        name => user_name(),
        rank => user_rank(),
    );

    hash(
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
};

run {
    my $block = shift;
    my $got = $gokgs->tourn_games->scrape( $block->input );
    is_deeply $got, $block->expected if defined $block->expected;
    cmp_deeply $got, $expected unless defined $block->expected;
};

sub build_uri {
    $gokgs->tourn_games->build_uri( @_ );
}

sub html {
    ( @_, $gokgs->tourn_games->build_uri );
}
