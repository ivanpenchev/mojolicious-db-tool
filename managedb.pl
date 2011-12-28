use Mojolicious::Lite;
use DBI;

my $ver = '0.1';
app->secret('hDfj3LkNr57wsV');

get '/' => sub {
	my $self = shift;
} => 'index';

get '/database' => sub {
	my $self = shift;
	my $conn = DBI->connect('dbi:SQLite:dbname='.$self->session->{dbfile}, '', '', {sqlite_unicode=>1});
	my $tables = $conn->selectall_arrayref( qq{ SELECT * FROM sqlite_master WHERE type='table' AND name!='sqlite_sequence' }, { Slice => {} });
	$self -> stash('database' => $self->session->{dbfile});
	$self -> stash('tables' => $tables);
	$self -> render;
	print $tables;
} => 'database';

get '/table/structure/:table_name' => sub {
	my $self = shift;
	my $table = $self->param('table_name');
	my $conn = DBI->connect('dbi:SQLite:dbname='.$self->session->{dbfile}, '', '', {sqlite_unicode=>1});
	my $table_structure = $conn->selectall_arrayref( qq { PRAGMA table_info($table) }, { Slice => {} });
	$self->stash( 'table' => $table_structure );
	$self -> render;
} => 'table';

get '/table/browse/:table_name' => sub {
	my $self = shift;
	my $table_name = $self->param('table_name');
	my $conn = DBI->connect('dbi:SQLite:dbname='.$self->session->{dbfile}, '', '', {sqlite_unicode=>1});
	my $records = $conn->selectall_arrayref( qq { SELECT * FROM $table_name }, { Slice => {} });
	my $table_info = $conn->selectall_arrayref( qq { PRAGMA table_info($table_name) }, { Slice => {} });
	$self->stash('records' => $records);
	$self->stash('columns' => $table_info);
	$self->render;
} => 'browse';

get '/table/insert/:table_name' => sub {
	my $self = shift;
	my $table_name = $self->param('table_name');
	my $conn = DBI->connect('dbi:SQLite:dbname='.$self->session->{dbfile}, '', '', {sqlite_unicode=>1});
	my $table_info = $conn->selectall_arrayref( qq { PRAGMA table_info($table_name) }, { Slice => {} });
	$self->stash('columns' => $table_info);
	$self->render;
} => 'insert';

post '/table/insert/:table_name' => sub {
	my $self = shift;
	my $table_name = $self->param('table_name');
	my $conn = DBI->connect('dbi:SQLite:dbname='.$self->session->{dbfile}, '', '', {sqlite_unicode=>1});
	my $table_info = $conn->selectall_arrayref( qq { PRAGMA table_info($table_name) }, { Slice => {} });
	my @columns;
	my @values;
	foreach my $column (@$table_info) {
		if(!$column->{pk}) {
			push(@columns, $column->{name});
			push(@values, "'".$self->param($column->{name})."'");
		}
	}
	my $query_columns = join ', ', @columns;
	my $query_values = join ', ', @values;
	my $query = 'INSERT INTO '.$table_name.' ('.$query_columns.') VALUES ('.$query_values.')';
	my $result = $conn->do($query) or die $conn->errstr;
	$self->redirect_to('/database/');
};

get '/table/new' => sub {
	my $self = shift;
	$self->stash('table_name' => $self->param('table_name'));
	$self->stash('table_cols_num' => $self->param('table_cols_num'));
	$self->render;
} => 'new-table';

post '/table/new' => sub {
	my $self = shift;
	my $conn = DBI->connect('dbi:SQLite:dbname='.$self->session->{dbfile}, '', '', {sqlite_unicode=>1});
	my $table_name = $self->param('table_name');
	my $table_cols_num = $self->param('table_cols_num');
	my $i = 1;
	my $query = qq { CREATE TABLE $table_name ( \n};
	while ( $table_cols_num >= $i ) {
		$query .= $self->param('column_'.$i.'_name') . ' ' . $self->param('column_'.$i.'_type');
		if( $self->param('column_'.$i.'_pk') ) { $query .= ' primary key'; }
		if( $self->param('column_'.$i.'_ai') ) { $query .= ' autoincrement'; }
		if( $self->param('column_'.$i.'_notnull') ) { $query .= ' not null'; }
		if( $self->param('column_'.$i.'_default') )
		{
			$query .= 'default '.$self->param('column_'.$i.'_default');
		}
		if($i != $table_cols_num) { $query .= ','; }
		$query .= "\n";
		print $i."\n";
		$i++;
	}
	$query .= "\n )";
	print $query;
	my $result = $conn->do($query) or die $conn->errstr;
	$self->redirect_to('/database/');
};

get '/table/drop/:table_name' => sub {
	my $self = shift;
	my $table_name = $self->param('table_name');
	my $conn = DBI->connect('dbi:SQLite:dbname='.$self->session->{dbfile}, '', '', {sqlite_unicode=>1});
	my $drop_result = $conn->do( qq { DROP TABLE $table_name }, undef) or die $conn->errstr;
	if( $drop_result )
	{
		$self->flash('success' => 'Table '.$table_name.' succesfully dropped.');
	}
	else
	{
		$self->flash('error' => 'There was an error while trying to drop table '.$table_name.'. Please try again later!');
	}
	$self->redirect_to('/database/');
};

post '/database/choose' => sub {
	my $self = shift;
	my $dbfile = $self->param('dbfile');
	$self -> session->{dbfile} = $dbfile;
	$self -> redirect_to('/database/');
};

app->start;

__DATA__

@@ index.html.ep
% title 'Choosing SQLite database file';
% layout 'main';
<form method="post" action="/database/choose">
	<h3>Select SQLite database file:</h3>
	<hr />
	<div class="clearfix">
		<label>SQLite database file(path):</label>
		<div class="input">
			<input type="text" name="dbfile">
		</div>
	</div>
	<div class="actions">
		<input type="submit" class="btn primary" name="choose" value="Choose">
	</div>
</form>

@@ insert.html.ep
% title 'Insert element into table'.$table_name;
% layout 'main';
<h2>Insert</h2>
<hr />
<form method="post" action="">
	% foreach my $column (@$columns) {
		<div class="clearfix">
			<label><%= $column->{name} %></label>
			<div class="input">
				<input type="text" name="<%= $column->{name} %>">
			</div>
		</div>
	% }
	<div class="actions">
		<a href="/database/" title="Back" class="btn primary">Back</a>
		<input type="submit" name="insert" class="btn success" value="Insert">
	</div>
</form>

@@ new-table.html.ep
% title 'Create new table';
% layout 'main';
<h2>Create new Table &raquo; <%= $table_name %></h2>
<form method="post" action="">
	<table>
		<thead>
			<tr> <th> Column </th> <th> Type </th> <th> Default </th> <th>Primary Key</th> <th> Auto Increment </th> <th>NOT NULL</th> </tr>
		</thead>
		<tbody>
			% my $i = 1;
			% while ($table_cols_num >= $i) {
				
				<tr>
					<td> <input type="text" class="span4" name="column_<%= $i %>_name" /> </td>
					<td> <input type="text" class="span4" name="column_<%= $i %>_type" /> </td>
					<td> <input type="text" name="column_<%= $i %>_default" /> </td>
					<td> <input type="checkbox" name="column_<%= $i %>_pk" /> </td>
					<td> <input type="checkbox" name="column_<%= $i %>_ai" /> </td>
					<td> <input type="checkbox" name="column_<%= $i %>_notnull" /> </td>
				</tr>

			% 	$i++;	
			% }
		</tbody>
	</table>
	<div class="actions" style="text-align: center; padding-left: 0;">
		<a href="/database/" title="Back" class="btn primary">Back</a>
		<input type="submit" name="insert" class="btn success" value="Create">
	</div>
</form>

@@ database.html.ep
% title 'Browse database file';
% layout 'main';
% if( defined flash 'error') {
	<div class="alert-message warning" data-alert>
		<a class="close" href="#">x</a>
		<p><strong><%= flash 'error' %></strong></p>
	</div>
% }

% if( defined flash 'success') {
	<div class="alert-message success" data-alert>
		<a class="close" href="#">x</a>
		<p><strong><%= flash 'success' %></strong></p>
	</div>
% }
<h2> <%= $database %>
<hr />
<h2> Current Tables </h2>
<hr />
% if(@$tables) {
	<table class="zebra-striped">
		<thead>
			<tr> <th class="header">Table</th> <th class="yellow">Options</th> <th class="blue">Size</th> 
		</thead>
		<tbody>
			% foreach my $table (@$tables) {
				<tr> 
					<td><a href="/table/structure/<%= $table->{name} %>" title="<%= $table->{name} %>"><%= $table->{name} %> </a></td> 
					<td> 
						<a href="/table/browse/<%= $table->{name} %>">Browse</a> | 
						<a href="/table/structure/<%= $table->{name} %>">Structure</a> | 
						<a href="/table/insert/<%= $table->{name} %>"><span class="label success">Insert</span></a> | 
						<a href="/table/drop/<%= $table->{name} %>"><span class="label important">Drop</span></a> 
					</td> 
					<td></td>
				</tr>
			% }
		</tbody>
	</table>
% } else {
	<p> There aren't any tables in this database yet. </p>
% }
<form method="get" action="/table/new">
	<h4> Create new table </h4>
	<div class="clearfix">
		<div class="input">
			<div class="inline-inputs">
				Table name:
				<input type="text" name="table_name"> 
				&nbsp;
				Number of columns:
				<input type="text" name="table_cols_num" style="width: 20px;">
			</div>
		</div>
	</div>
	<div class="actions" style="text-align: center; padding-left: 0;">
		<input type="submit" class="btn primary" value="Create">
	</div>
</form>

@@ browse.html.ep
% title 'Browse table records: '.$table_name;
% layout 'main';
<h2>Table: <%= $table_name %></h2>
<hr />
<table class="zebra-striped">
	<thead>
		<tr> 
			% foreach my $column (@$columns) {
				<th class="header"><%= $column->{name} %></th>
			% }
		</tr>
	</thead>
	<tbody>
		% foreach my $record (@$records) {
			<tr>
			% foreach my $column (@$columns) { 
					<td style="width:15px;"><%= $record->{$column->{name}} %></td> 
			% }
			</tr>
		%}
	</tbody>
</table>
<div style="text-align: center">
	<a href="/database" class="btn large primary">Back</a>
	<a href="/table/insert/<%= $table_name %>" class="btn large success">Insert</a>
</div>

@@ table.html.ep
% title 'Table structure';
% layout 'main';
<h2>Table: <%= $table_name %></h2>
<hr />
<table class="zebra-striped">
	<thead>
		<tr> 
			<th class="header">#</th> <th class="yellow">Column</th> <th class="blue">Type</th> <th>Not NULL</th> 
			<th class="green">Primary Key</th> 
		</tr>
	</thead>
	<tbody>
		% foreach my $row (@$table) {
			<tr> 
				<td style="width:15px;"><%= $row->{cid} %></td> <td><%= $row->{name} %></td> <td> <%= $row->{type} %></td> 
				<td> <%= $row->{notnull} %></td> <td> <%= $row->{pk} %> </td>
			</tr>
		% }
	</tbody>
</table>
<div style="text-align: center">
	<a href="/database" class="btn large primary">Back</a>
	<a href="/table/browse/<%= $table_name %>" class="btn large success">Browse Records</a>
</div>

@@ layouts/main.html.ep
<!DOCTYPE html>
<html>
	<head>
		<title>SQLite Database Managemenet - Mojolicious::Lite - <%= title %></title>
		<link rel="stylesheet" href="http://twitter.github.com/bootstrap/1.4.0/bootstrap.min.css">
		<script type="text/javascript" src="js/bootstrap-alerts.js"></script>
		<style>
		  /* Override some defaults */
		  html, body {
			background-color: #eee;
		  }
		  
		  body {
			padding-top: 40px; /* 40px to make the container go all the way to the bottom of the topbar */
		  }

		  .container > footer p {
			text-align: center; /* center align it with the container */
		  }

		  .container {
			width: 820px; /* downsize our container to make the content feel a bit tighter and more cohesive. NOTE: this removes two full columns from the grid, meaning you only go to 14 columns and not 16. */
		  }

		  /* The white background content wrapper */
		  .content {
			background-color: #fff;
			padding: 20px;
			margin: 0 -20px; /* negative indent the amount of the padding to maintain the grid system */
			-webkit-border-radius: 6px;
			-moz-border-radius: 6px;
			border-radius: 6px;
			-webkit-box-shadow: 0 1px 2px rgba(0,0,0,.2);
		   -moz-box-shadow: 0 1px 2px rgba(0,0,0,.2);
			box-shadow: 0 0px 3px rgba(0,0,0,.2);
		  }
		  
		  .hero-unit { padding: 10px; }

		  /* Page header tweaks */
		  .page-header {
			background-color: #f5f5f5;
			padding: 20px 20px 10px;
			margin: -20px -20px 20px;
		  }
		  
		  a.btn { text-align: center; margin: 0 auto; }
		  
		 table { margin-left: 15px; }
		  
		  footer { 
			border-top: none;
			margin-top: 7px;
			padding-top: 7px;
		}
		</style>
	</head>
	<body>
		<div class="container">
			<div class="content">

				<div class="row">
					<div class="span14">
						<%= content %>
					</div>
				</div>

			</div>
			<footer>
				<p> Powered by 
				<a href="http://mojolicio.us" title="Mojolicious"><img src="http://mojolicio.us/mojolicious-black.png" alt="Mojolicious"></a> and <a href="http://twitter.github.com/bootstrap/">Bootstrap</a></p>
			</footer>
		</div>
	</body>
</html>