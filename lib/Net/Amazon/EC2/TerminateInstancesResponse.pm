package Net::Amazon::EC2::TerminateInstancesResponse;
use Moose;

=head1 NAME

Net::Amazon::EC2::TerminateInstancesResponse

=head1 DESCRIPTION

A class representing the response from a terminate_instance call.

=head1 ATTRIBUTES

=over

=item instance_id (required)

The instance id of the terminating instance.

=cut

has 'instance_id'   => ( is => 'ro', isa => 'Str' );

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <jkim@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2008 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;