package WWW::GoKGS;
use 5.008_009;
use strict;
use warnings;
use Carp qw/croak/;
use LWP::UserAgent;
use URI;
use WWW::GoKGS::Scraper::GameArchives;
use WWW::GoKGS::Scraper::Top100;
use WWW::GoKGS::Scraper::TournEntrants;
use WWW::GoKGS::Scraper::TournGames;
use WWW::GoKGS::Scraper::TournInfo;
use WWW::GoKGS::Scraper::TournList;

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    bless \%args, $class;
}

sub date_filter {
    $_[0]->{date_filter} ||= sub { $_[0] };
}

sub html_filter {
    $_[0]->{html_filter} ||= sub { $_[0] };
}

sub result_filter {
    $_[0]->{result_filter} ||= sub { $_[0] };
}

sub user_agent {
    my $self = shift;
    $self->{user_agent} ||= $self->_build_user_agent;
}

sub _build_user_agent {
    my $self = shift;

    LWP::UserAgent->new(
        agent => ref $self . '/' . $self->VERSION,
    );
}

sub _scraper {
    my $self = shift;
    $self->{scraper} ||= $self->_build_scraper;
}

sub _build_scraper {
    my $self = shift;

    +{ map { $_->base_uri->path => $_ } (
        WWW::GoKGS::Scraper::GameArchives->new(
            user_agent    => $self->user_agent,
            date_filter   => $self->date_filter,
            result_filter => $self->result_filter,
        ),
        WWW::GoKGS::Scraper::Top100->new(
            user_agent => $self->user_agent,
        ),
        WWW::GoKGS::Scraper::TournList->new(
            user_agent => $self->user_agent,
        ),
        WWW::GoKGS::Scraper::TournInfo->new(
            user_agent  => $self->user_agent,
            date_filter => $self->date_filter,
            html_filter => $self->html_filter,
        ),
        WWW::GoKGS::Scraper::TournEntrants->new(
            user_agent  => $self->user_agent,
            date_filter => $self->date_filter,
        ),
        WWW::GoKGS::Scraper::TournGames->new(
            user_agent    => $self->user_agent,
            date_filter   => $self->date_filter,
            result_filter => $self->result_filter,
        ),
    )};
}

sub game_archives {
    $_[0]->_scraper->{'/gameArchives.jsp'};
}

sub top_100 {
    $_[0]->_scraper->{'/top100.jsp'};
}

sub tourn_list {
    $_[0]->_scraper->{'/tournList.jsp'};
}

sub tourn_info {
    $_[0]->_scraper->{'/tournInfo.jsp'};
}

sub tourn_entrants {
    $_[0]->_scraper->{'/tournEntrants.jsp'};
}

sub tourn_games {
    $_[0]->_scraper->{'/tournGames.jsp'};
}

sub scrape {
    my $self = shift;
    my $stuff = defined $_[0] ? shift : q{};

    my $url = URI->new( $stuff );
       $url->authority( 'www.gokgs.com' ) unless $url->authority;
       $url->scheme( 'http' ) unless $url->scheme;

    my $scraper = $url =~ m{^https?://www\.gokgs\.com/} && $url->path;
       $scraper = $self->_scraper->{$scraper} if $scraper;

    croak "Don't know how to scrape '$stuff'" unless $scraper;

    $scraper->scrape( $url );
}

1;

__END__

=head1 NAME

WWW::GoKGS - KGS Go Server (http://www.gokgs.com/) Scraper

=head1 SYNOPSIS

  use WWW::GoKGS;

  my $gokgs = WWW::GoKGS->new;

  # Game archives
  my $game_archives_1 = $gokgs->scrape( '/gameArchives.jsp?user=foo' );
  my $game_archives_2 = $gokgs->game_archives->query( user => 'foo' );

  # Top 100 players
  my $top_100_1 = $gokgs->scrape( '/top100.jsp' );
  my $top_100_2 = $gokgs->top_100->query;

  # List of tournaments 
  my $tourn_list_1 = $gokgs->scrape( '/tournList.jsp?year=2014' );
  my $tourn_list_2 = $gokgs->tourn_list->query( year => 2014 );

  # Information for the tournament
  my $tourn_info_1 = $gokgs->scrape( '/tournInfo.jsp?id=123' );
  my $tourn_info_2 = $gokgs->tourn_info->query( id => 123 );

  # The tournament entrants
  my $tourn_entrants_1 = $gokgs->scrape( '/tournEntrans.jsp?id=123&sort=n' );
  my $tourn_entrants_2 = $gokgs->tourn_entrants->query( id => 123, sort => 'n' );

  # The tournament games
  my $tourn_games_1 = $gokgs->scrape( '/tournGames.jsp?id=123&round=1' );
  my $tourn_games_2 = $gokgs->tourn_games->query( id => 123, round => 1 );

=head1 DESCRIPTION

This module is a KGS Go Server (C<http://www.gokgs.com/>) scraper.

This class maps a URI preceded by C<http://www.gokgs.com/>
to a proper scraper.
The supported resources on KGS are as follows:

=over 4

=item KGS Game Archives (http://www.gokgs.com/archives.jsp)

Handled by L<WWW::GoKGS::Scraper::GameArchives>.

=item Top 100 KGS Players (http://www.gokgs.com/top100.jsp)

Handled by L<WWW::GoKGS::Scraper::Top100>.

=item KGS Tournaments (http://www.gokgs.com/tournList.jsp)

Handled by L<WWW::GoKGS::Scraper::TournList>,
L<WWW::GoKGS::Scraper::TournInfo>,
L<WWW::GoKGS::Scraper::TournEntrants> and
L<WWW::GoKGS::Scraper::TournGames>.

=back

=head2 ATTRIBUTES

=over 4

=item $UserAgent = $gokgs->user_agent

Returns an L<LWP::UserAgent> object which is used to C<GET> the requested
resource. This attribute is read-only.

  use LWP::UserAgent;

  my $gokgs = WWW::GoKGS->new(
      user_agent => LWP::UserAgent->new(
          agent => 'MyAgent/1.00'
      )
  );

=item $CodeRef = $gokgs->html_filter

Returns an HTML filter. Defaults to an anonymous subref which just returns
the given argument (C<sub { $_[0] }>). The callback is called with
an HTML string. The return value is used as the filtered value.
This attribute is read-only.

  my $gokgs = WWW::GoKGS->new(
      html_filter => sub {
          my $html = shift;
          $html =~ s/<.*?>//g; # strip HTML tags
          $html;
      }
  );

=item $CodeRef = $gokgs->date_filter

Returns a date filter. Defaults to an anonymous subref which just returns
the given argument (C<sub { $_[0] }>). The callback is called with
a date string such as C<2014-05-17T19:05Z>. The return value is used as
the filtered value. This attribute is read-only.

  use Time::Piece qw/gmtime/;

  my $gokgs = WWW::GoKGS->new(
      date_filter => sub {
          my $date = shift; # => "2014-05-17T19:05Z"
          gmtime->strptime( $date, '%Y-%m-%dT%H:%MZ' );
      }
  );

=item $CodeRef = $gokgs->result_filter

=item $gokgs->result_filter( sub { my $result = shift; ... } )

Can be used to get or set a game result filter. Defaults to an anonymous subref
which just returns the given argument (C<sub { $_[0] }>). The callback is
called with a game result string such as C<B+Resign>.
The return value is used as the filtered value.

  my $gokgs = WWW::GoKGS->new(
      result_filter => sub {
          my $result = shift; # => "B+Resign"

          # I prefer "B+R" to "B+Resign", 
          # while both of them are valid SGF-compatible format
          return 'B+R' if $result eq 'B+Resign';
          ...

          $result;
      }
  );

=item $GameArchive = $gokgs->game_archives

Returns a L<WWW::GoKGS::Scraper::GameArchives> object.
This attribute is read-only.

=item $Top100 = $gokgs->top_100

Returns a L<WWW::GoKGS::Scraper::Top100> object.
This attribute is read-only.

=item $TournList = $gokgs->tourn_list

Returns a L<WWW::GoKGS::Scraper::TournList> object.
This attribute is read-only.

=item $TournInfo = $gokgs->tourn_info

Returns a L<WWW::GoKGS::Scraper::TournInfo> object.
This attribute is read-only.

=item $TournEntrants = $gokgs->tourn_entrants

Returns a L<WWW::GoKGS::Scraper::TournEntrants> object.
This attribute is read-only.

=item $TournGames = $gokgs->tourn_games

Returns a L<WWW::GoKGS::Scraper::TournGames> object.
This attribute is read-only.

=back

=head2 METHODS

=over 4

=item $HashRef = $gokgs->scrape( '/gameArchives.jsp?user=foo' )

=item $HashRef = $gokgs->scrape( 'http://www.gokgs.com/gameArchives.jsp?user=foo' )

A shortcut for:

  my $uri = URI->new( 'http://www.gokgs.com/gameArchives.jsp?user=foo' );
  my $game_archives = $gokgs->game_archives->scrape( $uri );

See L<WWW::GoKGS::Scraper::GameArchives> for details.

=item $HashRef = $gokgs->scrape( '/top100.jsp' )

=item $HashRef = $gokgs->scrape( 'http://www.gokgs.com/top100.jsp' )

A shortcut for:

  my $uri = URI->new( 'http://www.gokgs.com/top100.jsp' );
  my $top_100 = $gokgs->top_100->scrape( $uri );

See L<WWW::GoKGS::Scraper::Top100> for details.

=item $HashRef = $gokgs->scrape( '/tournList.jsp?year=2014' )

=item $HashRef = $gokgs->scrape( 'http://www.gokgs.com/tournList.jsp?year=2014' )

A shortcut for:

  my $uri = URI->new( 'http://www.gokgs.com/tournList.jsp?year=2014' );
  my $tourn_list = $gokgs->tourn_list->scrape( $uri );

See L<WWW::GoKGS::Scraper::TournList> for details.

=item $HashRef = $gokgs->scrape( '/tournInfo.jsp?id=123' )

=item $HashRef = $gokgs->scrape( 'http://www.gokgs.com/tournInfo.jsp?id=123' )

A shortcut for:

  my $uri = URI->new( 'http://www.gokgs.com/tournInfo.jsp?id=123' );
  my $tourn_info = $gokgs->tourn_info->scrape( $uri );

See L<WWW::GoKGS::Scraper::TournInfo> for details.

=item $HashRef = $gokgs->scrape( '/tournEntrants.jsp?id=123&s=n' )

=item $HashRef = $gokgs->scrape( 'http://www.gokgs.com/tournEntrants.jsp?id=123&s=n' )

A shortcut for:

  my $uri = URI->new( 'http://www.gokgs.com/tournEntrants.jsp?id=123&s=n' );
  my $tourn_entrants = $gokgs->tourn_entrants->scrape( $uri );

See L<WWW::GoKGS::Scraper::TournEntrants> for details.

=item $HashRef = $gokgs->scrape( '/tournGames.jsp?id=123&round=1' )

=item $HashRef = $gokgs->scrape( 'http://www.gokgs.com/tournGames.jsp?id=123&round=1' )

A shortcut for:

  my $uri = URI->new( 'http://www.gokgs.com/tournGames.jsp?id=123&round=1' );
  my $tourn_games = $gokgs->tourn_games->scrape( $uri );

See L<WWW::GoKGS::Scraper::TournGames> for details.

=back

=head1 SEE ALSO

L<Web::Scraper>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
