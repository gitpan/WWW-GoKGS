{
  'entrants' => [
    {
      'name' => 'pachi2',
      'notes' => 'Winner',
      'position' => '1',
      'rank' => '-',
      'score' => '2',
      'sodos' => undef,
      'sos' => undef,
      'standing' => undef
    },
    {
      'name' => 'Zen19S',
      'notes' => 'Winner',
      'position' => '1',
      'rank' => '4d',
      'score' => '2',
      'sodos' => undef,
      'sos' => undef,
      'standing' => undef
    },
    {
      'name' => 'ManyFaces1',
      'notes' => '',
      'position' => '3',
      'rank' => '2d',
      'score' => '1',
      'sodos' => undef,
      'sos' => undef,
      'standing' => undef
    },
    {
      'name' => 'mogobot5',
      'notes' => '',
      'position' => '3',
      'rank' => '-',
      'score' => '1',
      'sodos' => undef,
      'sos' => undef,
      'standing' => undef
    }
  ],
  'links' => {
    'entrants' => [
      {
        'sort_by' => 'name',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournEntrants.jsp?sort=n&id=607')}, 'URI::http' )
      },
      {
        'sort_by' => 'result',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournEntrants.jsp?sort=s&id=607')}, 'URI::http' )
      }
    ],
    'rounds' => [
      {
        'end_time' => '2011-07-31T08:35Z',
        'round' => '1',
        'start_time' => '2011-07-31T07:00Z',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=607&round=1')}, 'URI::http' )
      },
      {
        'end_time' => '2011-07-31T10:10Z',
        'round' => '2',
        'start_time' => '2011-07-31T08:35Z',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=607&round=2')}, 'URI::http' )
      },
      {
        'end_time' => '2011-07-31T11:45Z',
        'round' => '3',
        'start_time' => '2011-07-31T10:10Z',
        'uri' => bless( do{\(my $o = 'http://www.gokgs.com/tournGames.jsp?id=607&round=3')}, 'URI::http' )
      }
    ]
  },
  'name' => 'EGC 2011 19x19 Computer Go',
  'results' => {
    'ManyFaces1' => {
      'Zen19S' => '0/1',
      'mogobot5' => '1/1',
      'pachi2' => '0/1'
    },
    'Zen19S' => {
      'ManyFaces1' => '1/1',
      'mogobot5' => '0/1',
      'pachi2' => '1/1'
    },
    'mogobot5' => {
      'ManyFaces1' => '0/1',
      'Zen19S' => '1/1',
      'pachi2' => '0/1'
    },
    'pachi2' => {
      'ManyFaces1' => '1/1',
      'Zen19S' => '0/1',
      'mogobot5' => '1/1'
    }
  }
}
