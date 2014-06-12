use strict;
use warnings;
use Test::More tests => 2;

package WWW::GoKGS::Scraper::FooBar;
use parent qw/WWW::GoKGS::Scraper/;

sub scrape {
    { foo => 'bar' };
}

package My::WWW::GoKGS;
use parent qw/WWW::GoKGS/;

__PACKAGE__->mk_accessors( '/fooBar.jsp' );

sub _build_foo_bar {
    WWW::GoKGS::Scraper::FooBar->new;
}

package main;

my $gokgs = My::WWW::GoKGS->new;

isa_ok $gokgs->foo_bar, 'WWW::GoKGS::Scraper::FooBar';
is_deeply $gokgs->scrape( '/fooBar.jsp' ), { foo => 'bar' };
