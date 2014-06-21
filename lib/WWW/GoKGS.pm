package WWW::GoKGS;
use 5.008_009;
use strict;
use warnings;
use Carp qw/croak/;
use LWP::UserAgent;
use Scalar::Util qw/blessed/;
use String::CamelCase qw/decamelize/;
use URI;
use WWW::GoKGS::Scraper::GameArchives;
use WWW::GoKGS::Scraper::Top100;
use WWW::GoKGS::Scraper::TournEntrants;
use WWW::GoKGS::Scraper::TournGames;
use WWW::GoKGS::Scraper::TournInfo;
use WWW::GoKGS::Scraper::TournList;

our $VERSION = '0.11';

__PACKAGE__->mk_accessors(
    '/gameArchives.jsp',
    '/top100.jsp',
    '/tournList.jsp',
    '/tournInfo.jsp',
    '/tournEntrants.jsp',
    '/tournGames.jsp',
);

sub _build_game_archives {
    my $self = shift;

    my $game_archives = WWW::GoKGS::Scraper::GameArchives->new(
        user_agent => $self->user_agent,
    );

    $game_archives->add_filter(
        'games[].start_time' => $self->date_filter,
    );

    $game_archives;
}

sub _build_top_100 {
    my $self = shift;

    WWW::GoKGS::Scraper::Top100->new(
        user_agent => $self->user_agent,
    );
}

sub _build_tourn_list {
    my $self = shift;

    WWW::GoKGS::Scraper::TournList->new(
        user_agent => $self->user_agent,
    );
}

sub _build_tourn_info {
    my $self = shift;

    my $tourn_info = WWW::GoKGS::Scraper::TournInfo->new(
        user_agent => $self->user_agent,
    );

    $tourn_info->add_filter(
        'description' => $self->html_filter,
        'links.rounds[].start_time' => $self->date_filter,
        'links.rounds[].end_time'   => $self->date_filter,
    );

    $tourn_info;
}

sub _build_tourn_entrants {
    my $self = shift;

    my $tourn_entrants = WWW::GoKGS::Scraper::TournEntrants->new(
        user_agent => $self->user_agent,
    );

    $tourn_entrants->add_filter(
        'links.rounds[].start_time' => $self->date_filter,
        'links.rounds[].end_time'   => $self->date_filter,
    );

    $tourn_entrants;
}

sub _build_tourn_games {
    my $self = shift;

    my $tourn_games = WWW::GoKGS::Scraper::TournGames->new(
        user_agent => $self->user_agent,
    );

    $tourn_games->add_filter(
        'games[].start_time' => $self->date_filter,
        'links.rounds[].start_time' => $self->date_filter,
        'links.rounds[].end_time'   => $self->date_filter,
    );

    $tourn_games;
}

sub mk_accessors {
    my ( $class, @paths ) = @_;

    for my $path ( @paths ) {
        my $method = join '::', $class, $class->accessor_name_for( $path );
        my $body = $class->make_accessor( $path );
        no strict 'refs';
        *$method = $body;
    }

    return;
}

sub accessor_name_for {
    my ( $class, $path ) = @_;
    my $name = $path;
    $name =~ s{^/}{};
    $name =~ s{\.jsp$}{};
    $name = $name eq 'top100' ? 'top_100' : decamelize $name;
    $name;
}

sub builder_name_for {
    my ( $class, $path ) = @_;
    my $name = $class->accessor_name_for( $path );
    $name = "_build_$name";
    $name;
}

sub make_accessor {
    my ( $class, $path ) = @_;
    my $builder = $class->builder_name_for( $path );

    if ( $class->can($builder) ) {
        sub {
            my $self = shift;

            if ( @_ ) {
                $self->set_scraper( $path => shift );
            }
            elsif ( $self->_has_scraper($path) ) {
                $self->get_scraper( $path );
            }
            else {
                $self->set_scraper( $path => $self->$builder );
                $self->get_scraper( $path );
            }
        };
    }
    else {
        sub {
            my $self = shift;
            return $self->get_scraper( $path ) unless @_;
            $self->set_scraper( $path => shift );
        };
    }
}

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    bless \%args, $class;
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

sub date_filter {
    $_[0]->{date_filter} ||= sub { $_[0] };
}

sub html_filter {
    $_[0]->{html_filter} ||= sub { $_[0] };
}

sub _scraper {
    $_[0]->{scraper} ||= {};
}

sub get_scraper {
    my ( $self, $path ) = @_;
    $self->_scraper->{$path};
}

sub _has_scraper {
    my ( $self, $path ) = @_;
    exists $self->_scraper->{$path};
}

sub set_scraper {
    my ( $self, @pairs ) = @_;
    my $scraper = $self->_scraper;

    croak "Odd number of arguments passed to 'set_scraper'" if @pairs % 2;

    while ( my ($key, $value) = splice @pairs, 0, 2 ) {
        if ( blessed $value and $value->can('scrape') ) {
            $scraper->{$key} = $value;
        }
        else {
            croak "$value ($key scraper) is missing 'scrape' method";
        }
    }

    return;
}

sub scrape {
    my ( $self, $arg ) = @_;

    my $uri = URI->new( $arg );
       $uri->authority( 'www.gokgs.com' ) unless $uri->authority;
       $uri->scheme( 'http' ) unless $uri->scheme;

    my $scraper = do {
        my $path = $uri =~ m{^https?://www\.gokgs\.com/} && $uri->path;
        my $accessor = $path && $self->accessor_name_for( $path );

        if ( $accessor and $self->can($accessor) ) {
            $self->$accessor;
        }
        elsif ( $path ) {
            $self->get_scraper( $path );
        }
        else {
            undef;
        }
    };

    croak "Don't know how to scrape '$arg'" unless $scraper;

    $scraper->scrape( $uri );
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
KGS allows the users to play a board game called go a.k.a. baduk (Korean)
or weiqi (Chinese). Although the web server provides resources generated
dynamically, such as Game Archives, they are formatted as HTML,
the only format. This module provides yet another representation of those
resources, Perl data structure.

This class maps a URI preceded by C<http://www.gokgs.com/>
to a proper scraper. The supported resources on KGS are as follows:

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

=item $GameArchives = $gokgs->game_archives

=item $gokgs->game_archives( WWW::GoKGS::Scraper::GameArchives->new(...) )

Can be used to get or set a scraper object which can C<scrape>
C</gameArchives.jsp>. Defaults to a L<WWW::GoKGS::Scraper::GameArchives>
object.

=item $Top100 = $gokgs->top_100

=item $gokgs->top_100( WWW::GoKGS::Scraper::Top100->new(...) )

Can be used to get or set a scraper object which can C<scrape>
C</top100.jsp>. Defaults to a L<WWW::GoKGS::Scraper::Top100> object.

=item $TournList = $gokgs->tourn_list

=item $gokgs->tourn_list( WWW::GoKGS::Scraper::TournList->new(...) )

Can be used to get or set a scraper object which can C<scrape>
C</tournList.jsp>. Defaults to a L<WWW::GoKGS::Scraper::TournList> object.

=item $TournInfo = $gokgs->tourn_info

=item $gokgs->tourn_info( WWW::GoKGS::Scraper::TournInfo->new(...) )

Can be used to get or set a scraper object which can C<scrape>
C</tournInfo.jsp>. Defaults to a L<WWW::GoKGS::Scraper::TournInfo> object.

=item $TournEntrants = $gokgs->tourn_entrants

=item $gokgs->tourn_entrants( WWW::GoKGS::Scraper::TournEntrants->new(...) )

Can be used to get or set a scraper object which can C<scrape>
C</tournEntrants.jsp>. Defaults to a L<WWW::GoKGS::Scraper::TournEntrants>
object.

=item $TournGames = $gokgs->tourn_games

=item $gokgs->tourn_games( WWW::GoKGS::Scraper::TournGames->new(...) )

Can be used to get or set a scraper object which can C<scrape>
C</tournGames.jsp>. Defaults to a L<WWW::GoKGS::Scraper::TournGames> object.

=back

=head2 INSTANCE METHODS

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

=item $scraper = $gokgs->get_scraper( $path )

Returns a scraper object which can C<scrape> a resource located at C<$path>
on KGS. If the scraper object does not exist, then C<undef> is returned.

  my $game_archives = $gokgs->get_scraper( '/gameArchives.jsp' );
  # => WWW::GoKGS::Scraper::GameArchives object

=item $gokgs->set_scraper( $path => $scraper )

=item $gokgs->set_scraper( $p1 => $s1, $p2 => $s2, ... )

Can be used to set a scraper object which can C<scrape> a resource located
at C<$path> on KGS. You can also set multiple scrapers in one C<set_scraper>
call.

  use Web::Scraper;
  use WWW::GoKGS::Scraper::FooBar; # isa WWW::GoKGS::Scraper

  $gokgs->set_scraper(
      '/fooBar.jsp' => WWW::GoKGS::Scraper::FooBar->new,
      '/barBaz.jsp' => scraper {
           process '.bar', baz => 'TEXT;
           ...
      }
  );

=back

=head2 CLASS METHODS

=over 4

=item $class->mk_accessors( $path )

=item $class->mk_accessors( @paths )

Creates the accessor method for a scraper which can C<scrape> C<$path>.
You can also create multiple accessors in one C<mk_accessors> call.

  use parent 'WWW::GoKGS';

  # Generates foo_bar() whose builder is _build_foo_bar()
  __PACKAGE__->mk_accessors( '/fooBar.jsp' );

  # Build a scraper object which can scrape /fooBar.jsp
  sub _build_foo_bar {
      my $self = shift;
      ...
  }

=item $CodeRef = $class->make_accessor( $path )

Returns a subroutine reference which acts as an accessor for the scraper
which can C<scrape> C<$path>.

=item $accessor_name = $class->accessor_name_for( $path )

Returns the accessor name of a scraper which can C<scrape> C<$path>.

  my $accessor_name = $class->accessor_name_for( '/fooBar.jsp' );
  # => "foo_bar"

=item $builder_name = $class->builder_name_for( $path )

Returns the builder name of a scraper which can C<scrape> C<$path>.

  my $builder_name = $class->builder_name_for( '/fooBar.jsp' );
  # => "_build_foo_bar"

=back

=head1 WRITING SCRAPERS

KGS scrapers should use a namespace which starts with
C<WWW::GoKGS::Scraper::>, and also should be a subclass of
L<WWW::GoKGS::Scraper> so that the users can not only use the module solely,
but also can add the scraper object to C<WWW::GoKGS> object as follows:

  use WWW::GoKGS::Scraper::FooBar; # your scraper

  # using set_scraper()
  $gokgs->set_scraper(
      '/fooBar.jsp' => WWW::GoKGS::Scraper::FooBar->new
  );

  # by subclassing
  use parent 'WWW::GoKGS';
  __PACKAGE__->mk_accessors( '/fooBar.jsp' );
  sub _build_foo_bar { WWW::GoKGS::Scraper::FooBar->new }

=head1 ENVIRONMENTAL VARIABLES

=over 4

=item AUTHOR_TESTING

Some tests for scrapers send HTTP requests to C<GET> resources on KGS.
When you run C<./Build test>, they are skipped by default
to avoid overloading the KGS server. To run those tests,
you have to set C<AUTHOR_TESTING> to true explicitly:

  $ perl Build.PL
  $ env AUTHOR_TESTING=1 ./Build test

Author tests are run by L<Travis CI|https://travis-ci.org/anazawa/p5-WWW-GoKGS>
once a day. You can visit the website to check whether the tests passed or not.

=back

=head1 ACKNOWLEDGEMENT

Thanks to wms, the author of KGS Go Server, we can enjoy playing go online
for free.

=head1 SEE ALSO

L<KGS Go Server|http://www.gokgs.com>, L<Web::Scraper>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
