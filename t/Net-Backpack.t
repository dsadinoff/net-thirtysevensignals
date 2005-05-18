# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Backpack.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Net::Backpack') };

my $token = $ENV{BACKPACK_TOKEN} 
  || die "You must set the environment variable BACKPACK_TOKEN\n";
my $user = $ENV{BACKPACK_USER}
  || die "You must set the environment variable BACKPACK_USER\n";

eval { Net::Backpack->new };
ok($@);

eval { Net::Backpack->new(user => $user) };
ok($@);

eval { Net::Backpack->new(token => $token) };
ok($@);

my $bp = Net::Backpack->new(user => $user, token => $token);
ok($bp);
ok(ref $bp eq 'Net::Backpack');

print $bp->list_all_pages;
