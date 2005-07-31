# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Backpack.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Net::Backpack') };

eval { Net::Backpack->new };
ok($@);

eval { Net::Backpack->new(user => $ENV{BACKPACK_USER}) };
ok($@);

eval { Net::Backpack->new(token => $ENV{BACKPACK_TOKEN}) };
ok($@);

SKIP: {
  skip 'BACKPACK_TOKEN and BACKPACK_USER must be set', 2
    unless $ENV{BACKPACK_TOKEN} && $ENV{BACKPACK_USER};
  my $bp = Net::Backpack->new(user  => $ENV{BACKPACK_USER},
			      token => $ENV{BACKPACK_TOKEN});
  ok($bp);
  ok(ref $bp eq 'Net::Backpack');
}

