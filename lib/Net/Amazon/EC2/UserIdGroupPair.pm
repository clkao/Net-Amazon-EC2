package Net::Amazon::EC2::UserIdGroupPair;
use Moose;

has 'user_id'       => ( is => 'ro', isa => 'Str' );
has 'group_name'    => ( is => 'ro', isa => 'Str' );

no Moose;
1;