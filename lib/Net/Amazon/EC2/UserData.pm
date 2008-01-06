package Net::Amazon::EC2::UserData;
use strict;
use Moose;

has 'data'	=> ( is => 'ro', isa => 'Str' );

no Moose;
1;