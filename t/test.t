#!/usr/bin/env perl

use strict;
use warnings;

use Test::More	tests => 26;
use Test::Mojo;
use FindBin		'$Bin';
use File::Temp	'tempfile';
use File::Copy;

# work on a temporary db file
my (undef, $tempfn) = tempfile('test_db_XXXX');
copy("$Bin/test.db" => $tempfn);

# create a tester
require "$Bin/../managedb.pl";
my $t = Test::Mojo->new;
$t->max_redirects(1);

# check if the select atabase page is ok
$t 	-> get_ok('/') -> status_is(200)
	-> text_like(title => qr/Choosing SQLite database file/);
my $action_url = $t->tx->res->dom->at('form')->attrs->{action};
like( $action_url, qr|/database/choose/?$|, 'right url');

# now select the test database file and submit it
$t -> post_form_ok('/database/choose', {dbfile=>$tempfn})->status_is(200);
like($t->tx->req->url, qr|/database/?$|, 'right_url (redirected)');

$t 	-> text_like( title => qr/Browse database file/ )
	-> text_like( 'tbody tr:nth-child(1) td:nth-child(1) a', qr/first/)
	-> text_like( 'tbody tr:nth-child(2) td:nth-child(1) a', qr/second/)
	-> text_like( 'form h4:nth-child(1)', qr/Create new table/);

# now check tables structure
$t 	-> get_ok('/table/structure/first') -> status_is(200)
	-> text_like( title => qr/Table structure: first/ )
	-> text_like( 'tbody tr:nth-child(1) td:nth-child(2)', qr/foo/ )
	-> text_like( 'tbody tr:nth-child(2) td:nth-child(2)', qr/bar/ )
	-> text_like( 'tbody tr:nth-child(1) td:nth-child(3)', qr/text/ )
	-> text_like( 'tbody tr:nth-child(2) td:nth-child(3)', qr/text/ );

# browse some records from the first table
$t 	-> get_ok('/table/browse/first') -> status_is(200)
	-> text_like( title => qr/Browse table records: first/ )
	-> text_like( 'thead tr:nth-child(1) th:nth-child(1)', qr/foo/ )
	-> text_like( 'thead tr:nth-child(1) th:nth-child(2)', qr/bar/ )
	-> text_like( 'tbody tr:nth-child(1) td:nth-child(1)', qr/O/)
	-> text_like( 'tbody tr:nth-child(1) td:nth-child(2)', qr/HAI!/);

# delete the temporary database file
unlink $tempfn;
ok( !-e $tempfn, 'temporary database file deleted');