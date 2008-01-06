package Net::Amazon::EC2::IpPermission;
use Moose;

has 'ip_protocol'   => ( is => 'ro', isa => 'Str', required => 1 );
has 'from_port'     => ( is => 'ro', isa => 'Int', required => 1 );
has 'to_port'       => ( is => 'ro', isa => 'Int', required => 1 );
has 'ip_ranges'     => ( 
    is          => 'rw', 
    isa         => 'ArrayRef[Net::Amazon::EC2::IpRange]',
    predicate   => 'has_ip_ranges',
    auto_deref  => 1,
    required    => 0,
);
has 'groups'        => ( 
    is          => 'rw', 
    isa         => 'ArrayRef[Net::Amazon::EC2::UserIdGroupPair]',
    predicate   => 'has_groups',
    auto_deref  => 1,
    required    => 0,
);

no Moose;
1;