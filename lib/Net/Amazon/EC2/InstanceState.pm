package Net::Amazon::EC2::InstanceState;
use Moose;

# XXX need to revisit and put in something to deal with codes
has 'code'  => ( is => 'ro', isa => 'Int' );
has 'name'  => ( is => 'ro', isa => 'Str' );

no Moose;
1;