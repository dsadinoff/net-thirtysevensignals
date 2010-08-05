use Test::More tests => 7;
BEGIN { use_ok('Net::Highrise') };

eval { Net::Highrise->new };
ok($@);

eval { Net::Highrise->new(user => $ENV{HIGHRISE_USER}) };
ok($@);

eval { Net::Highrise->new(token => $ENV{HIGHRISE_TOKEN}) };
ok($@);

SKIP: {
  skip 'HIGHRISE_TOKEN and HIGHRISE_USER must be set', 3
    unless $ENV{HIGHRISE_TOKEN} && $ENV{HIGHRISE_USER};
  my $bp = Net::Highrise->new(user  => $ENV{HIGHRISE_USER},
			      token => $ENV{HIGHRISE_TOKEN});
  ok($bp);
  ok(ref $bp eq 'Net::Highrise');
  my $res = $bp->people_list_all();
use Data::Dumper;
  warn Dumper($res);
  ok( @{ $res} > 1 );

}

