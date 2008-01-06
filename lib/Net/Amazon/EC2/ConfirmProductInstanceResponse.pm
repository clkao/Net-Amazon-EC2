package Net::Amazon::EC2::ConfirmProductInstanceResponse;
use strict;
use Moose;

has 'result'	=> ( is => 'ro', isa => 'Str' );
has 'owner_id'	=> ( is => 'ro', isa => 'Str', required => 0 );

no Moose;
1;