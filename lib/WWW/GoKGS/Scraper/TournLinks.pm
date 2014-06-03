package WWW::GoKGS::Scraper::TournLinks;
use strict;
use warnings;
use Exporter qw/import/;
use Web::Scraper;

our @EXPORT_OK = qw( process_links );

sub process_links {
    my %args = @_;

    my $date_filter = do {
        my $orig = $args{date_filter} || sub { $_[0] };

        sub {
            my $date = shift;
            return unless $date;
            my ( $mon, $mday, $yy, $hour, $min, $ampm )
                = $date =~ m{^(\d\d?)/(\d\d?)/(\d\d) (\d\d?):(\d\d) (AM|PM)$};
            $orig->(do {
                sprintf '%04d-%02d-%02dT%02d:%02dZ',
                        $yy + 2000, $mon, $mday,
                        $ampm eq 'PM' ? $hour + 12 : $hour, $min;
            });
        };
    };

    my $round_number = sub {
        m/^Round (\d+) / ? $1 : undef;
    };

    my $start_time = sub {
        my $time = m/ will start at (.*)$/ && $1;
        $time ||= m/\(([^\-]+) -/ ? $1 : undef;
        $time =~ tr/\x{a0}/ / if $time;
        $time;
    };

    my $end_time = sub {
        my $time = m/- ([^)]+)\)$/ ? $1 : undef;
        $time =~ tr/\x{a0}/ / if $time;
        $time;
    };

    my $round = scraper {
        process '.', 'round' => [ 'TEXT', $round_number ];
        process '.', 'start_time' => [ 'TEXT', $start_time, $date_filter ];
        process '.', 'end_time' => [ 'TEXT', $end_time, $date_filter ];
        process '.', 'uri' => [ 'TEXT', sub { undef } ]; # FIXME
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
