package Net::Amazon::EC2::SecurityGroup;
use Moose;

has 'owner_id'          => ( is => 'ro', isa => 'Str', required => 1 );
has 'group_name'        => ( is => 'ro', isa => 'Str', required => 1 );
has 'group_description' => ( is => 'ro', isa => 'Str', required => 1 );
has 'ip_permissions'    => ( 
    is          => 'ro', 
    isa         => 'ArrayRef[Net::Amazon::EC2::IpPermission]',
    auto_deref  => 1,
    predicate   => 'has_ip_permissions',
);

no Moose;
1;