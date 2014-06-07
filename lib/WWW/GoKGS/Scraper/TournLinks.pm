package WWW::GoKGS::Scraper::TournLinks;
use strict;
use warnings;
use Exporter qw/import/;
use Web::Scraper;

our @EXPORT_OK = qw( process_links );

sub process_links {
    my %filter = @_;

    my $round_number = sub {
        m/^Round (\d+) / ? int $1 : undef;
    };

    my @start_time = (
        sub {
            my $time = m/ will start at (.*)$/ && $1;
            $time ||= m/\(([^\-]+) -/ ? $1 : undef;
            $time =~ tr/\x{a0}/ / if $time;
            $time;
        },
        @{ $filter{'links.rounds[].start_time'} || [] },
    );

    my @end_time = (
        sub {
            my $time = m/- ([^)]+)\)$/ ? $1 : undef;
            $time =~ tr/\x{a0}/ / if $time;
            $time;
        },
        @{ $filter{'links.rounds[].end_time'} || [] },
    );

    my $round = scraper {
        process '.', 'round' => [ 'TEXT', $round_number ];
        process '.', 'start_time' => [ 'TEXT', @start_time ];
        process 'a', 'end_time' => [ 'TEXT', @end_time ];
        process 'a', 'uri' => '@href';
    };

    my $entrant = scraper {
        process 'a', 'sort_by' => [ 'TEXT', sub { s/^By // } ];
        process 'a', 'uri' => '@href';
    };

    process '//div[@class="tournData"]', 'links' => scraper {
        process '//ul[starts-with(preceding-sibling::p/text(), "Entrants")]//li',
                'entrants[]' => $entrant;
        process '//ul[starts-with(preceding-sibling::p/text(), "Games")]//li',
                'rounds[]' => $round;
    };
}

1;
