package Net::Amazon::EC2::DescribeImagesResponse;
use Moose;

=head1 NAME

Net::Amazon::EC2::DescribeImagesResponse

=head1 DESCRIPTION

A class representing a machine image.

=head1 ATTRIBUTES

=over

=item image_id (required)

The image_id you you are describing the image attributes of.

=item image_state (required)

Current state of the AMI. 
If the operation returns available, the image is successfully registered and available for launching 
If the operation returns deregistered, the image is deregistered and no longer available for launching.

=item image_owner_id (required)

AWS access key id of the owner of the image.

=item image_location (required)

Path to the AMI itself

=item is_public (required)

This is true if the AMI can be launched by anyone (has public launch permissions) or false if its only able
to be run by the owner of the AMI.

=item product_codes (optional)

An array ref of Net::Amazon::EC2::ProductCode objects (if any) associated with this AMI.

=item architecture (optional)

The AMI architecture (i386 or x86_64).

=item image_type (optional)

The type of AMI this is.  Valid values are:

=over

=item machine

=item kernel

=item ramdisk

=back

=item kernel_id (optional)

The kernel id associated with this AMI (if any). This is only defined for machine type AMIs.

=item ramdisk_id (optional)

The ramdisk id associated with this AMI (if any). This is only defined for machine type AMIs.

=back

=cut

has 'image_id'          => ( is => 'ro', isa => 'Str', required => 1 );
has 'image_state'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'image_owner_id'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'image_location'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'is_public'         => ( is => 'ro', isa => 'Str', required => 1 );
has 'product_codes'     => ( 
    is          => 'rw', 
    isa         => 'Maybe[ArrayRef[Net::Amazon::EC2::ProductCode]]', 
    predicate   => 'has_product_codes',
    required	=> 0,
);
has 'architecture'		=> ( is => 'ro', isa => 'Str', required => 0 );
has 'image_type'		=> ( is => 'ro', isa => 'Maybe[Str]', required => 0 );
has 'kernel_id'			=> ( is => 'ro', isa => 'Maybe[Str]', required => 0 );
has 'ramdisk_id'		=> ( is => 'ro', isa => 'Maybe[Str]', required => 0 );

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <jkim@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2008 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;