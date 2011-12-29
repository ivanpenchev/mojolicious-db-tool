#!/usr/bin/env perl

use strict;
use warnings;

use Test::More	tests => 47;
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

# now lets test the creation of new table containing 4 columns
$t 	-> get_ok('/table/new?table_name=tests&table_cols_num=4') -> status_is(200);
$t 	-> post_form_ok('/table/new', {
	table_name=>'tests', table_cols_num=>4,
	column_1_name => 'id', column_1_type => 'integer', column_1_ai => 1, column_1_pk => 1, column_1_notnull => 1,
	column_2_name => 'test_name', column_2_type => 'varchar', column_2_notnull => 1,
	column_3_name => 'test_txt_result', column_3_type => 'text', column_3_notnull => 1,
	column_4_name => 'test_result', column_4_type => 'int', column_4_default => 1, column_4_notnull => 1
}) -> status_is(200);

# is the redirection correct?
like($t->tx->req->url, qr|/database/?$|, 'right url (redirect)');

# is the ne table created?
$t 	-> get_ok('/database/') -> status_is(200)
	-> text_like( 'tbody tr:last-child td:first-child a', qr/tests/);

# check if insert page is displayed correct
$t 	-> get_ok('/table/insert/tests') -> status_is(200)
	-> text_like( title => qr/Insert element into table tests/ )
	-> text_like( 'form div:nth-child(1) label:first-child', qr/id/ )
	-> text_like( 'form div:nth-child(4) label:first-child', qr/test_result/);

# now try to insert something into the newly created table
$t 	-> post_form_ok('/table/insert/tests', {
	test_name => 'Insertion test',
	test_txt_result => 'Passed/Completed',
	test_result => 1
}) -> status_is(200);

# is the redirection correct?
like($t->tx->req->url, qr|/database/?$|, 'right url (redirect)');

# now try to empty the newly created table
$t 	-> 	get_ok('/table/empty/tests') -> status_is(200);
# is the redirection correct?
like($t->tx->req->url, qr|/database/?$|, 'right url (redirect)');

# and finaly lets try to drop the table
$t 	-> get_ok('/table/drop/tests') -> status_is(200);

# delete the temporary database file
unlink $tempfn;
ok( !-e $tempfn, 'temporary database file deleted');