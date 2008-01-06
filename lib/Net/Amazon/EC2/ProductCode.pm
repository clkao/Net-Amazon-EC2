package Net::Amazon::EC2::ProductCode;
use Moose;

has 'product_code'  => ( is => 'ro', isa => 'Str' );

no Moose;
1;