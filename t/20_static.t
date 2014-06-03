use strict;
use warnings;
use Path::Class qw/dir/;
use Test::More;
use WWW::GoKGS::Scraper::GameArchives;
use WWW::GoKGS::Scraper::Top100;
use WWW::GoKGS::Scraper::TournList;
use WWW::GoKGS::Scraper::TournInfo;
use WWW::GoKGS::Scraper::TournGames;
use WWW::GoKGS::Scraper::TournEntrants;

my @tests;
for my $dir ( dir('t/data')->children ) {
    next unless $dir->is_dir;
    for my $d ( $dir->children ) {
        next unless $d->is_dir;
        push @tests, {
            name => $d->basename,
            class => 'WWW::GoKGS::Scraper::' . $dir->basename,
            input => scalar $d->file('input.html')->slurp(iomode=>'<:encoding(UTF-8)'),
            expected => do $d->file('expected.pl'),
        };
    }
}

plan tests => scalar @tests;

for my $test ( @tests ) {
    my $scraper = $test->{class}->new;
    my $got = $scraper->scrape( \$test->{input}, $scraper->base_uri );
    is_deeply $got, $test->{expected}, "$test->{name} ($test->{class})";
}
