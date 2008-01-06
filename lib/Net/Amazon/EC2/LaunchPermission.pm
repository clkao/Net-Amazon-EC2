package Net::Amazon::EC2::LaunchPermission;
use Moose;

has 'group'         => ( is => 'ro', isa => 'Str' );
has 'user_id'       => ( is => 'ro', isa => 'Str' );

no Moose;
1;