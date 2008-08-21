package Net::Amazon::EC2::Attachment;
use Moose;

=head1 NAME

Net::Amazon::EC2::Attachment

=head1 DESCRIPTION

A class representing a volume attachment to an instance

=head1 ATTRIBUTES

=over

=item volume_id (required)

The ID of the volume.

=item status (required)

The attachment's status.

=item instance_id (required)

The ID of the instance which this volume was attached to.

=item attach_time (required)

The time the volume was attached.

=item device (required)

The device path on the instance that the volume was attached as.

=back

=cut

has 'volume_id'		=> ( is => 'ro', isa => 'Str', required => 1 );
has 'status'		=> ( is => 'ro', isa => 'Str', required => 1 );
has 'instance_id'	=> ( is => 'ro', isa => 'Str', required => 1 );
has 'attach_time'	=> ( is => 'ro', isa => 'Str', required => 1 );
has 'device'		=> ( is => 'ro', isa => 'Str', required => 1 );

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <jkim@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2008 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;