package Net::Amazon::EC2::GroupSet;
use Moose;

has 'group_id'  => ( is => 'ro', isa => 'Str', required => 1 );

no Moose;
1;