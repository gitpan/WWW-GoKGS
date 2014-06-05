use strict;
use warnings;
use Test::Exception;
use Test::More tests => 7;
use WWW::GoKGS;
use WWW::GoKGS::Scraper::GameArchives;
use WWW::GoKGS::Scraper::Top100;
use WWW::GoKGS::Scraper::TournList;
use WWW::GoKGS::Scraper::TournInfo;
use WWW::GoKGS::Scraper::TournEntrants;
use WWW::GoKGS::Scraper::TournGames;

subtest 'WWW::GoKGS::Scraper::GameArchives' => sub {
    my $game_archives = WWW::GoKGS::Scraper::GameArchives->new;
    isa_ok $game_archives, 'WWW::GoKGS::Scraper::GameArchives';
    is $game_archives->base_uri, 'http://www.gokgs.com/gameArchives.jsp';
    isa_ok $game_archives->user_agent, 'LWP::UserAgent';
    isa_ok $game_archives->date_filter, 'CODE';
    isa_ok $game_archives->result_filter, 'CODE';
    can_ok $game_archives, qw( scrape query );
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
    is $tourn_info->base_uri, 'http://www.gokgs.com/tournInfo.jsp';
    isa_ok $tourn_info->date_filter, 'CODE';
    isa_ok $tourn_info->html_filter, 'CODE';
    isa_ok $tourn_info->user_agent, 'LWP::UserAgent';
    can_ok $tourn_info, qw( scrape query );
};

subtest 'WWW::GoKGS::Scraper::TournEntrants' => sub {
    my $tourn_entrants = WWW::GoKGS::Scraper::TournEntrants->new;
    isa_ok $tourn_entrants, 'WWW::GoKGS::Scraper::TournEntrants';
    is $tourn_entrants->base_uri, 'http://www.gokgs.com/tournEntrants.jsp';
    isa_ok $tourn_entrants->date_filter, 'CODE';
    isa_ok $tourn_entrants->user_agent, 'LWP::UserAgent';
    can_ok $tourn_entrants, qw( scrape query );
};

subtest 'WWW::GoKGS::Scraper::TournGames' => sub {
    my $tourn_games = WWW::GoKGS::Scraper::TournGames->new;
    isa_ok $tourn_games, 'WWW::GoKGS::Scraper::TournGames';
    is $tourn_games->base_uri, 'http://www.gokgs.com/tournGames.jsp';
    isa_ok $tourn_games->date_filter, 'CODE';
    isa_ok $tourn_games->user_agent, 'LWP::UserAgent';
    can_ok $tourn_games, qw( scrape query );
};

subtest 'WWW::GoKGS' => sub {
    my $gokgs = WWW::GoKGS->new;

    isa_ok $gokgs, 'WWW::GoKGS';
    isa_ok $gokgs->user_agent, 'LWP::UserAgent';
    isa_ok $gokgs->date_filter, 'CODE';
    isa_ok $gokgs->html_filter, 'CODE';
    isa_ok $gokgs->result_filter, 'CODE';
    isa_ok $gokgs->game_archives, 'WWW::GoKGS::Scraper::GameArchives';
    isa_ok $gokgs->top_100, 'WWW::GoKGS::Scraper::Top100';
    isa_ok $gokgs->tourn_list, 'WWW::GoKGS::Scraper::TournList';
    isa_ok $gokgs->tourn_info, 'WWW::GoKGS::Scraper::TournInfo';
    isa_ok $gokgs->tourn_entrants, 'WWW::GoKGS::Scraper::TournEntrants';
    isa_ok $gokgs->tourn_games, 'WWW::GoKGS::Scraper::TournGames';
    can_ok $gokgs, qw( scrape );

    throws_ok {
        $gokgs->scrape('/fooBar.jsp');
    } qr{^Don't know how to scrape '/fooBar\.jsp'};
};
