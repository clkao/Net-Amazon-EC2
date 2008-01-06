package Net::Amazon::EC2::ConsoleOutput;
use Moose;

has 'instance_id'   => ( is => 'ro', isa => 'Str' );
has 'timestamp'     => ( is => 'ro', isa => 'Str' );
has 'output'        => ( is => 'ro', isa => 'Str' );

no Moose;
1;