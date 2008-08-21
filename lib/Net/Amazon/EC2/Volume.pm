package Net::Amazon::EC2::Volume;
use Moose;

=head1 NAME

Net::Amazon::EC2::Volume

=head1 DESCRIPTION

A class representing a volume

=head1 ATTRIBUTES

=over

=item volume_id (required)

The ID of the volume.

=item status (required)

The volume's status.

=item zone (required)

The availability zone the volume was creared in.

=item attachments (optional)

An array ref of Net:Amazon::EC2::Attachment objects.

=item create_time (required)

The time the volume was created.

=item snapshot_id (optional)

The ID of the snapshot which this volume was created from (if any).

=item size (required)

The size, in GiB (1GiB = 2^30 octects)

=back

=cut

has 'volume_id'		=> ( is => 'ro', isa => 'Str', required => 1 );
has 'status'		=> ( is => 'ro', isa => 'Str', required => 1 );
has 'zone'			=> ( is => 'ro', isa => 'Str', required => 1 );
has 'attachments'	=> ( is => 'ro', isa => 'Maybe[ArrayRef[Net::Amazon::EC2::Attachment]]', required => 0 );
has 'create_time'	=> ( is => 'ro', isa => 'Str', required => 1 );
has 'snapshot_id'	=> ( is => 'ro', isa => 'Maybe[Str]', required => 0 );
has 'size'			=> ( is => 'ro', isa => 'Str', required => 1 );

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <jkim@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2008 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;