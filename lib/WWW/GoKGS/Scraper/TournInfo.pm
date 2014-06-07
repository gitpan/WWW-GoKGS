package WWW::GoKGS::Scraper::TournInfo;
use strict;
use warnings FATAL => 'all';
use parent qw/WWW::GoKGS::Scraper/;
use URI;
use Web::Scraper;
use WWW::GoKGS::Scraper::Filters qw/datetime/;
use WWW::GoKGS::Scraper::TournLinks qw/process_links/;

sub _build_base_uri {
    URI->new('http://www.gokgs.com/tournInfo.jsp');
}

sub _build_scraper {
    my $self = shift;

    scraper {
        process '//h1', 'name' => [ 'TEXT', sub { s/ \([^)]+\)$// } ];
        process '//node()[preceding-sibling::h1 and following-sibling::div]',
                'description[]' => sub { $_[0]->as_XML };
        process_links $self->_assoc_filter('links.rounds[].start_time'),
                      $self->_assoc_filter('links.rounds[].end_time');
    };
}

sub _build_filter {
    my $self = shift;

    {
        'links.rounds[].start_time' => [ \&datetime ],
        'links.rounds[].end_time'   => [ \&datetime ],
    };
}

sub _assoc_filter {
    my ( $self, $key ) = @_;
    ( $key, [ $self->get_filter($key) ] );
}

sub scrape {
    my ( $self, @args ) = @_;
    my $result = $self->SUPER::scrape( @args );

    return $result unless $result->{description};

    $result->{description} = $self->run_filter('description', do {
        join q{}, @{$result->{description}};
    });

    $result;
}

1;

__END__

=head1 NAME

WWW::GoKGS::Scraper::TournInfo - Information for the KGS tournament

=head1 SYNOPSIS

  use WWW::GoKGS::Scraper::TournInfo;

  my $tourn_info = WWW::GoKGS::Scraper::TournInfo->new;

  my $result = $tourn_info->query(
      id => 762
  );
  # => {
  #     name => 'KGS Meijin Qualifier October 2012',
  #     description => 'Welcome to the KGS Meijin October Qualifier! ...',
  #     links => {
  #         entrants => [
  #             {
  #                 sort_by => 'name',
  #                 uri     => '/tournEntrants.jsp?id=762&sort=n'
  #             },
  #             {
  #                 sort_by => 'result',
  #                 uri     => '/tournEntrants.jsp?id=762&sort=s'
  #             }
  #         ],
  #         rounds => [
  #             {
  #                 round      => 1,
  #                 start_time => '2012-10-27T16:05Z',
  #                 end_time   => '2012-10-27T18:35Z',
  #                 uri        => '/tournGames.jsp?id=762&round=1'
  #             },
  #             ...
  #         ]
  #     }
  # }

=head1 DESCRIPTION

This class inherits from L<WWW::GoKGS::Scraper>.

=head2 ATTRIBUTES

=over 4

=item $URI = $tourn_info->base_uri

Defaults to C<http://www.gokgs.com/tournInfo.jsp>.
This attribute is read-only.

=item $UserAgent = $tourn_info->user_agent

=item $tourn_info->user_agent( LWP::UserAgent->new(...) )

Can be used to get or set an L<LWP::UserAgent> object which is used to
C<GET> the requested resource. Defaults to the C<LWP::UserAgent> object
shared by L<Web::Scraper> users (C<$Web::Scraper::UserAgent>).

=back

=head2 METHODS

=over 4

=item $tourn_info->add_filter( 'description' => $filter )

Adds a tournament description filter. C<$filter> is called with
an HTML string. C<$filter> can be either a filter class name
or a subref. See L<Web::Scraper::Filter> for details.

  $tourn_info->add_filter(
      'description' => sub { 
          my $html = shift;
          $html =~ s/<.*?>//g; # strip HTML tags
          $html;
      }
  );

=item $tourn_info->add_filter( 'links.rounds[].start_time' => $filter )

=item $tourn_info->add_filter( 'links.rounds[].end_time' => $filter )

Adds a round start/end time filter. C<$filter> is called with a date string
such as C<2014-05-17T19:05Z>. C<$filter> can be either a filter class name
or a subref. See L<Web::Scraper::Filter> for details.

  use Time::Piece qw/gmtime/;

  $tourn_info->add_filter(
      'links.rounds[].start_time' => sub {
          my $start_time = shift; # => "2014-05-17T19:05Z"
          gmtime->strptime( $start_time, '%Y-%m-%dT%H:%MZ' );
      }
  );

=item $HashRef = $tourn_info->scrape( URI->new(...) )

=item $HashRef = $tourn_info->scrape( HTTP::Response->new(...) )

=item $HashRef = $tourn_info->scrape( $html[, $base_uri] )

=item $HashRef = $tourn_info->scrape( \$html[, $base_uri] )

=item $HashRef = $tourn_info->query( id => $tourn_id )

=back

=head1 SEE ALSO

L<WWW::GoKGS>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
