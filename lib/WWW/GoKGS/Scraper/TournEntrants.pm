package WWW::GoKGS::Scraper::TournEntrants;
use strict;
use warnings;
use parent qw/WWW::GoKGS::Scraper/;
use URI;
use Web::Scraper;
use WWW::GoKGS::Scraper::Filters qw/datetime/;
use WWW::GoKGS::Scraper::TournLinks qw/process_links/;

sub _build_base_uri {
    URI->new('http://www.gokgs.com/tournEntrants.jsp');
}

sub _build_scraper {
    my $self = shift;
    my $name = sub { s/ \[[^\]]+\]$// };
    my $rank = sub { m/ \[([^\]]+)\]$/ ? $1 : undef };

    scraper {
        process '//h1', 'name' => [ 'TEXT', sub { s/ Players$// } ];
        process '//table[tr/th[3]/text()="Score"]//following-sibling::tr',
                'entrants[]' => scraper { # Swiss or McMahon
                    process '//td[1]', 'position' => 'TEXT';
                    process '//td[2]', 'name' => [ 'TEXT', $name ];
                    process '//td[2]', 'rank' => [ 'TEXT', $rank ];
                    process '//td[3]', 'score' => 'TEXT';
                    process '//td[4]', 'sos' => 'TEXT';
                    process '//td[5]', 'sodos' => 'TEXT';
                    process '//td[6]', 'notes' => 'TEXT'; };
        process '//table[tr/th[1]/text()="Name"]//following-sibling::tr',
                'entrants[]' => scraper { # Single or Double Elimination
                    process '//td[1]', 'name' => [ 'TEXT', $name ];
                    process '//td[1]', 'rank' => [ 'TEXT', $rank ];
                    process '//td[2]', 'standing' => 'TEXT'; };
        process '//table[tr/th[3]/text()="#"]//following-sibling::tr',
                'entrants[]' => scraper { # Round Robin
                    process '//td', 'columns[]' => 'TEXT';
                    result 'columns'; };
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
    my @filters = $self->get_filter( $key );
    @filters ? ( $key, \@filters ) : ();
}

sub scrape {
    my ( $self, @args ) = @_;
    local $SIG{__WARN__} = sub { die $_[0] };
    my $result = $self->SUPER::scrape( @args );

    return $result unless $result->{entrants};

    if ( !$result->{entrants}->[0] ) { # Round Robin
        shift @{$result->{entrants}};

        my @entrants;
        my $size = @{$result->{entrants}->[0]};
        for my $entrant ( @{$result->{entrants}} ) {
            $entrant->[0] =~ s/\(tie\)$//;

            push @entrants, {
                position => @$entrant == $size ? int shift @$entrant : $entrants[-1]{position},
                name     => shift @$entrant,
                number   => shift @$entrant,
                notes    => pop @$entrant,
                score    => 0 + pop @$entrant,
                results  => $entrant,
            };
        }

        for my $entrant ( @entrants ) {
            $entrant->{name} =~ /^([a-zA-Z0-9]+)(?: \[([^\]]+)\])?$/;
            $entrant->{name} = $1;
            $entrant->{rank} = $2;
        }

        my %results;
        for my $a ( @entrants ) {
            next unless $a->{number};
            for my $b ( @entrants ) {
                next if $b == $a;
                next unless $b->{number};
                $results{$a->{name}}{$b->{name}}
                    = $a->{results}->[$b->{number}-1] || q{};
            }
        }

        delete @{$_}{qw/number results/} for @entrants;

        $result->{entrants} = \@entrants;
        $result->{results}  = \%results if %results;
    }
    elsif ( exists $result->{entrants}->[0]->{score} ) { # Swiss, McMahon
        my $preceding;
        for my $entrant ( @{$result->{entrants}} ) {
            $entrant->{position} =~ s/\(tie\)$//;
            next if !$preceding or exists $entrant->{notes};
            $entrant->{notes}    = $entrant->{sodos};
            $entrant->{sodos}    = $entrant->{sos};
            $entrant->{sos}      = $entrant->{score};
            $entrant->{score}    = $entrant->{name};
            $entrant->{position} =~ /^([a-zA-Z0-9]+)(?: \[([^\]]+)\])?$/;
            $entrant->{name}     = $1;
            $entrant->{rank}     = $2;
            $entrant->{position} = $preceding->{position};
        }
        continue {
            $entrant->{position} = int $entrant->{position};
            $entrant->{sos}      += 0;
            $entrant->{sodos}    += 0;
            $entrant->{score}    += 0;

            $preceding = $entrant;
        }
    }
    else { # Double Elimination
    }

    for my $entrant ( @{$result->{entrants}} ) {
        delete $entrant->{rank} unless $entrant->{rank};
    }

    $result;
}

1;

__END__

=head1 NAME

WWW::GoKGS::Scraper::TournEntrants - KGS Tournament Entrants

=head1 SYNOPSIS

  use WWW::GoKGS::Scraper::TournEntrants;

  my $tourn_entrants = WWW::GoKGS::Scraper::TournEntrants->new;

  my $result = $tourn_entrants->query(
      id   => 762,
      sort => 's'
  );
  # => {
  #     name => 'KGS Meijin Qualifier October 2012',
  #     entrants => [
  #         {
  #             name     => 'foo',
  #             rank     => '5d',
  #             standing => 'Winner'
  #         },
  #         ...
  #     ],
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
  #                 end_time   => '2012-10-27T18:05Z',
  #                 uri        => '/tournGames.jsp?id=762&round=1',
  #             },
  #             ...
  #         ]
  #     }
  # }

=head1 DESCRIPTION

This class inherits from L<WWW::GoKGS::Scraper>.

=head2 ATTRIBUTES

=over 4

=item $URI = $tourn_entrants->base_uri

Defaluts to C<http://www.gokgs.com/tournEntrants.jsp>.
This attribute is read-only.

=item $UserAgent = $tourn_entrants->user_agent

=item $tourn_entrants->user_agent( LWP::UserAgent->new(...) )

Can be used to get or set an L<LWP::UserAgent> object which is used to
C<GET> the requested resource. Defaults to the C<LWP::UserAgent> object
shared by L<Web::Scraper> users (C<$Web::Scraper::UserAgent>).

=back

=head2 METHODS

=over 4

=item $tourn_entrants->add_filter( 'links.rounds[].start_time' => $filter )

=item $tourn_entrants->add_filter( 'links.rounds[].end_time' => $filter )

Adds a round start/end time filter. C<$filter> is called with a date string
such as C<2014-05-17T19:05Z>. C<$filter> can be either a filter class name
or a subref. See L<Web::Scraper::Filter> for details.

  use Time::Piece qw/gmtime/;

  $tourn_entrants->add_filter(
      'links.rounds[].start_time' => sub {
          my $start_time = shift; # => "2014-05-17T19:05Z"
          gmtime->strptime( $start_time, '%Y-%m-%dT%H:%MZ' );
      }
  );

=item $HashRef = $tourn_entrants->query( id => $tourn_id, sort => 's' )

=item $HashRef = $tourn_entrants->query( id => $tourn_id, sort => 'n' )

Given key-value pairs of query parameters, returns a hash reference
which represents the tournament entrants.
The hashref is formatted as follows:

=over 4

=item Single or Double Elimination tournaments

  {
      name => 'KGS Meijin Qualifier October 2012',
      entrants => [
          {
              name     => 'foo',
              rank     => '5d',
              standing => 'Winner'
          },
          ...
      ],
      links => {
         ...
      }
  }

=item Swiss or McMahon tournaments

  {
      name => 'June 2014 KGS bot tournament',
      entrants => [
          {
              position => 1,
              name     => 'Zen19S',
              rank     => '-',
              score    => 29,
              sos      => 678.5, # Sum of Opponents' Scores
              sodos    => 514,   # Sum Of Defeated Opponents' Scores
              notes    => 'Winner'
          },
          ...
      ],
      links => {
          ...
      }
  }

=item Round Robin tournaments

  {
      name => 'EGC 2011 19x19 Computer Go',
      entrants => [
          {
              position => 1,
              name     => 'pachi2',
              rank     => '-',
              score    => 2,
              notes    => 'Winner'
          },
          ...
      ],
      results => {
          'pachi2' => {
              'Zen19S'     => '0/1',
              'ManyFaces1' => '1/1',
              'mogobot5'   => '1/1'
          },
          ...
      },
      links => {
         ...
      }
  }

=back

=item $HashRef = $tourn_entrants->scrape( URI->new(...) )

=item $HashRef = $tourn_entrants->scrape( HTTP::Response->new(...) )

=item $HashRef = $tourn_entrants->scrape( $html[, $base_uri] )

=item $HashRef = $tourn_entrants->scrape( \$html[, $base_uri] )

=back

=head1 SEE ALSO

L<WWW::GoKGS>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

