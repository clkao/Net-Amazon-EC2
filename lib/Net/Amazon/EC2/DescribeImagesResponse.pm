package Net::Amazon::EC2::DescribeImagesResponse;
use Moose;

has 'image_id'          => ( is => 'ro', isa => 'Str', required => 1 );
has 'image_state'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'image_owner_id'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'image_location'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'is_public'         => ( is => 'ro', isa => 'Str', required => 1 );
has 'product_codes'     => ( 
    is          => 'ro', 
    isa         => 'ArrayRef[Net::Amazon::EC2::ProductCode]', 
    predicate   => 'has_product_codes',
    auto_deref  => 1,
);

no Moose;
1;