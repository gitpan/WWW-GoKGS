use strict;
use warnings;
use Test::More tests => 2;

package WWW::GoKGS::Scraper::FooBar;
use parent qw/WWW::GoKGS::Scraper/;

sub user_agent {}

sub scrape {
    { foo => 'bar' };
}

package My::WWW::GoKGS;
use parent qw/WWW::GoKGS/;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors( '/fooBar.jsp' );

sub _build_foo_bar {
    WWW::GoKGS::Scraper::FooBar->new;
}

package main;

my $gokgs = My::WWW::GoKGS->new(
    from => 'user@example.com',
);

isa_ok $gokgs->foo_bar, 'WWW::GoKGS::Scraper::FooBar';
is_deeply $gokgs->scrape( '/fooBar.jsp' ), { foo => 'bar' };
