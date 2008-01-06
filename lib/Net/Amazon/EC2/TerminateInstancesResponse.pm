package Net::Amazon::EC2::TerminateInstancesResponse;
use Moose;

has 'instance_id'   => ( is => 'ro', isa => 'Str' );

no Moose;
1;