package Net::Amazon::EC2::KeyPair;
use Moose;

extends 'Net::Amazon::EC2::DescribeKeyPairsResponse';

has 'key_material'   => ( is => 'ro', isa => 'Str', required => 1 );

no Moose;
1;