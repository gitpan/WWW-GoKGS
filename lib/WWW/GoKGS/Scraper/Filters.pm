package WWW::GoKGS::Scraper::Filters;
use strict;
use warnings FATAL => 'all';
use Exporter qw/import/;

our @EXPORT_OK = qw(
    datetime
);

sub datetime {
    my $time = shift;
    my ( $mon, $mday, $year, $hour, $min, $ampm )
        = $time =~ m{^(\d\d?)/(\d\d?)/(\d\d) (\d\d?):(\d\d) (AM|PM)$};

    $year += 2000;
    $hour -= 12 if $ampm eq 'AM' and $hour == 12;
    $hour += 12 if $ampm eq 'PM' and $hour != 12;

    sprintf '%04d-%02d-%02dT%02d:%02dZ',
            $year, $mon, $mday,
            $hour, $min;
}

1;
