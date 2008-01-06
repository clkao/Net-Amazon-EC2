package Net::Amazon::EC2::DescribeImageAttribute;
use Moose;

has 'image_id'              => ( is => 'ro', isa => 'Str' );
has 'launch_permissions'    => ( 
    is          => 'ro', 
    isa         => 'ArrayRef[Net::Amazon::EC2::LaunchPermission]',
    predicate   => 'has_launch_permissions',
    auto_deref  => 1,
);
has 'product_codes'         => ( 
    is          => 'ro', 
    isa         => 'ArrayRef[Net::Amazon::EC2::ProductCode]',
    predicate   => 'has_product_codes',
    auto_deref  => 1,
);

no Moose;
1;