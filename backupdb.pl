#! /usr/bin/perl -w

# Make a backup of a database and upload it to S3.

use strict;
use FileHandle;

scalar(@ARGV) == 1 || die "Usage: $0 <database name>\n";
my $dbname = shift @ARGV;

my $home = $ENV{'HOME'};
my $dbpasswd_fh = new FileHandle("<$home/.ccdbpasswd")
	|| die "Couldn't open $home/.ccdbpasswd: $!\n";
my $dbpasswd = <$dbpasswd_fh>;
die "Couldn't read db password from $home/.ccdbpasswd\n" if (!defined $dbpasswd);
chomp $dbpasswd;
$dbpasswd_fh->close();

my $date = `date +'%d-%m-%Y'`;
chomp $date;

my $backup_filename = "$dbname-$date.sql.bz2";

# Dump the database
my $cmd = "mysqldump -u cloudcoder -p'$dbpasswd' '$dbname' | (bzip2 --best > $backup_filename)";
print "cmd: $cmd\n";
system($cmd)/256 == 0
	|| die "mysqldump failed\n";

# vim:set ts=2:
