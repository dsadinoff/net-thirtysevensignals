use Data::Dumper;		#  -*- perl -*-
use strict;
use Test::More tests => 11;
BEGIN { use_ok('Net::ThirtySevenSignals::Highrise') };

eval { Net::ThirtySevenSignals::Highrise->new };
ok($@);

eval { Net::ThirtySevenSignals::Highrise->new(user => $ENV{HIGHRISE_USER}) };
ok($@);

eval { Net::ThirtySevenSignals::Highrise->new(token => $ENV{HIGHRISE_TOKEN}) };
ok($@);

SKIP: {
    skip 'HIGHRISE_TOKEN and HIGHRISE_USER must be set', 6
	unless $ENV{HIGHRISE_TOKEN} && $ENV{HIGHRISE_USER};
    my $hr = Net::ThirtySevenSignals::Highrise->new(
	user  => $ENV{HIGHRISE_USER},
	token => $ENV{HIGHRISE_TOKEN},
	ssl => 1,
	);
    ok($hr);
    ok(ref $hr eq 'Net::ThirtySevenSignals::Highrise');
    my $res = $hr->people_list_all();
    note(" received ".scalar(@{$res})." peopel");
    # 7
    ok( @{ $res } > 1 );
    
    my $firstPerson = $res->[0];
    my $personID = $firstPerson->{id}[0]{content};
    
    my $taggyPersonID = '44406487';
    $personID = $taggyPersonID;
    
    my $tags4Person = $hr->tags_list_for_subject(subjectType=>'people',subjectID => $personID);
    # 8
    ok( @{$tags4Person} > 0);

    
    skip ("no HIGHRISE_EMAIL set", 1)
	unless $ENV{HIGHRISE_EMAIL};
    if( $ENV{HIGHRISE_EMAIL} ){
	my $criteriaResults = $hr->people_list_by_criteria(email=> $ENV{HIGHRISE_EMAIL});
	# 9
	ok(('ARRAY' eq ref( $criteriaResults))&&  ( 1== @{$criteriaResults} ), "criteria fetch");
    }
    note("HI");


    my $personRec = $hr->person_create(
	'firstName' => 'Joe', 'LastName' => 'Tester',
	'emailAddress' =>'joe@example.com',
	'companyName' =>'paternostro & kill',
	);
    my $newPersonID = $personRec->{id}[0]{content};
    
    my $newPerson = $hr->person_get(id=> $newPersonID);
    ok( $newPersonID && $newPerson, 'created personID');
    
    $hr->person_destroy(id => $newPersonID , xml=>1);

    $newPerson =undef;
    eval{
	$newPerson = $hr->person_get(id=> $newPersonID);
    };

    ok(!defined $newPerson, 'destroyed');
    
    
}

