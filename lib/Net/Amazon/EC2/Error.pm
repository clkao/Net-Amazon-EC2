package Net::Amazon::EC2::Error;
use Moose;

has 'code'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'message'   => ( is => 'ro', isa => 'Str', required => 1 );

no Moose;
1;