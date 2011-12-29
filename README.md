Simple SQLite database management tool powered by Mojolicious framework and Bootstrap.

-----------------------

Mojolicious Framework - http://mojolicio.us (https://github.com/kraih/mojo)
Bootstrap - http://twitter.github.com/bootstrap/

Developed by Ivan Penchev for Google Code-in Contest.

HOW-TO INSTALL
--------------

1. Install Perl - http://learn.perl.org/installing/
2. Download the mojolicioud-db-tool application from github and install it through cmd/terminal:
perl Makefile.PL
cpanm --installdeps .

Note that if  you don't have cpanm, you can install it like this:
$ curl -L cpanmin.us | perl - --sudo App::cpanminus

3. Start the application:
/path/to/managedb.pl daemon
4. Open your browser and load the app's home page which should be http://127.0.0.1:3000/.
Enter the path to the database file you want to manage. 
*Note that if the db file doesn't exist it will be automatically created.

--------------------------

*IMPORTANT: the SQLite database file should have write access permissions

You can always extend the application's functionality. 
For more information please read the Mojolicious documentation:
http://mojolicio.us/perldoc

--------------------------

And don't forget to have fun! - "Mojolicious"