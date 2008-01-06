package Net::Amazon::EC2::LaunchPermissionOperation;
use strict;
use Moose;

has 'add'			=> ( is => 'ro', isa => 'Net::Amazon::EC2::LaunchPermission' );
has 'remove'		=> ( is => 'ro', isa => 'Net::Amazon::EC2::LaunchPermission' );

no Moose;
1;