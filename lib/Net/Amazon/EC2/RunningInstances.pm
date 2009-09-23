package Net::Amazon::EC2::RunningInstances;
use Moose;

=head1 NAME

Net::Amazon::EC2::RunningInstances

=head1 DESCRIPTION

A class representing a running instance.

=head1 ATTRIBUTES

=over

=item ami_launch_index (optional)

The AMI launch index, which can be used to find 
this instance within the launch group.

=item dns_name (optional)

The public DNS name assigned to the instance. This DNS 
name is contactable from outside the Amazon EC2 network. 
This element remains empty until the instance enters a 
running state.

=item image_id (required)

The image id of the AMI currently running in this instance.

=item instance_id (required)

The instance id of the launched instance.

=item instance_state (required)

An Net::Amazon::EC2::InstanceState object.

=item instance_type (required)

The type of instance launched.

=item key_name (optional)

The key pair name the instance was launched with.

=item launch_time (required)

The time the instance was started.

=item placement (required)

A Net::Amazon::EC2::PlacementResponse object.

=item private_dns_name (optional)

The private DNS name assigned to the instance. This DNS 
name can only be used inside the Amazon EC2 network. 
This element remains empty until the instance enters a 
running state.

=item product_codes (optional)

An array ref of Net::Amazon::EC2::ProductCode objects.

=item reason (optional)

The reason for the most recent state transition.

=item platform (optional)

The operating system for this instance.

=item monitoring (optional)

The state of monitoring on this instance.

=cut

has 'ami_launch_index'  => ( is => 'ro', isa => 'Str', required => 0 );
has 'dns_name'          => ( is => 'ro', isa => 'Maybe[Str]', required => 0 );
has 'image_id'          => ( is => 'ro', isa => 'Str', required => 1 );
has 'instance_id'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'instance_state'    => ( 
    is => 'ro', 
    isa => 'Net::Amazon::EC2::InstanceState', 
    required => 1
);
has 'instance_type'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'key_name'          => ( is => 'ro', isa => 'Maybe[Str]', required => 0 );
has 'launch_time'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'placement'			=> ( is => 'ro', isa => 'Net::Amazon::EC2::PlacementResponse', required => 1 );
has 'private_dns_name'  => ( is => 'ro', isa => 'Maybe[Str]', required => 0 );
has 'product_codes'     => ( 
    is          => 'rw', 
    isa         => 'ArrayRef[Net::Amazon::EC2::ProductCode]',
    auto_deref  => 1,
    required	=> 0,
);
has 'reason'            => ( is => 'ro', isa => 'Maybe[Str]', required => 0 );
has 'platform'			=> ( is => 'ro', isa => 'Maybe[Str]', required => 0 );
has 'monitoring'		=> ( is => 'ro', isa => 'Maybe[Str]', required => 0 );

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <jkim@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2009 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;