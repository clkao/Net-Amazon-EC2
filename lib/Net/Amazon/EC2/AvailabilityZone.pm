package Net::Amazon::EC2::AvailabilityZone;
use Moose;

=head1 NAME

Net::Amazon::EC2::AvailabilityZone

=head1 DESCRIPTION

A class representing an availability zone

=head1 ATTRIBUTES

=over

=item zone_name (required)

Name of the Availability Zone.

=item zone_state (required)

State of the Availability Zone. 

=back

=cut

has 'zone_name'		=> ( is => 'ro', isa => 'Str', required => 1 );
has 'zone_state'	=> ( is => 'ro', isa => 'Str', required => 1 );

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <jkim@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2008 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;