package Net::Amazon::EC2::Errors;
use Moose;

has 'request_id'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'errors'        => ( 
    is          => 'rw', 
    isa         => 'ArrayRef[Net::Amazon::EC2::Error]',
    predicate   => 'has_errors',
    auto_deref  => 1,
    required    => 1,
);

no Moose;
1;