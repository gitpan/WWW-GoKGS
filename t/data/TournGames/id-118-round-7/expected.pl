{
  'byes' => [
    {
      'name' => 'botnoid',
      'rank' => '21k',
      'type' => 'System'
    },
    {
      'name' => 'Mango',
      'rank' => '-',
      'type' => 'No show'
    }
  ],
  'games' => [
    {
      'black' => {
        'name' => 'antbot',
        'rank' => '-'
      },
      'board_size' => 9,
      'result' => 'W+Forfeit',
      'sgf_uri' => bless( do{\(my $o = 'http://files.gokgs.com/games/2005/9/4/CrazyStone-antbot.sgf')}, 'URI::http' ),
      'start_time' => '2005-09-04T14:00Z',
      'white' => {
        'name' => 'CrazyStone',
        'rank' => '-'
      }
    },
    {
      'black' => {
        'name' => 'GNU',
        'rank' => '13k'
      },
      'board_size' => 9,
      'result' => 'B+Forfeit',
      'sgf_uri' => bless( do{\(my $o = 'http://files.gokgs.com/games/2005/9/4/gonzoBot-GNU.sgf')}, 'URI::http' ),
      'start_time' => '2005-09-04T14:00Z',
      'white' => {
        'name' => 'gonzoBot',
        'rank' => '-'
      }
    },
    {
      'black' => {
        'name' => 'tlsBot',
        'rank' => '-'
      },
      'board_size' => 9,
      'result' => 'B+Resign',
      'sgf_uri' => bless( do{\(my $o = 'http://files.gokgs.com/games/2005/9/4/viking5-tlsBot.sgf')}, 'URI::http' ),
      'start_time' => '2005-09-04T14:00Z',
      'white' => {
        'name' => 'viking5',
        'rank' => '-'
      }
    }
  ],
  'links' => {
    'entrants' => [
      {
        'sort_by' => 'name',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournEntrants.jsp?sort=n&id=118')}, 'URI::http' )
      },
      {
        'sort_by' => 'result',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournEntrants.jsp?sort=s&id=118')}, 'URI::http' )
      }
    ],
    'rounds' => [
      {
        'end_time' => '2005-09-04T09:00Z',
        'round' => 1,
        'start_time' => '2005-09-04T08:00Z',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=118&round=1')}, 'URI::http' )
      },
      {
        'end_time' => '2005-09-04T10:00Z',
        'round' => 2,
        'start_time' => '2005-09-04T09:00Z',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=118&round=2')}, 'URI::http' )
      },
      {
        'end_time' => '2005-09-04T11:00Z',
        'round' => 3,
        'start_time' => '2005-09-04T10:00Z',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=118&round=3')}, 'URI::http' )
      },
      {
        'end_time' => '2005-09-04T24:00Z',
        'round' => 4,
        'start_time' => '2005-09-04T11:00Z',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=118&round=4')}, 'URI::http' )
      },
      {
        'end_time' => '2005-09-04T13:00Z',
        'round' => 5,
        'start_time' => '2005-09-04T24:00Z',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=118&round=5')}, 'URI::http' )
      },
      {
        'end_time' => '2005-09-04T14:00Z',
        'round' => 6,
        'start_time' => '2005-09-04T13:00Z',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=118&round=6')}, 'URI::http' )
      },
      {
        'end_time' => '2005-09-04T15:00Z',
        'round' => 7,
        'start_time' => '2005-09-04T14:00Z',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=118&round=7')}, 'URI::http' )
      },
      {
        'end_time' => '2005-09-04T16:00Z',
        'round' => 8,
        'start_time' => '2005-09-04T15:00Z',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=118&round=8')}, 'URI::http' )
      },
      {
        'end_time' => '2005-09-04T17:00Z',
        'round' => 9,
        'start_time' => '2005-09-04T16:00Z',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=118&round=9')}, 'URI::http' )
      },
      {
        'end_time' => '2005-09-04T18:00Z',
        'round' => 10,
        'start_time' => '2005-09-04T17:00Z',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=118&round=10')}, 'URI::http' )
      }
    ]
  },
  'name' => 'Sixth KGS Computer Go Tournament - Formal division',
  'next_round_uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=118&round=8')}, 'URI::http' ),
  'previous_round_uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=118&round=6')}, 'URI::http' ),
  'round' => 7
}
