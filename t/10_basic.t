use strict;
use warnings;
use Test::Exception;
use Test::More tests => 8;
use WWW::GoKGS;
use WWW::GoKGS::Scraper::Filters qw/datetime/;
use WWW::GoKGS::Scraper::GameArchives;
use WWW::GoKGS::Scraper::Top100;
use WWW::GoKGS::Scraper::TournList;
use WWW::GoKGS::Scraper::TournInfo;
use WWW::GoKGS::Scraper::TournEntrants;
use WWW::GoKGS::Scraper::TournGames;

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

subtest 'WWW::GoKGS::Scraper::GameArchives' => sub {
    my $game_archives = WWW::GoKGS::Scraper::GameArchives->new;

    isa_ok $game_archives, 'WWW::GoKGS::Scraper::GameArchives';

    isa_ok $game_archives->base_uri, 'URI';
    isa_ok $game_archives->user_agent, 'LWP::UserAgent';

    can_ok $game_archives, qw( add_filter scrape query );

    is $game_archives->base_uri, 'http://www.gokgs.com/gameArchives.jsp';

    throws_ok {
        $game_archives->add_filter('key');
    } qr{^Odd number of arguments passed to 'add_filter'};
};

subtest 'WWW::GoKGS::Scraper::Top100' => sub {
    my $top_100 = WWW::GoKGS::Scraper::Top100->new;
    isa_ok $top_100, 'WWW::GoKGS::Scraper::Top100';
    is $top_100->base_uri, 'http://www.gokgs.com/top100.jsp';
    isa_ok $top_100->user_agent, 'LWP::UserAgent';
    can_ok $top_100, qw( scrape query );
};

subtest 'WWW::GoKGS::Scraper::TournList' => sub {
    my $tourn_list = WWW::GoKGS::Scraper::TournList->new;
    isa_ok $tourn_list, 'WWW::GoKGS::Scraper::TournList';
    is $tourn_list->base_uri, 'http://www.gokgs.com/tournList.jsp';
    isa_ok $tourn_list->user_agent, 'LWP::UserAgent';
    can_ok $tourn_list, qw( scrape query );
};

subtest 'WWW::GoKGS::Scraper::TournInfo' => sub {
    my $tourn_info = WWW::GoKGS::Scraper::TournInfo->new;

    isa_ok $tourn_info, 'WWW::GoKGS::Scraper::TournInfo';

    isa_ok $tourn_info->base_uri, 'URI';
    isa_ok $tourn_info->user_agent, 'LWP::UserAgent';

    can_ok $tourn_info, qw( add_filter scrape query );

    is $tourn_info->base_uri, 'http://www.gokgs.com/tournInfo.jsp';

    throws_ok {
        $tourn_info->add_filter('key');
    } qr{^Odd number of arguments passed to 'add_filter'};
};

subtest 'WWW::GoKGS::Scraper::TournEntrants' => sub {
    my $tourn_entrants = WWW::GoKGS::Scraper::TournEntrants->new;

    isa_ok $tourn_entrants, 'WWW::GoKGS::Scraper::TournEntrants';

    isa_ok $tourn_entrants->base_uri, 'URI';
    isa_ok $tourn_entrants->user_agent, 'LWP::UserAgent';

    can_ok $tourn_entrants, qw( add_filter scrape query );

    is $tourn_entrants->base_uri, 'http://www.gokgs.com/tournEntrants.jsp';

    throws_ok {
        $tourn_entrants->add_filter('key');
    } qr{^Odd number of arguments passed to 'add_filter'};
};

subtest 'WWW::GoKGS::Scraper::TournGames' => sub {
    my $tourn_games = WWW::GoKGS::Scraper::TournGames->new;

    isa_ok $tourn_games, 'WWW::GoKGS::Scraper::TournGames';

    isa_ok $tourn_games->base_uri, 'URI';
    isa_ok $tourn_games->user_agent, 'LWP::UserAgent';

    can_ok $tourn_games, qw( add_filter scrape query );

    is $tourn_games->base_uri, 'http://www.gokgs.com/tournGames.jsp';

    throws_ok {
        $tourn_games->add_filter('key');
    } qr{^Odd number of arguments passed to 'add_filter'};
};

subtest 'WWW::GoKGS' => sub {
    my $gokgs = WWW::GoKGS->new(
        from => 'user@example.com',
    );

    isa_ok $gokgs, 'WWW::GoKGS';
    
    isa_ok $gokgs->user_agent, 'LWP::UserAgent';
    isa_ok $gokgs->date_filter, 'CODE';
    isa_ok $gokgs->html_filter, 'CODE';
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
        set_scraper
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
        is $path, $scraper->base_uri->path;
    });

    throws_ok {
        $gokgs->set_scraper( '/fooBar.jsp' );
    } qr{^Odd number of arguments passed to 'set_scraper'};

    throws_ok {
        $gokgs->set_scraper( '/fooBar.jsp' => 'FooBar' );
    } qr{^FooBar \(/fooBar\.jsp scraper\) is missing 'scrape' method};

    throws_ok {
        my ( $path, $scraper ) = $gokgs->each_scraper;
    } qr{^Not a CODE reference};

    throws_ok {
        $gokgs->scrape( '/fooBar.jsp' );
    } qr{^Don't know how to scrape '/fooBar\.jsp'};
};
