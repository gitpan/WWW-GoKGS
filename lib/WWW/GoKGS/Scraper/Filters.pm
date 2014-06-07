package WWW::GoKGS::Scraper::Filters;
use strict;
use warnings;
use Exporter qw/import/;

our @EXPORT_OK = qw(
    datetime
);

sub datetime {
    my $time = shift;
    my ( $mon, $mday, $yy, $hour, $min, $ampm )
        = $time =~ m{^(\d\d?)/(\d\d?)/(\d\d) (\d\d?):(\d\d) (AM|PM)$};
    sprintf '%04d-%02d-%02dT%02d:%02dZ',
            $yy + 2000, $mon, $mday,
            $ampm eq 'PM' ? $hour + 12 : $hour, $min;
}

1;
