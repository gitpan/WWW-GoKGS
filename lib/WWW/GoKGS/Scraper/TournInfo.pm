package WWW::GoKGS::Scraper::TournInfo;
use strict;
use warnings;
use parent qw/WWW::GoKGS::Scraper/;
use URI;
use Web::Scraper;
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
        process_links date_filter => $self->date_filter;
    };
}

sub html_filter {
    my $self = shift;
    $self->{html_filter} = shift if @_;
    $self->{html_filter} ||= sub { $_[0] };
}

sub date_filter {
    my $self = shift;
    $self->{date_filter} = shift if @_;
    $self->{date_filter} ||= sub { $_[0] };
}

sub scrape {
    my ( $self, @args ) = @_;
    my $result = $self->SUPER::scrape( @args );

    return $result unless $result->{description};

    $result->{description} = $self->html_filter->(do {
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
      id => 762,
  );
  # => {
  #     name => 'KGS Meijin Qualifier October 2012',
  #     description => 'Welcome to the KGS Meijin October Qualifier! ...',
  #     links => {
  #         entrants => [
  #             {
  #                 sort_by => 'name',
  #                 uri => 'http://www.gokgs.com/tournEntrants.jsp?id=762&sort=n',
  #             },
  #             ...
  #         ],
  #         rounds => [
  #             {
  #                 round => '1',
  #                 start_time => '2012-10-27T16:05Z',
  #                 end_time => '2012-10-27T18:35Z',
  #                 uri => 'http://www.gokgs.com/tournGames.jsp?id=762&round=1',
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

=item $CodeRef = $tourn_info->html_filter

=item $tourn_info->html_filter( sub { my $html = shift; ... } )

Can be used to get or set an HTML filter.
Defaults to an anonymous subref which just returns
the given argument (C<sub { $_[0] }>). The callback is called with
an HTML string. The return value is used as the filtered value.

  $tourn_info->html_filter(sub { 
      my $html = shift;
      $html =~ s/<.*?>//g; # strip HTML tags
      $html;
  });

=item $CodeRef = $tourn_info->date_filter

=item $tourn_info->date_filter( sub { my $date = shift; ... } )

Can be used to get or set a date filter.
Defaults to an anonymous subref which just returns
the given argument (C<sub { $_[0] }>). The callback is called with
a date string such as C<2014-05-17T19:05Z>. The return value is used as
the filtered value.

  use Time::Piece qw/gmtime/;

  $tourn_info->date_filter(sub {
      my $date = shift; # => "2014-05-17T19:05Z"
      gmtime->strptime( $date, '%Y-%m-%dT%H:%MZ' );
  });

=back

=head2 METHODS

=over 4

=item $tourn_info->scrape

=item $tourn_info->query

=back

=head1 SEE ALSO

L<WWW::GoKGS>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
