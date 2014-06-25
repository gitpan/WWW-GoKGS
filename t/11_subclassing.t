use strict;
use warnings;
use Test::Exception;
use Test::More tests => 4;

package WWW::GoKGS::Scraper::GraphPage;
use parent qw/WWW::GoKGS::Scraper/;

sub scrape {
    { foo => 'bar' };
}

package My::WWW::GoKGS;
use parent qw/WWW::GoKGS/;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors( '/graphPage.jsp' );

sub _build_graph_page {
    WWW::GoKGS::Scraper::GraphPage->new;
}

package main;

throws_ok {
    My::WWW::GoKGS->mk_accessors( '/fooBar.jsp' );
} qr{^Unknown path: /fooBar\.jsp};

my $gokgs = My::WWW::GoKGS->new(
    from => 'user@example.com',
);

is $gokgs->agent, 'My::WWW::GoKGS/0.01';

isa_ok $gokgs->graph_page, 'WWW::GoKGS::Scraper::GraphPage';
is_deeply $gokgs->scrape( '/graphPage.jsp' ), { foo => 'bar' };
