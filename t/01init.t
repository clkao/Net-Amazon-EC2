use strict;
use blib;
use Test::More tests => 1;

BEGIN { use_ok( 'Net::Amazon::EC2' ); }

my $ec2 = Net::Amazon::EC2->new(
	AWSAccessKeyId => 'YOUR_ACCESS_KEY_HERE', 
	SecretAccessKey => 'YOUR_SECRET_KEY_HERE'
);
