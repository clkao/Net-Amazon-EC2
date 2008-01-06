package Net::Amazon::EC2::ProductInstanceResponse;
use strict;
use Moose;

has 'product_code'	=> ( is => 'ro', isa => 'Str' );
has 'instance_id'	=> ( is => 'ro', isa => 'Str' );
has 'owner_id'		=> ( is => 'ro', isa => 'Str' );

no Moose;
1;