package Net::Amazon::EC2::ReservationInfo;
use Moose;

=head1 NAME

Net::Amazon::EC2::ReservationInfo

=head1 DESCRIPTION

A class representing a run instance reservation.

=head1 ATTRIBUTES

=over

=item reservation_id (required)

Unique ID attached to the reservation.

=item owner_id (required)

AWS Account id of the person making the reservation.

=item group_set (required)

An array ref of Net::Amazon::EC2::GroupSet objects.

=item instances_set (required)

An array ref of Net::Amazon::EC2::RunningInstances objects.

=cut

has 'reservation_id'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'owner_id'          => ( is => 'ro', isa => 'Str', required => 1 );
has 'group_set'         => ( 
    is          => 'ro', 
    isa         => 'ArrayRef[Net::Amazon::EC2::GroupSet]',
    required    => 1,
    auto_deref  => 1,
);
has 'instances_set'     => ( 
    is          => 'ro',
    isa         => 'ArrayRef[Net::Amazon::EC2::RunningInstances]',
    required    => 1,
    auto_deref  => 1,
);

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <jkim@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2009 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;