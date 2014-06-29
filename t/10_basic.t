use strict;
use warnings;
use Test::Exception;
use Test::More tests => 2;
use WWW::GoKGS;
use WWW::GoKGS::Scraper::Filters qw/datetime/;

subtest 'datetime()' => sub {
    my @tests = (
        '2/13/14 12:14 AM' => '2014-02-13T00:14Z',
        '6/9/14 12:14 PM'  => '2014-06-09T12:14Z',
    );

    while ( my ($input, $expected) = splice @tests, 0, 2 ) {
        is datetime( $input ), $expected,
           "datetime('$input') should return '$expected'";
    }
};

subtest 'WWW::GoKGS' => sub {
    my $gokgs = WWW::GoKGS->new(
        from => 'user@example.com',
    );

    isa_ok $gokgs, 'WWW::GoKGS';
    
    isa_ok $gokgs->user_agent, 'LWP::UserAgent';
    isa_ok $gokgs->game_archives, 'WWW::GoKGS::Scraper::GameArchives';
    isa_ok $gokgs->top_100, 'WWW::GoKGS::Scraper::Top100';
    isa_ok $gokgs->tourn_list, 'WWW::GoKGS::Scraper::TournList';
    isa_ok $gokgs->tourn_info, 'WWW::GoKGS::Scraper::TournInfo';
    isa_ok $gokgs->tourn_entrants, 'WWW::GoKGS::Scraper::TournEntrants';
    isa_ok $gokgs->tourn_games, 'WWW::GoKGS::Scraper::TournGames';

    is $gokgs->from, 'user@example.com';
    like $gokgs->agent, qr{^WWW::GoKGS/\d\.\d\d$};

    can_ok $gokgs, qw(
        get_scraper
        each_scraper
        can_scrape
        scrape
    );

    cmp_ok $gokgs->get_scraper('/top100.jsp'), '==', $gokgs->top_100;

    ok $gokgs->can_scrape( '/gameArchives.jsp?user=foo' );
    ok $gokgs->can_scrape( 'http://www.gokgs.com/top100.jsp' );
    ok !$gokgs->can_scrape( '/fooBar.jsp?baz=qux' );
    ok !$gokgs->can_scrape( 'http://www.example.com/top100.jsp' );

    $gokgs->each_scraper(sub {
        my ( $path, $scraper ) = @_;
        is $path, $scraper->build_uri->path;
    });

    throws_ok {
        my ( $path, $scraper ) = $gokgs->each_scraper;
    } qr{^Not a CODE reference};

    throws_ok {
        $gokgs->scrape( '/fooBar.jsp' );
    } qr{^Don't know how to scrape '/fooBar\.jsp'};
};
