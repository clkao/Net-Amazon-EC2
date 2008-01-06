package Net::Amazon::EC2::DescribeKeyPairsResponse;
use strict;
use Moose;

has 'key_name'          => ( is => 'ro', isa => 'Str', required => 1 );
has 'key_fingerprint'   => ( is => 'ro', isa => 'Str', required => 1 );

no Moose;
1;