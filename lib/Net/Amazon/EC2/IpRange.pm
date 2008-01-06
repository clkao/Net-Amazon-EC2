package Net::Amazon::EC2::IpRange;
use Moose;

has 'cidr_ip'  => ( is => 'ro', isa => 'Str' );

no Moose;
1;