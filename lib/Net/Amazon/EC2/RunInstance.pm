package Net::Amazon::EC2::RunInstance;
use strict;
use Moose;

has 'image_id'			=> ( is => 'ro', isa => 'Str' );
has 'min_count'			=> ( is => 'ro', isa => 'Int' );
has 'max_count'			=> ( is => 'ro', isa => 'Int' );
has 'key_name'			=> ( is => 'ro', isa => 'Str' );

no Moose;
1;