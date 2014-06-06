package WWW::GoKGS::Scraper::TournGames;
use strict;
use warnings;
use parent qw/WWW::GoKGS::Scraper/;
use URI;
use Web::Scraper;
use WWW::GoKGS::Scraper::TournLinks qw/process_links/;

sub _build_base_uri {
    URI->new('http://www.gokgs.com/tournGames.jsp');
}

sub _build_scraper {
    my $self = shift;
    my $name = sub { s/ Round \d+ Games$// };
    my $round = sub { m/ Round (\d+) Games$/ ? int $1 : undef };

    my $player = sub {
        m/^([a-zA-Z0-9]+)(?: \[([^\]]+)\])?$/ 
            ? { name => $1, $2 ? (rank => $2) : () }
            : undef;
    };

    my $start_time = sub {
        my $date = shift;
        my ( $mon, $mday, $yy, $hour, $min, $ampm )
            = $date =~ m{^(\d\d?)/(\d\d?)/(\d\d) (\d\d?):(\d\d) (AM|PM)$};
        sprintf '%04d-%02d-%02dT%02d:%02dZ',
                $yy + 2000, $mon, $mday,
                $ampm eq 'PM' ? $hour + 12 : $hour, $min;
    };

    my $game = scraper {
        process '//td[1]/a', 'sgf_uri' => '@href';
        process '//td[2]', 'white' => [ 'TEXT', $player ];
        process '//td[3]', 'black' => [ 'TEXT', $player ];
        process '//td[3]', 'maybe_bye' => 'TEXT';
        process '//td[4]', 'setup' => 'TEXT';
        process '//td[5]', 'start_time' => [ 'TEXT', $start_time, $self->date_filter ];
        process '//td[6]', 'result' => 'TEXT';
    };

    scraper {
        process '//h1', 'name' => [ 'TEXT', $name ];
        process '//h1', 'round' => [ 'TEXT', $round ];
        process '//table[@class="grid"]//following-sibling::tr',
                'games[]' => $game;
        process '//a[text()="Previous round"]', 'previous_round_uri' => '@href';
        process '//a[text()="Next round"]', 'next_round_uri' => '@href';
        process_links date_filter => $self->date_filter;
    };
}

sub date_filter {
    my $self = shift;
    $self->{date_filter} = shift if @_;
    $self->{date_filter} ||= sub { $_[0] };
}

sub result_filter {
    my $self = shift;
    $self->{result_filter} = shift if @_;
    $self->{result_filter} ||= sub { $_[0] };
}

sub scrape {
    my ( $self, @args ) = @_;
    my $result = $self->SUPER::scrape( @args );

    return $result unless $result->{games};

    my ( @games, @byes );
    for my $game ( @{$result->{games}} ) {
        my $maybe_bye = delete $game->{maybe_bye};
        if ( $maybe_bye =~ /^Bye(?: \(([^\)]+)\))?$/ ) {
            push @byes, {
                type => $1 || 'System',
                %{$game->{white}},
            };
        }
        else {
            push @games, $game;
        }
    }

    my $result_filter = do {
        my $orig = $self->result_filter;
        
        # use SGF-compatible format whenever possible
        my %canonical = (
            'W+Res.'  => 'W+Resign',
            'B+Res.'  => 'B+Resign',
            'W+Forf.' => 'W+Forfeit',
            'B+Forf.' => 'B+Forfeit',
            'Jigo'    => 'Draw',
        );

        sub {
            my $r = shift;
            $orig->( $canonical{$r} || $r );
        };
    };

    for my $game ( @games ) {
        $game->{result}     = $result_filter->( $game->{result} );
        $game->{setup}      =~ /^(\d+)\x{d7}\d+ (?:H(\d+))?$/;
        $game->{board_size} = int $1;
        $game->{handicap}   = int $2 if $2;

        delete $game->{setup};
    }

    delete $result->{games};

    $result->{byes} = \@byes if @byes;
    $result->{games} = \@games if @games;

    $result;
}

1;

__END__

=head1 NAME

WWW::GoKGS::Scraper::TournGames - Games of the KGS tournament

=head1 SYNOPSIS

  use WWW::GoKGS::Scraper::TournGames;

  my $tourn_games = WWW::GoKGS::Scraper::TournGames->new;

  my $result = $tourn_games->query(
      id    => 762,
      round => 1
  );
  # => {
  #     name => 'KGS Meijin Qualifier October 2012',
  #     round => 1,
  #     games => [
  #         {
  #             sgf_uri => 'http://files.gokgs.com/.../foo-bar.sgf',
  #             white => {
  #                 name => 'foo',
  #                 rank => '3d',
  #             },
  #             black => {
  #                 name => 'bar',
  #                 rank => '1d',
  #             },
  #             board_size => 19,
  #             start_time => '2012-10-27T16:05Z',
  #             result => 'W+Resign'
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
  #                 end_time   => '2012-10-27T18:35Z',
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

=item $URI = $tuorn_games->base_uri

Defaults to C<http://www.gokgs.com/tournGames.jsp>.
This attribute is read-only.

=item $UserAgent = $tourn_games->user_agent

=item $tourn_games->user_agent( LWP::UserAgent->new(...) )

Can be used to get or set an L<LWP::UserAgent> object which is used to
C<GET> the requested resource. Defaults to the C<LWP::UserAgent> object
shared by L<Web::Scraper> users (C<$Web::Scraper::UserAgent>).

=item $CodeRef = $tourn_games->date_filter

=item $tourn_games->date_filter( sub { my $date = shift; ... } )

Can be used to get or set a date filter. Defaults to an anonymous subref
which just returns the given argument (C<sub { $_[0] }>). The callback is
called with a date string such as C<2014-05-17T19:05Z>.
The return value is used as the filtered value.

  use Time::Piece qw/gmtime/;

  $tourn_games->date_filter(sub {
      my $date = shift; # => "2014-05-17T19:05Z"
      gmtime->strptime( $date, '%Y-%m-%dT%H:%MZ' );
  });

=item $CodeRef = $tourn_games->result_filter

=item $tourn_games->result_filter( sub { my $result = shift; ... } )

Can be used to get or set a game result filter. Defaults to an anonymous subref
which just returns the given argument (C<sub { $_[0] }>). The callback is
called with a game result string such as C<B+Resign>.
The return value is used as the filtered value.

  $tourn_games->result_filter(sub {
      my $result = shift;

      # I prefer "B+R" to "B+Resign", 
      # while both of them are valid SGF-compatible format
      return 'B+R' if $result eq 'B+Resign';
      ...

      $result;
  });

=back

=head2 METHODS

=over 4

=item $HashRef = $tourn_games->scrape( URI->new(...) )

=item $HashRef = $tourn_games->scrape( HTTP::Response->new(...) )

=item $HashRef = $tourn_games->scrape( $html[, $base_uri] )

=item $HashRef = $tourn_games->scrape( \$html[, $base_uri] )

=item $HashRef = $tourn_games->query( id => $tourn_id, round => $round_nbr )

=back

=head1 SEE ALSO

L<WWW::GoKGS>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
