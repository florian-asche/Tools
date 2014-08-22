#!/usr/bin/perl

#################################
#################################
## Apache Groupfile Admin Tool ##
#################################
#################################



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
my $addusertogroup;
my $deleteuserfromgroup;
my $file;
my $group;
my $username;
my $verbose;
my $debug;
my $help;

Getopt::Long::GetOptions (
  'read'                => \$read,
  'addusertogroup'      => \$addusertogroup,
  'deleteuserfromgroup' => \$deleteuserfromgroup,
  'verbose'             => \$verbose,
  'debug'               => \$debug,
  'help'                => \$help,
  'file=s'              => \$file,
  'username=s'          => \$username,
  'group=s'             => \$group,

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
                        if ($line =~ /^#/) {
                                $debug && print CYAN $line . "\n";
                                #gruppe: admin user1 user2 user3
                        } elsif ($line =~ /(.*): (.*)/) {
                                $debug && print CYAN $line . "\n";

                                my $group               = $1;
                                my $users               = $2;
                                #my @usersarray=split(',',$users);
                                print GREEN "Found Entry: (" . "group=" . $group . " users=" . $users . ")" . "\n";
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
elsif ($addusertogroup) {
        if (!defined($group) || $group eq "") {
                print RED "Please give me a username" . "\n";
                exit 1;
        };
        if (!defined($username) || $username eq "") {
                print RED "Please give me a password" . "\n";
                exit 1;
        };

        #Check if user already exists for group
        my $line;
        my $count = 0;
        if(open(FILE, "<$file")) {
                while($line = <FILE>) {
                        $line =~ s/^\s+|\s+$//g;
                        if ($line =~ /^#/) {
                                $debug && print CYAN $line . "\n";
                        } elsif ($line =~ /$group:.*$username.*/) {
                                $debug && print RED $line . "\n";
                                $count ++;
                        } elsif ($line =~ /$group: (.*)/) {
                                $debug && print GREEN $line . "\n";
                                my $users = $1;
                                my $searchstring = $group . ': ' . $users;
                                my $insertstring = ' ' . $username;
                                my $deststring = $searchstring . $insertstring . "\n";

                                tie my @lines, 'Tie::File', $file or die $!;
                                for my $line ( @lines ){
                                        $line =~ s/$searchstring/$deststring/g;
                                }
                                untie @lines;
                                print GREEN "Entry Successfully added" . "\n";

                        } elsif ($line =~ /(.*): (.*)/) {
                                $debug && print CYAN $line . "\n";
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
}


##########
# DELETE #
##########
elsif ($deleteuserfromgroup) {
        if (!defined($group) || $group eq "") {
                print RED "Please give me a username" . "\n";
                exit 1;
        };
        if (!defined($username) || $username eq "") {
                print RED "Please give me a password" . "\n";
                exit 1;
        };

        #Check if user already exists for group
        my $line;
        my $count = 0;
        if(open(FILE, "<$file")) {
                while($line = <FILE>) {
                        $line =~ s/^\s+|\s+$//g;
                        if ($line =~ /^#/) {
                                $debug && print CYAN $line . "\n";
                        } elsif ($line =~ /$group: (.*)$username(.*)/) {
                                $debug && print GREEN $line . "\n";
                                $count ++;

                                my $searchstring = $line;
                                my $deststring = $group . ': ' . $1 . $2 . "\n";

                                tie my @lines, 'Tie::File', $file or die $!;
                                for my $line ( @lines ){
                                        $line =~ s/$searchstring/$deststring/g;
                                }
                                untie @lines;
                                print GREEN "Entry Successfully deleted" . "\n";
                        } else {
                                $debug && print CYAN $line . "\n";
                        }
                }
                close FILE;

                if ($count eq 0) {
                        print RED "No Entry found, which can be deleted" . "\n";
                        exit 1;
                }
        };
}


#########
# OTHER #
#########
else {
  print <<EOL;
./script.pl <options>
  --read                         Read all Entrys and Output
  --addusertogroup               Add a User to a existing Group (need --group, --user)
  --deleteuserfromgroup          Delete a User from a existing Group (need --group, --user)

  --file                         Full Path with Filename (Example: /etc/apache2/group)
  --group                        Group (Example: gruppe1)
  --user                         User (Example: benutzer1)

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

