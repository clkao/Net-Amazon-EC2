package Net::Amazon::EC2::BlockDeviceMapping;
use strict;
use Moose;

=head1 NAME

Net::Amazon::EC2::BlockDeviceMapping

=head1 DESCRIPTION

A class representing a block device mapping

=head1 ATTRIBUTES

=over

=item virtual_name (required)

Virtual name assigned to the device.

=item device_name (required)

Name of the device within Amazon EC2. 

=back

=cut

has 'virtual_name'	=> ( is => 'ro', isa => 'Str', required => 1 );
has 'device_name'	=> ( is => 'ro', isa => 'Str', required => 1 );

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <jkim@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2009 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;