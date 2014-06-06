package WWW::GoKGS::Scraper;
use strict;
use warnings;
use Carp qw/croak/;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $user_agent = delete $args{user_agent};
    my $self = bless { %args }, $class;

    $self->user_agent( $user_agent ) if $user_agent;

    $self;
}

sub base_uri {
    my $self = shift;
    return $self->{base_uri} if exists $self->{base_uri};
    $self->{base_uri} = $self->_build_base_uri;
}

sub _build_base_uri {
    croak 'call to abstract method ', __PACKAGE__, '::base_uri';
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
    my $url = $self->base_uri->clone;
    $url->query_form( @args );
    $self->scrape( $url );
}

1;

__END__

=head1 NAME

WWW::GoKGS::Scraper - Abstract base class for KGS scrapers

=head1 SYNOPSIS

  use parent 'WWW::GoKGS::Scraper';
  use URI;
  use Web::Scraper;

  sub _build_base_uri {
      URI->new('http://www.gokgs.com/...');
  }

  sub _build_scraper {
      my $self = shift;

      scraper {
          ...
      };
  }

=head1 DESCRIPTION

This module is an abstract base class for KGS scrapers.
KGS scrapers must inherit from this class, and also implement two methods;
C<_build_base_uri> and C<_build_scraper>. C<_build_base_uri> must return
a L<URI> object which represents a resource on KGS.
C<_build_scraper> must return an L<Web::Scraper> object which can C<scrape>
the resource. Both of them are called as a method on the object
with no parameters.

=head2 ATTRIBUTES

=over 4

=item $URI = $scraper->base_uri

Returns a L<URI> object which represents a resource on KGS.
This attribute is read-only.

=item $UserAgent = $scraper->user_agent

=item $scraper->user_agent( LWP::UserAgent->new(...) )

Can be used to get or set an L<LWP::UserAgent> object which is used to
C<GET> the requested resource. Defaults to the C<LWP::UserAgent> object
shared by L<Web::Scraper> users (C<$Web::Scraper::UserAgent>).

=back

=head2 METHODS

=over 4

=item $scraper->scrape( URI->new(...) )

=item $scraper->scrape( HTTP::Response->new(...) )

=item $scraper->scrape( $html[, $base_uri] )

=item $scraper->scrape( \$html[, $base_uri] )

Given arguments are passed to the C<scrape> method of
an L<Web::Scraper> object built by the C<_build_scraper> method.

=item $scraper->query( $k1 => $v1, $k2 => $v2, ... )

Given key-value pairs of query parameters,
constructs a L<URI> object which consists of C<base_uri> and the query
parameters, then pass the C<URI> to the C<scrape> method.

=back

=head1 SEE ALSO

L<WWW::GoKGS>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
