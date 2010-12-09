package Net::Amazon::EC2::TerminateInstancesResponse;
use Any::Moose;

=head1 NAME

Net::Amazon::EC2::TerminateInstancesResponse

=head1 DESCRIPTION

A class representing the response from a terminate_instance call.

=head1 ATTRIBUTES

=over

=item instance_id (required)

The instance id of the terminating instance.

=item shutdown_code (required)

A 16-bit unsigned integer. The high byte is an opaque internal 
value and should be ignored. The low byte is set based on the 
state represented

=item shutdown_name (required)

The current state of the instance.

=item previous_code (required)

A 16-bit unsigned integer. The high byte is an opaque internal 
value and should be ignored. The low byte is set based on the 
state represented.

=item previous_name (required)

The previous state of the instance.

=cut

has 'instance_id'   => ( is => 'ro', isa => 'Str' );
has 'shutdown_code'	=> ( is => 'ro', isa => 'Str' );
has 'shutdown_name'	=> ( is => 'ro', isa => 'Str' );
has 'previous_code' => ( is => 'ro', isa => 'Str' );
has 'previous_name' => ( is => 'ro', isa => 'Str' );

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <jkim@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2009 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Any::Moose;
1;