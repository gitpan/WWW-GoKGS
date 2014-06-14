package xt::Util;
use strict;
use warnings;
use Exporter qw/import/;
use Time::Piece qw/gmtime/;

our @EXPORT_OK = qw(
    cmp_deeply
    hash
    array
    uri
    integer
    real
    datetime
);

our %EXPORT_TAGS = (
    cmp_deeply => [qw/cmp_deeply hash array uri integer real datetime/],
);

sub cmp_deeply {
    my ( $got, $expected, $name ) = @_;

    Test::More::subtest(
        $name || 'unknown',
        sub { $expected->( $got ) }
    );

    return;
}

sub hash {
    my %expected = @_;

    sub {
        my $got = shift;
        my $name = shift || '$hash';

        Test::More::isa_ok( $got, 'HASH', $name );

        for my $key ( keys %$got ) {
            my $value = $got->{$key};

            my $n = "$name\->{$key}";
               $n .= ": '$value'" unless ref($value) =~ /^(?:HASH|ARRAY)$/;

            if ( ref $expected{$key} eq 'CODE' ) {
                local $_ = $value;
                my $bool = $expected{$key}->( $value, $n );
                Test::More::ok( $bool, $n ) if defined $bool;
            }
            elsif ( ref $expected{$key} eq 'ARRAY' ) {
                for my $e ( @{$expected{$key}} ) {
                    local $_ = $value;
                    my $bool = $e->( $value, $n );
                    Test::More::ok( $bool, $n ) if defined $bool;
                }
            }
        }

        return;
    };
}

sub array {
    my $expected = shift;

    sub {
        my $got = shift;
        my $name = shift || '$array';

        Test::More::isa_ok( $got, 'ARRAY', $name );

        my $i = 0;
        for my $g ( @$got ) {
            my $n = "$name\->[$i]";
               $n .= ": '$g'" unless ref($g) =~ /^(?:HASH|ARRAY)$/;

            local $_ = $g;
            my $bool = $expected->( $g, $n );
            Test::More::ok( $bool, $n ) if defined $bool;

            $i++;
        }

        return;
    };
}

sub uri {
    sub {
        my ( $got, $name ) = @_;
        Test::More::isa_ok( $got, 'URI', $name );
        return;
    };
}

sub integer {
    sub {
        my ( $got, $name ) = @_;

        Test::More::like(
            $got,
            qr{^(?:0|\-?[1-9][0-9]*)$},
            "$name should be integer"
        );

        return;
    };
}

sub real {
    sub {
        my ( $got, $name ) = @_;

        Test::More::like(
            $got,
            qr{^(?:0|\-?[1-9][0-9]*(?:\.[0-9]*[1-9])?)$},
            "$name should be real"
        );

        return;
    };
}

sub datetime {
    my $format = shift;

    sub {
        my ( $got, $name ) = @_;
        eval { gmtime->strptime( $got, $format ) };
        Test::More::ok( !$@, "$name should be '$format': $@" );
        return;
    };
}

1;
