package Net::Amazon::EC2::RunningInstances;
use Moose;

has 'instance_id'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'image_id'          => ( is => 'ro', isa => 'Str', required => 1 );
has 'private_dns_name'  => ( is => 'ro', isa => 'Str|Undef', default => '' );
has 'dns_name'          => ( is => 'ro', isa => 'Str|Undef', default => '' );
has 'reason'            => ( is => 'ro', isa => 'Str|Undef', default => '' );
has 'key_name'          => ( is => 'ro', isa => 'Str|Undef', default => '' );
has 'ami_launch_index'  => ( is => 'ro', isa => 'Str' );
has 'instance_type'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'launch_time'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'product_codes'     => ( 
    is          => 'ro', 
    isa         => 'ArrayRef[Net::Amazon::EC2::ProductCode]',
    auto_deref  => 1,
);
has 'instance_state'    => ( 
    is => 'ro', 
    isa => 'Net::Amazon::EC2::InstanceState', 
    required => 1
);

no Moose;
1;