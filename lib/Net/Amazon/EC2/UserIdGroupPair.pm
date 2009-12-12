package Net::Amazon::EC2::UserIdGroupPair;
use Moose;

=head1 NAME

Net::Amazon::EC2::UserIdGroupPair

=head1 DESCRIPTION

A class representing the User ID and Group pair used with security group operations.

=head1 ATTRIBUTES

=over

=item user_id (required)

AWS Access Key ID of the user.

=item group_name (required)

Name of the security group.

=cut

has 'user_id'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'group_name'    => ( is => 'ro', isa => 'Str', required => 1 );

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <jkim@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2009 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;