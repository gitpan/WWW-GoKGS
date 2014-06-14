use strict;
use warnings;
use xt::Util qw/:cmp_deeply/;
use Test::More;
use WWW::GoKGS::Scraper::GameArchives;

if ( $ENV{AUTHOR_TESTING} ) {
    plan tests => 1;
}
else {
    plan skip_all => 'AUTHOR_TESTING is required';
}

my $game_archives = WWW::GoKGS::Scraper::GameArchives->new;
my $got = $game_archives->query( user => 'anazawa' );

my $user = hash(
    name => sub { /^[a-zA-Z][a-zA-Z0-9]{0,9}$/ },
    rank => sub { /^(?:\-|\?|[1-9](?:p|d\??|k\??)|[12][0-9]k\??|30k\??)$/ },
    uri => [ uri(), sub { $_[0]->path eq '/gameArchives.jsp' } ],
);

my $type = sub {
    +{ map {( $_ => 1 )} (
        'Ranked',
        'Teaching',
        'Simul',
        'Rengo',
        'Rengo Review',
        'Review',
        'Demonstration',
        'Tournament',
        'Free',
    )}->{$_[0]};
};

cmp_deeply $got, hash(
    games => array(hash(
        sgf_uri => [ uri(), sub { $_[0]->path =~ /\.sgf$/ } ],
        owner => $user,
        white => array( $user ),
        black => array( $user ),
        board_size => [ integer(), sub { $_[0] >= 2 && $_[0] <= 38 } ],
        handicap => [ integer(), sub { $_[0] >= 2 } ],
        start_time => datetime( '%Y-%m-%dT%H:%MZ' ),
        type => $type,
        result => sub { /^(?:Unfinished|Draw|(?:B|W)\+(?:Resign|Forfeit|Time|\d+(?:\.\d+)?))$/ },
    )),
    tgz_uri => [ uri(), sub { $_[0]->path =~ /\.tar\.gz$/ } ],
    zip_uri => [ uri(), sub { $_[0]->path =~ /\.zip$/ } ],
    calendar => array(hash(
        year => [ integer(), sub { $_[0] >= 1999 } ],
        month => [ integer(), sub { $_[0] >= 1 && $_[0] <= 12 } ],
        uri => [ uri(), sub { $_[0]->path eq '/gameArchives.jsp' } ],
    )),
);
