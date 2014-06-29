package WWW::GoKGS::Scraper;
use strict;
use warnings;
use Carp qw/croak/;
use URI;

sub base_uri {
    croak 'call to abstract method ', __PACKAGE__, '::base_uri';
}

sub build_uri {
    my ( $class, @args ) = @_;
    my $uri = URI->new( $class->base_uri );
    $uri->query_form( @args ) if @args;
    $uri;
}

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $self = bless {}, $class;

    $self->init( \%args );

    $self;
}

sub init {
    my ( $self, $args ) = @_;

    $self->user_agent( $args->{user_agent} ) if exists $args->{user_agent};

    return;
}

sub _scraper {
    my $self = shift;
    $self->{scraper} ||= $self->_build_scraper;
}

sub _build_scraper {
    croak 'call to abstract method ', __PACKAGE__, '::_build_scraper';
}

sub user_agent {
    my ( $self, @args ) = @_;
    $self->_scraper->user_agent( @args );
}

sub scrape {
    my ( $self, @args ) = @_;
    $self->_scraper->scrape( @args );
}

sub query {
    my ( $self, @args ) = @_;
    $self->scrape( ref($self)->build_uri(@args) );
}

1;

__END__

=head1 NAME

WWW::GoKGS::Scraper - Abstract base class for KGS scrapers

=head1 SYNOPSIS

  use parent 'WWW::GoKGS::Scraper';
  use Web::Scraper;

  sub base_uri { 'http://www.gokgs.com/...' }

  sub _build_scraper {
      my $self = shift;

      scraper {
          ...
      };
  }

=head1 DESCRIPTION

This module is an abstract base class for KGS scrapers. KGS scrapers must
inherit from this class, and also implement the following methods:

=over 4

=item base_uri

Must return a URI string which represents a resource on KGS.
This method is called as a method on the class.

=item _build_scraper

Must return an L<Web::Scraper> object which can C<scrape> the resource.
This method is called as a method on the object.

=back

=head2 CLASS METHODS

=over 4

=item $URI = $class->build_uri( $k1 => $v1, $k2 => $v2, ... )

=item $URI = $class->build_uri({ $k1 => $v1, $k2 => $v2, ... })

=item $URI = $class->build_uri([ $k1 => $v1, $k2 => $v2, ... ])

Given key-value pairs of query parameters, constructs a L<URI> object
which consists of C<base_uri> and the paramters.

=back

=head2 INSTANCE METHODS

=over 4

=item $UserAgent = $scraper->user_agent

=item $scraper->user_agent( LWP::UserAgent->new(...) )

Can be used to get or set an L<LWP::UserAgent> object which is used to
C<GET> the requested resource. Defaults to the C<LWP::UserAgent> object
shared by L<Web::Scraper> users (C<$Web::Scraper::UserAgent>).

=item $scraper->scrape( URI->new(...) )

=item $scraper->scrape( HTTP::Response->new(...) )

=item $scraper->scrape( $html[, $base_uri] )

=item $scraper->scrape( \$html[, $base_uri] )

Given arguments are passed to the C<scrape> method of
an L<Web::Scraper> object built by the C<_build_scraper> method.

=item $scraper->query( $k1 => $v1, $k2 => $v2, ... )

Given key-value pairs of query parameters, constructs a L<URI> object
which consists of C<base_uri> and the parameters, then pass the C<URI>
to the C<scrape> method.

=back

=head1 SEE ALSO

L<WWW::GoKGS>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
