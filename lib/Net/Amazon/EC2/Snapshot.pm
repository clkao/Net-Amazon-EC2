package Net::Amazon::EC2::Snapshot;
use Moose;

=head1 NAME

Net::Amazon::EC2::Snapshot

=head1 DESCRIPTION

A class representing a snapshot of a volume.

=head1 ATTRIBUTES

=over

=item snapshot_id (required)

The ID of the snapshot.

=item status (required)

The snapshot's status.

=item volume_id (required)

The ID of the volume the snapshot was taken from.

=item start_time (required)

The time the snapshot was started.

=item progress (required)

The current progress of the snaptop, in percent.

=back

=cut

has 'snapshot_id'	=> ( is => 'ro', isa => 'Str', required => 1 );
has 'status'		=> ( is => 'ro', isa => 'Str', required => 1 );
has 'volume_id'		=> ( is => 'ro', isa => 'Str', required => 1 );
has 'start_time'	=> ( is => 'ro', isa => 'Str', required => 1 );
has 'progress'		=> ( is => 'ro', isa => 'Maybe[Str]', required => 0 );

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <jkim@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2008 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;