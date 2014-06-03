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
    my $round = sub { m/ Round (\d+) Games$/ ? $1 : undef };
    my $handicap = sub { m/ H(\d+)$/ ? $1 : undef };
    my $board_size = sub { m/^(\d+)\x{d7}\d+ / ? $1 : undef };

    my $player = sub {
        m/^([a-zA-Z0-9]+)(?: \[([^\]]+)\])?$/ 
            ? { name => $1, rank => $2 || undef }
            : {};
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
        process '//td[4]', 'board_size' => [ 'TEXT', $board_size ];
        process '//td[4]', 'handicap' => [ 'TEXT', $handicap ];
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

sub scrape {
    my ( $self, @args ) = @_;
    my $result = $self->SUPER::scrape( @args );

    %$result = (
        name               => undef,
        round              => undef,
        games              => [],
        byes               => [],
        previous_round_uri => undef,
        next_round_uri     => undef,
        links              => {},
        %$result,
    );

    return $result unless @{$result->{games}};

    my ( @games, @byes );
    for my $game ( @{$result->{games}} ) {
        my $maybe_bye = delete $game->{maybe_bye};
        if ( $maybe_bye =~ /^Bye(?: \([^)]+\))?$/ ) {
            push @byes, {
                type => $1 || 'System',
                %{$game->{white}},
            };
        }
        else {
            push @games, $game;
        }
    }

    $result->{games} = \@games;
    $result->{byes}  = \@byes;

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
      round => 1,
  );
  # => {
  #     name => 'KGS Meijin Qualifier October 2012',
  #     round => '1',
  #     games => [
  #         {
  #             sgf_uri => 'http://files.gokgs.com/.../foo-bar.sgf',
  #             board_size => 19,
  #             white => {
  #                 name => 'foo',
  #                 rank => '2k',
  #             ],
  #             black => {
  #                 name => 'bar',
  #                 rank => '2k',
  #             },
  #         },
  #     ],
  #     links => {
  #         entrants => [
  #             {
  #                 sort_by => 'name',
  #                 uri     => 'http://www.gokgs.com/tournEntrants.jsp?id=762&sort=n',
  #             },
  #             ...
  #         ],
  #         rounds => [
  #             {
  #                 round      => 1,
  #                 start_time => '10/27/12 4:05 PM',
  #                 end_time   => '10/27/12 6:35 PM',
  #                 uri        => 'http://www.gokgs.com/tournGames.jsp?id=762&round=1',
  #             },
  #             ...
  #         ],
  #     },
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

=item $tourn_games->scrape

=item $tourn_games->query

=back

=head1 SEE ALSO

L<WWW::GoKGS>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
