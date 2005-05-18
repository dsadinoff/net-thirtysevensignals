#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Net::Backpack;

my $token = 'f627873eb6c7fe5063f12888c6d83217f2833160';
my $user  = 'davorg';

my $bp = Net::Backpack->new(user  => $user,
                            token => $token);

print Dumper $bp->list_all_pages(xml => shift);

my $page = $bp->create_page(title => 'A test page',
                            description => 'Created with the Backpack API');

print Dumper $bp->show_page(id => $page->{page}{id});

$bp->destroy_page(id => $page->{page}{id});

