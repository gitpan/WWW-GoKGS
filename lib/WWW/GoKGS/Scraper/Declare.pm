package WWW::GoKGS::Scraper::Declare;
use strict;
use warnings;
use Exporter qw/import/;

our @EXPORT = qw( scraper process process_first result );

BEGIN {
    if ( $ENV{WWW_GOKGS_LIBXML} ) {
        require Web::Scraper::LibXML;
        Web::Scraper::LibXML->import;
    }
    else {
        require Web::Scraper;
        Web::Scraper->import;
    }
}

1;
