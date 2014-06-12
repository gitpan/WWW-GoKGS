package WWW::GoKGS::Scraper::TournGames;
use strict;
use warnings FATAL => 'all';
use parent qw/WWW::GoKGS::Scraper/;
use URI;
use Web::Scraper;
use WWW::GoKGS::Scraper::Filters qw/datetime/;
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

    my $result = do {
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
            $canonical{$r} || $r;
        };
    };


    my $game = scraper {
        process '//td[1]/a', 'sgf_uri' => '@href';
        process '//td[2]', 'white' => [ 'TEXT', $player ];
        process '//td[3]', 'black' => [ 'TEXT', $player ];
        process '//td[3]', 'maybe_bye' => 'TEXT';
        process '//td[4]', 'setup' => 'TEXT';
        process '//td[5]', 'start_time' => [ 'TEXT', $self->get_filter('games[].start_time') ];
        process '//td[6]', 'result' => [ 'TEXT', $result ];
    };

    scraper {
        process '//h1', 'name' => [ 'TEXT', $name ];
        process '//h1', 'round' => [ 'TEXT', $round ];
        process '//table[@class="grid"]//following-sibling::tr',
                'games[]' => $game;
        process '//a[text()="Previous round"]', 'previous_round_uri' => '@href';
        process '//a[text()="Next round"]', 'next_round_uri' => '@href';
        process_links $self->_assoc_filter('links.rounds[].start_time'),
                      $self->_assoc_filter('links.rounds[].end_time');
    };
}

sub _build_filter {
    my $self = shift;

    {
        'games[].start_time' => [ \&datetime ],
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

    for my $game ( @games ) {
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
  #     byes => [
  #         {
  #             name => 'baz',
  #             rank => '2d',
  #             type => 'System'
  #         }
  #     ],
  #     next_round_uri => '/tournGames.jsp?id=762&round=2',
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

=back

=head2 METHODS

=over 4

=item $tourn_games->add_filter( 'games[].start_time' => $filter )

=item $tourn_games->add_filter( 'links.rounds[].start_time' => $filter )

=item $tourn_games->add_filter( 'links.rounds[].end_time' => $filter )

Adds a game start time or a round start/end time filter.
C<$filter> is called with a date string
such as C<2014-05-17T19:05Z>. C<$filter> can be either a filter class name
or a subref. See L<Web::Scraper::Filter> for details.

  use Time::Piece qw/gmtime/;

  $tourn_games->add_filter(
      'games[].start_time' => sub {
          my $start_time = shift; # => "2014-05-17T19:05Z"
          gmtime->strptime( $start_time, '%Y-%m-%dT%H:%MZ' );
      }
  );

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
