package Net::Amazon::EC2::ReservationInfo;
use Moose;

has 'reservation_id'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'owner_id'          => ( is => 'ro', isa => 'Str', required => 1 );
has 'group_set'         => ( 
    is          => 'ro', 
    isa         => 'ArrayRef[Net::Amazon::EC2::GroupSet]',
    required    => 1,
    auto_deref  => 1,
);
has 'instances_set'     => ( 
    is          => 'ro',
    isa         => 'ArrayRef[Net::Amazon::EC2::RunningInstances]',
    required    => 1,
    auto_deref  => 1,
);

no Moose;
1;