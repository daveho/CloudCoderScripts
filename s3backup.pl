#! /usr/bin/perl -w

# Really simple script to copy a file to an S3 bucket.
# Credentials are read from ~/.s3credentials, which should
# consist of two lines: the access key id and the secret key.

use strict;
use FileHandle;
use Net::Amazon::S3;

my $quiet = 0;
if (scalar(@ARGV) > 0 && $ARGV[0] eq '-q') {
	$quiet = 1;
	shift @ARGV;
}

scalar(@ARGV) == 2 || Usage();

my $local_file = shift @ARGV;
my $bucket_name = shift @ARGV;

my ($access_key, $secret_key) = ReadCredentials();

my $s3 = Net::Amazon::S3->new({
	aws_access_key_id => $access_key,
	aws_secret_access_key => $secret_key,
	retry => 1,
});

my $bucket = $s3->bucket($bucket_name);
print "Transferring file $local_file to bucket $bucket_name..." unless ($quiet);
STDOUT->flush();

# Create a key name by stripping the directory part from the local filename
my $key_name = $local_file;
if ($local_file =~ m,^.*/([^/]+)$,) {
	$key_name = $1;
}

$bucket->add_key_filename($key_name, $local_file, { content_type => 'application/octet-stream' })
	|| die "Couldn't copy file to bucket: " . $s3->errstr . "\n";
print "Done!\n" unless $quiet;
exit 0;

sub Usage {
	print STDERR <<"USAGE";
Usage: s3backup.pl <local file> <bucket>
USAGE
	exit 1;
}

sub ReadCredentials {
	my $home = $ENV{'HOME'};
	my $credentials_fh = new FileHandle("<$home/.s3credentials")
		|| die "Couldn't open $home/.s3credentials: $!\n";
	
	my $access_key = <$credentials_fh>;
	chomp $access_key;
	my $secret_key = <$credentials_fh>;
	chomp $secret_key;

	$credentials_fh->close();

	die "Could not read access key\n" if (!defined $access_key);
	die "Could not read secret key\n" if (!defined $secret_key);

	return ($access_key, $secret_key);
}

# vim:set ts=2:
