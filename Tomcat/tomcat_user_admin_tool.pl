#!/usr/bin/perl

############################
############################
## Tomcat User Admin Tool ##
############################
############################



######################
# Used Perl Packages #
######################
use strict;
use warnings;
use Switch;
use Tie::File;
use Getopt::Long qw(:config no_ignore_case);
use Carp;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET=1;


########
# MENU #
########
my $read;
my $add;
my $file;
my $delete;
my $username;
my $password;
my $roles;
my $verbose;
my $debug;
my $help;

Getopt::Long::GetOptions (
  'read'        => \$read,
  'add'         => \$add,
  'file=s'      => \$file,
  'delete'      => \$delete,
  'verbose'     => \$verbose,
  'debug'       => \$debug,
  'help'        => \$help,
  'username=s'  => \$username,
  'password=s'  => \$password,
  'roles=s'     => \$roles,

);


##########
# GLOBAL #
##########
$debug && print CYAN "file=".$file . "\n";

if (!defined($file) || $file eq "") {
        print RED "Please give me a file" . "\n";
        exit 1;
};


########
# READ #
########
if ($read) {
        my $line;
        if(open(FILE, "<$file")) {
                while($line = <FILE>) {
                        $line =~ s/^\s+|\s+$//g;
                        if ($line =~ /^#/ || $line =~ /<!--/) {
                                $debug && print CYAN $line . "\n";
                                #<user username="manager" password="157f5c3b48082f5d9d2bd24546bssf0edd23eab4" roles="manager-script,manager-jmx"/>
                        } elsif ($line =~ /<user username="(.*)" password="(.*)" roles="(.*)"/) {
                                $debug && print CYAN $line . "\n";

                                $username               = $1;
                                $password               = $2;
                                $roles                  = $3;
                                print GREEN "Found Entry: (" . "username=" . $username . " password=" . $password . " roles=" . $roles . ")" . "\n";
                        } else {
                                $debug && print CYAN $line . "\n";
                        }
                }
                close FILE;
        };
}


#######
# ADD #
#######
elsif ($add) {
        if (!defined($username) || $username eq "") {
                print RED "Please give me a username" . "\n";
                exit 1;
        };
        if (!defined($password) || $password eq "") {
                print RED "Please give me a password" . "\n";
                exit 1;
        };
        if (!defined($roles) || $roles eq "") {
                print RED "Please give me roles" . "\n";
                exit 1;
        };

        #Check if user already exists
        my $line;
        my $count = 0;
        if(open(FILE, "<$file")) {
                while($line = <FILE>) {
                        $line =~ s/^\s+|\s+$//g;
                        if ($line =~ /^#/ || $line =~ /<!--/) {
                                $debug && print CYAN $line . "\n";
                                #<user username="manager" password="157f5c3b48082f5d9d2bd24546bssf0edd23eab4" roles="manager-script,manager-jmx"/>
                        } elsif ($line =~ /<user username="$username" password="(.*)" roles="(.*)"/) {
                                $debug && print CYAN $line . "\n";

                                $password               = $1;
                                $roles                  = $2;
                                $debug && print CYAN "Found Entry: (" . "username=" . $username . " password=" . $password . " roles=" . $roles . ")" . "\n";
                                $count ++;
                        } else {
                                $debug && print CYAN $line . "\n";
                        }
                }
                close FILE;

                if ($count ne 0) {
                        print RED "Entry with User already exists" . "\n";
                        exit 1;
                }
        };

        my $searchstring = "</tomcat-users>";
        my $insertstring = '  <user username="' . $username . '" password="' . $password . '" roles="' . $roles . '"/>';
        my $deststring = $insertstring . "\n" . $searchstring;

        tie my @lines, 'Tie::File', $file or die $!;
        for my $line ( @lines ){
                $line =~ s/$searchstring/$deststring/g;
        }
        untie @lines;
        print GREEN "Entry Successfully added" . "\n";
}


##########
# DELETE #
##########
elsif ($delete) {
        if (!defined($username) || $username eq "") {
                print RED "Please give me a username" . "\n";
                exit 1;
        };

        #Check if user exists
        my $line;
        my $count = 0;
        if(open(FILE, "<$file")) {
                while($line = <FILE>) {
                        $line =~ s/^\s+|\s+$//g;
                        if ($line =~ /^#/ || $line =~ /<!--/) {
                                $debug && print CYAN $line . "\n";
                                #<user username="manager" password="157f5c3b48082f5d9d2bd24546bssf0edd23eab4" roles="manager-script,manager-jmx"/>
                        } elsif ($line =~ /<user username="$username" password="(.*)" roles="(.*)"/) {
                                $debug && print CYAN $line . "\n";

                                $password               = $1;
                                $roles                  = $2;
                                $debug && print CYAN "Found Entry: (" . "username=" . $username . " password=" . $password . " roles=" . $roles . ")" . "\n";
                                $count ++;
                        } else {
                                $debug && print CYAN $line . "\n";
                        }
                }
                close FILE;

                if ($count < 1) {
                        print RED "No Entry with User exists" . "\n";
                        exit 1;
                }
        }

        my $searchstring = '<user username="' . $username . '" password=".*" roles=".*"/>';
        my $deststring = '';

        tie my @lines, 'Tie::File', $file or die $!;
        for my $line ( @lines ){
                $line =~ s/$searchstring/$deststring/g;
        }
        untie @lines;
        print GREEN "All Entry Successfully deleted" . "\n";
}


#########
# OTHER #
#########
else {
  print <<EOL;
./script.pl <options>
  --read                         Read all Entrys and Output
  --add                          Add a new Entry (need --user, --password, --roles)
  --delete                       Delete a Entry (need --user)

  --file                         Full Path with Filename (Example: /etc/tomcat/tomcat-users.xml)
  --user                         User (Example: manager)
  --password                     Password (Example: 157f5c3b48082f5d9d2bd24546bssf0edd23eab4)
  --roles                        Roles (Example: manager-script,manager-jmx)

  --verbose
  --debug
  --help
EOL
exit;
}


#######
# END #
#######
$debug && exit 1;
