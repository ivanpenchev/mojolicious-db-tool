use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME 			=> 'mojolicious-db-tool',
	ABSTRACT		=> 'Database management software',
	AUTHOR			=> 'Ivan Penchev',
	EXE_FILES		=> ['managedb'],
	PREREQ_PM		=> {
		'Mojolicious'		=> 1.1,
		'DBD::SQLite'	=> 0
	}
);

1;