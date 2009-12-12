package Net::Amazon::EC2;
use Moose;

use strict;
use vars qw($VERSION);

use XML::Simple;
use LWP::UserAgent;
use Digest::HMAC_SHA1;
use URI;
use MIME::Base64 qw(encode_base64 decode_base64);
use HTTP::Date qw(time2isoz);
use Params::Validate qw(validate SCALAR ARRAYREF);
use Net::Amazon::EC2::DescribeImagesResponse;
use Net::Amazon::EC2::DescribeKeyPairsResponse;
use Net::Amazon::EC2::GroupSet;
use Net::Amazon::EC2::InstanceState;
use Net::Amazon::EC2::IpPermission;
use Net::Amazon::EC2::LaunchPermission;
use Net::Amazon::EC2::LaunchPermissionOperation;
use Net::Amazon::EC2::ProductCode;
use Net::Amazon::EC2::ProductInstanceResponse;
use Net::Amazon::EC2::ReservationInfo;
use Net::Amazon::EC2::RunInstance;
use Net::Amazon::EC2::RunningInstances;
use Net::Amazon::EC2::SecurityGroup;
use Net::Amazon::EC2::TerminateInstancesResponse;
use Net::Amazon::EC2::UserData;
use Net::Amazon::EC2::UserIdGroupPair;
use Net::Amazon::EC2::IpRange;
use Net::Amazon::EC2::KeyPair;
use Net::Amazon::EC2::DescribeImageAttribute;
use Net::Amazon::EC2::ConsoleOutput;
use Net::Amazon::EC2::Errors;
use Net::Amazon::EC2::Error;
use Net::Amazon::EC2::ConfirmProductInstanceResponse;

$VERSION = '0.06';

=head1 NAME

Net::Amazon::EC2 - Perl interface to the Amazon Elastic Compute Cloud (EC2)
environment.

=head1 VERSION

This document describes version 0.06 of Net::Amazon::EC2, released
February 15, 2008. This module is coded against the Query version of the '2007-08-29' version of the EC2 API.

=head1 SYNOPSIS

 use Net::Amazon::EC2;

 my $ec2 = Net::Amazon::EC2->new(
	AWSAccessKeyId => 'PUBLIC_KEY_HERE', 
	SecretAccessKey => 'SECRET_KEY_HERE'
 );

 # Start 1 new instance from AMI: ami-XXXXXXXX
 my $instance = $ec2->run_instances(ImageId => 'ami-XXXXXXXX', MinCount => 1, MaxCount => 1);

 my $running_instances = $ec2->describe_instances;

 foreach my $reservation (@$running_instances) {
    foreach my $instance ($reservation->instances_set) {
        print $instance->instance_id . "\n";
    }
 }

 my $instance_id = $instance->instances_set->[0]->instance_id;

 print "$instance_id\n";

 # Terminate instance

 my $result = $ec2->terminate_instances(InstanceId => $instance_id);

If an error occurs while communicating with EC2, the return value of these methods will be a Net::Amazon::EC2::Errors object.

=head1 DESCRIPTION

This module is a Perl interface to Amazon's Elastic Compute Cloud. It uses the Query API to communicate with Amazon's Web Services framework.

=head1 CLASS METHODS

=head2 new(%params)

This is the constructor, it will return you a Net::Amazon::EC2 object to work with.  It takes these parameters:

=over

=item AWSAccessKeyId (required)

Your AWS access key.

=item SecretAccessKey (required)

Your secret key, WARNING! don't give this out or someone will be able to use your account and incur charges on your behalf.

=item debug (optional)

A flag to turn on debugging. It is turned off by default

=item use_old_api (optional)

Setting this to 1 will cause the data coming back from the method calls to be returned as data structures instead of objects (set this to enable backwards compatibility
with code written against 0.01-0.04 of this module)

NOTE: THIS BACKWARDS COMPATIBILITY WILL END AFTER THIS VERSION

=back

=cut

has 'AWSAccessKeyId'	=> ( is => 'ro', isa => 'Str', required => 1 );
has 'SecretAccessKey'	=> ( is => 'ro', isa => 'Str', required => 1 );
has 'debug'				=> ( is => 'ro', isa => 'Str', required => 0, default => 0 );
has 'use_old_api'		=> ( is => 'ro', isa => 'Str', required => 0, default => 0 );
has 'signature_version'	=> ( is => 'ro', isa => 'Int', required => 1, default => 1 );
has 'version'			=> ( is => 'ro', isa => 'Str', required => 1, default => '2007-08-29' );
has 'base_url'			=> ( is => 'ro', isa => 'Str', required => 1, default => 'http://ec2.amazonaws.com' );
has 'timestamp'			=> ( is => 'ro', isa => 'Str', required => 1, default => sub { my $ts = time2isoz(); chop($ts); $ts .= '.000Z'; $ts =~ s/\s+/T/g; return $ts; } );

sub _sign {
	my $self						= shift;
	my %args						= @_;
	my $action						= delete $args{Action};
	my %sign_hash					= %args;
	$sign_hash{AWSAccessKeyId}		= $self->AWSAccessKeyId;
	$sign_hash{Action}				= $action;
	$sign_hash{Timestamp}			= $self->timestamp;
	$sign_hash{Version}				= $self->version;
	$sign_hash{SignatureVersion}	= $self->signature_version;
	my $sign_this;

	# The sign string must be alphabetical in a case-insensitive manner.
	foreach my $key (sort { lc($a) cmp lc($b) } keys %sign_hash) {
		$sign_this .= $key . $sign_hash{$key};
	}

	$self->_debug("QUERY TO SIGN: $sign_this");
	my $encoded = $self->_hashit($self->SecretAccessKey, $sign_this);

	my $uri = URI->new($self->base_url);
	my %params = (
		Action				=> $action,
		SignatureVersion	=> $self->signature_version,
		AWSAccessKeyId		=> $self->AWSAccessKeyId,
		Timestamp			=> $self->timestamp,
		Version				=> $self->version,
		Signature			=> $encoded,
		%args
	);
	
	$uri->query_form(\%params);
	
	my $ur	= $uri->as_string();
	$self->_debug("GENERATED QUERY URL: $ur");
	my $ua	= LWP::UserAgent->new();
	my $res	= $ua->get($ur);
	
	# We should force <item> elements to be in an array
	my $xs	= XML::Simple->new(ForceArray => qr/(?:item|Errors)/i);
	my $ref	= $xs->XMLin($res->content());

	return $ref;
}

sub _parse_errors {
	my $self		= shift;
	my $errors_xml	= shift;
	
	my $es;
	my $request_id = $errors_xml->{RequestID};
	foreach my $e (@{$errors_xml->{Errors}}) {
		my $error = Net::Amazon::EC2::Error->new(
			code	=> $e->{Error}{Code},
			message	=> $e->{Error}{Message},
		);
		
		push @$es, $error;
	}
	
	my $errors = Net::Amazon::EC2::Errors->new(
		request_id	=> $request_id,
		errors		=> $es,
	);

	foreach my $error ($errors->errors) {
		$self->_debug("ERROR CODE: " . $error->code . " MESSAGE: " . $error->message . " FOR REQUEST: " . $errors->request_id);
	}
	
	return $errors;	
}

sub _debug {
	my $self	= shift;
	my $message	= shift;
	
	if ((grep { defined && length} $self->debug) && $self->debug == 1) {
		print "$message\n";
	}
}

# HMAC sign the query with the aws secret access key and base64 encodes the result.
sub _hashit {
	my $self								= shift;
	my ($secret_access_key, $query_string)	= @_;
	my $hashed								= Digest::HMAC_SHA1->new($secret_access_key);
	$hashed->add($query_string);
	
	my $encoded = encode_base64($hashed->digest, '');

	return $encoded;
}

=head1 OBJECT METHODS

=head2 authorize_security_group_ingress(%params)

This method adds permissions to a security group.  It takes the following parameters:

=over

=item GroupName (required)

The name of the group to add security rules to.

=item SourceSecurityGroupName (requred when authorizing a user and group together)

Name of the group to add access for.

=item SourceSecurityGroupOwnerId (required when authorizing a user and group together)

Owner of the group to add access for.

=item IpProtocol (required when adding access for a CIDR)

IP Protocol of the rule you are adding access for (TCP, UDP, or ICMP)

=item FromPort (required when adding access for a CIDR)

Beginning of port range to add access for.

=item ToPort (required when adding access for a CIDR)

End of port range to add access for.

=item CidrIp (required when adding access for a CIDR)

The CIDR IP space we are adding access for.

=back

Adding a rule can be done in two ways: adding a source group name + source group owner id, or, by Protocol + start port + end port + CIDR IP.  The two are mutally exclusive.

Returns 1 if rule is added successfully.

=cut

sub authorize_security_group_ingress {
	my $self = shift;
	my %args = validate( @_, {
		GroupName					=> { type => SCALAR },
		SourceSecurityGroupName 	=> { 
			type => SCALAR,
			depends => ['SourceSecurityGroupOwnerId'],
			optional => 1 ,
		},
		SourceSecurityGroupOwnerId	=> { type => SCALAR, optional => 1 },
		IpProtocol 					=> { 
			type => SCALAR,
			depends => ['FromPort', 'ToPort', 'CidrIp'],
			optional => 1 
		},
		FromPort 					=> { type => SCALAR, optional => 1 },
		ToPort 						=> { type => SCALAR, optional => 1 },
		CidrIp						=> { type => SCALAR, optional => 1 },
	});
	
	
	my $xml = $self->_sign(Action  => 'AuthorizeSecurityGroupIngress', %args);
	
	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
}

=head2 confirm_product_instance(%params)

Checks to see if the product code passed in is attached to the instance id, taking the following parameter:

=over

=item ProductCode (required)

The Product Code to check

=item InstanceId (required)

The Instance Id to check

=back

Returns a Net::Amazon::EC2::ConfirmProductInstanceResponse object

=cut

sub confirm_product_instance {
	my $self = shift;
	my %args = validate( @_, {
		ProductCode	=> { type => SCALAR },
		InstanceId	=> { type => SCALAR },
	});

	my $xml = $self->_sign(Action  => 'ConfirmProductInstance', %args);
	
	if ( grep { defined && length } $xml->{Errors} ) {
		return $self->_parse_errors($xml);
	}
	else {
		my $confirm_response = Net::Amazon::EC2::ConfirmProductInstanceResponse->new(
			result			=> $xml->{result},
			owner_id		=> $xml->{ownerId},
		);
		
		return $confirm_response;
	}
}

=head2 create_key_pair(%params)

Creates a new 2048 bit key pair, taking the following parameter:

=over

=item KeyName (required)

A name for this key. Should be unique.

=back

Returns a Net::Amazon::EC2::KeyPair object

=cut

sub create_key_pair {
	my $self = shift;
	my %args = validate( @_, {
		KeyName => { type => SCALAR },
	});
		
	my $xml = $self->_sign(Action  => 'CreateKeyPair', %args);

	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
			
			return undef;
		}
		else {
			return $xml;
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			my $key_pair = Net::Amazon::EC2::KeyPair->new(
				key_name		=> $xml->{keyName},
				key_fingerprint	=> $xml->{keyFingerprint},
				key_material	=> $xml->{keyMaterial},
			);
			
			return $key_pair;
		}
	}	
}

=head2 create_security_group(%params)

This method creates a new security group.  It takes the following parameters:

=over

=item GroupName (required)

The name of the new group to create.

=item GroupDescription (required)

A short description of the new group.

=back

Returns 1 if the group creation succeeds.

=cut

sub create_security_group {
	my $self = shift;
	my %args = validate( @_, {
		GroupName				=> { type => SCALAR },
		GroupDescription 		=> { type => SCALAR },
	});
	
	
	my $xml = $self->_sign(Action  => 'CreateSecurityGroup', %args);

	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}	
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}	
	}
}

=head2 delete_key_pair(%params)

This method deletes a keypair.  Takes the following parameter:

=over

=item KeyName (required)

The name of the key to delete.

=back

Returns 1 if the key was successfully deleted.

=cut

sub delete_key_pair {
	my $self = shift;
	my %args = validate( @_, {
		KeyName => { type => SCALAR },
	});
		
	my $xml = $self->_sign(Action  => 'DeleteKeyPair', %args);

	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}	
	}
}

=head2 delete_security_group(%params)

This method deletes a security group.  It takes the following parameter:

=over

=item GroupName (required)

The name of the security group to delete.

=back

Returns 1 if the delete succeeded.

=cut

sub delete_security_group {
	my $self = shift;
	my %args = validate( @_, {
		GroupName => { type => SCALAR },
	});
	
	
	my $xml = $self->_sign(Action  => 'DeleteSecurityGroup', %args);
	
	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
}

=head2 deregister_image(%params)

This method will deregister an AMI. It takes the following parameter:

=over

=item ImageId (required)

The image id of the AMI you want to deregister.

=back

Returns 1 if the deregistering succeeded

=cut

sub deregister_image {
	my $self = shift;
	my %args = validate( @_, {
		ImageId	=> { type => SCALAR },
	});
	

	my $xml = $self->_sign(Action  => 'DeregisterImage', %args);

	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
}

=head2 describe_image_attributes(%params)

This method pulls a list of attributes for the image id specified

=over

=item ImageId (required)

A scalar containing the image you want to get the list of attributes for.

=item Attribute (required)

A scalar containing the attribute to describe.  Currently the only possible value for this is 'launchPermission'.

=back

Returns a Net::Amazon::EC2::DescribeImageAttribute object

=cut

sub describe_image_attribute {
	my $self = shift;
	my %args = validate( @_, {
								ImageId => { type => SCALAR },
								Attribute => { type => SCALAR }
	});
		
	my $xml = $self->_sign(Action  => 'DescribeImageAttribute', %args);
	
	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			# Lets create our custom data struct here
			my $struct = { ImageId => $xml->{ImageId}, launchPermission => $xml->{launchPermission} };
			return $struct;
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			my $launch_permissions;
			my $product_codes;
			
			if ( grep { defined && length } $xml->{launchPermission}{item} ) {
				foreach my $lp (@{$xml->{launchPermission}{item}}) {
					my $launch_permission = Net::Amazon::EC2::LaunchPermission->new(
						group	=> $lp->{group},
						user_id	=> $lp->{userId},
					);
					
					push @$launch_permissions, $launch_permission;
				}
			}
	
			if ( grep { defined && length } $xml->{productCodes}{item} ) {
				foreach my $pc (@{$xml->{productCodes}{item}}) {
					my $product_code = Net::Amazon::EC2::ProductCode->new(
						product_code	=> $pc->{productCode},
					);
					
					push @$product_codes, $product_code;
				}
			}
			
			my $describe_image_attribute = Net::Amazon::EC2::DescribeImageAttribute->new(
				image_id			=> $xml->{imageId},
				launch_permissions	=> $launch_permissions,
				product_codes		=> $product_codes,
			);
	
			return $describe_image_attribute;
		}
	}
}

=head2 describe_images(%params)

This method pulls a list of the AMIs which can be run.  The list can be modified by passing in some of the following parameters:

=over 

=item ImageId (optional)

Either a scalar or an array ref can be passed in, will cause just these AMIs to be 'described'

=item Owner (optional)

Either a scalar or an array ref can be passed in, will cause AMIs owned by the Owner's provided will be 'described'. Pass either account ids, or 'amazon' for all amazon-owned AMIs, or 'self' for your own AMIs.

=item ExecutableBy (optional)

Either a scalar or an array ref can be passed in, will cause AMIs executable by the account id's specified.  Or 'self' for your own AMIs.

=back

Returns an array ref of Net::Amazon::EC2::DescribeImagesResponse objects

=cut

sub describe_images {
	my $self = shift;
	my %args = validate( @_, {
		ImageId			=> { type => SCALAR | ARRAYREF, optional => 1 },
		Owner			=> { type => SCALAR | ARRAYREF, optional => 1 },
		ExecutableBy	=> { type => SCALAR | ARRAYREF, optional => 1 },
	});
	
	# If we have a array ref of instances lets split them out into their ImageId.n format
	if (ref ($args{ImageId}) eq 'ARRAY') {
		my $image_ids	= delete $args{ImageId};
		my $count		= 1;
		foreach my $image_id (@{$image_ids}) {
			$args{"ImageId." . $count} = $image_id;
			$count++;
		}
	}
	
	# If we have a array ref of instances lets split them out into their Owner.n format
	if (ref ($args{Owner}) eq 'ARRAY') {
		my $owners	= delete $args{Owner};
		my $count	= 1;
		foreach my $owner (@{$owners}) {
			$args{"Owner." . $count} = $owner;
			$count++;
		}
	}

	# If we have a array ref of instances lets split them out into their ExecutableBy.n format
	if (ref ($args{ExecutableBy}) eq 'ARRAY') {
		my $executors	= delete $args{ExecutableBy};
		my $count		= 1;
		foreach my $executor (@{$executors}) {
			$args{"ExecutableBy." . $count} = $executor;
			$count++;
		}
	}

	my $xml = $self->_sign(Action  => 'DescribeImages', %args);
	
	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
			
			return undef;
		}
		else {
			return $xml->{imagesSet}{item};
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			my $images;
			
			foreach my $item (@{$xml->{imagesSet}{item}}) {
				my $product_codes;
				my $image = Net::Amazon::EC2::DescribeImagesResponse->new(
					image_id		=> $item->{imageId},
					image_owner_id	=> $item->{imageOwnerId},
					image_state		=> $item->{imageState},
					is_public		=> $item->{isPublic},
					image_location	=> $item->{imageLocation},
				);
				
				if (grep { defined && length } $item->{productCodes} ) {
					foreach my $pc (@{$item->{productCodes}{item}}) {
						my $product_code = Net::Amazon::EC2::ProductCode->new( product_code => $pc->{productCode} );
						push @$product_codes, $product_code;
					}
					
					$image->product_codes($product_codes);
				}
				
				push @$images, $image;
			}
					
			return $images;
		}
	}
}

=head2 describe_instances(%params)

This method pulls a list of the instances which are running or were just running.  The list can be modified by passing in some of the following parameters:

=over

=item InstanceId (optional)

Either a scalar or an array ref can be passed in, will cause just these instances to be 'described'

=back

Returns an array ref of Net::Amazon::EC2::ReservationInfo objects

=cut

sub describe_instances {
	my $self = shift;
	my %args = validate( @_, {
		InstanceId => { type => SCALAR | ARRAYREF, optional => 1 },
	});
	
	# If we have a array ref of instances lets split them out into their InstanceId.n format
	if (ref ($args{InstanceId}) eq 'ARRAY') {
		my $instance_ids	= delete $args{InstanceId};
		my $count			= 1;
		foreach my $instance_id (@{$instance_ids}) {
			$args{"InstanceId." . $count} = $instance_id;
			$count++;
		}
	}
	
	my $xml = $self->_sign(Action  => 'DescribeInstances', %args);

	my $reservations;
	
	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			# Lets create our custom data struct here
			my $structs;
			
			foreach my $instance (@{$xml->{reservationSet}{item}}) {
				my $struct;
				$struct->{reservationId} = $instance->{reservationId};
				$struct->{ownerId} = $instance->{ownerId};
				$struct->{instance} = $instance->{instancesSet}{item};
				
				foreach my $group_arr (@{$instance->{groupSet}{item}}) {
						push @{$struct->{groups}}, $group_arr->{groupId};
				}
	
				push @{$structs}, $struct;
			}
			
			return $structs;
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			foreach my $reservation_set (@{$xml->{reservationSet}{item}}) {
				my $group_sets;
				foreach my $group_arr (@{$reservation_set->{groupSet}{item}}) {
					my $group = Net::Amazon::EC2::GroupSet->new(
						group_id => $group_arr->{groupId},
					);
					push @$group_sets, $group;
				}
		
				my $running_instances;
				foreach my $instance_elem (@{$reservation_set->{instancesSet}{item}}) {
					my $instance_state_type = Net::Amazon::EC2::InstanceState->new(
						code	=> $instance_elem->{instanceState}{code},
						name	=> $instance_elem->{instanceState}{name},
					);
					
					my $product_codes;
					
					if (grep { defined && length } $instance_elem->{productCodes} ) {
						foreach my $pc (@{$instance_elem->{productCodes}{item}}) {
							my $product_code = Net::Amazon::EC2::ProductCode->new( product_code => $pc->{productCode} );
							push @$product_codes, $product_code;
						}
					}
		
					unless ( grep { defined && length } $instance_elem->{reason} and ref $instance_elem->{reason} ne 'HASH' ) {
						$instance_elem->{reason} = undef;
					}
							
					unless ( grep { defined && length } $instance_elem->{privateDnsName} and ref $instance_elem->{privateDnsName} ne 'HASH' ) {
						$instance_elem->{privateDnsName} = undef;
					}
										
					unless ( grep { defined && length } $instance_elem->{dnsName} and ref $instance_elem->{dnsName} ne 'HASH' ) {
						$instance_elem->{dnsName} = undef;
					}
					
					my $running_instance = Net::Amazon::EC2::RunningInstances->new(
						instance_id			=> $instance_elem->{instanceId},
						image_id			=> $instance_elem->{imageId},
						instance_state		=> $instance_state_type,
						private_dns_name	=> $instance_elem->{privateDnsName},
						dns_name			=> $instance_elem->{dnsName},
						reason				=> $instance_elem->{reason},
						key_name			=> $instance_elem->{keyName},
						ami_launch_index	=> $instance_elem->{amiLaunchIndex},
						instance_type		=> $instance_elem->{instanceType},
						launch_time			=> $instance_elem->{launchTime},
					);
	
					if ($product_codes) {
						$running_instance->product_codes($product_codes);
					}
					
					push @$running_instances, $running_instance;
				}
							
				my $reservation = Net::Amazon::EC2::ReservationInfo->new(
					reservation_id	=> $reservation_set->{reservationId},
					owner_id		=> $reservation_set->{ownerId},
					group_set		=> $group_sets,
					instances_set	=> $running_instances,
				);
				
				push @$reservations, $reservation;
			}
				
		}
	}
	
	return $reservations;
}

=head2 describe_key_pairs(%params)

This method describes the keypairs available on this account. It takes the following parameter:

=over

=item KeyName (optional)

The name of the key to be described. Can be either a scalar or an array ref.

=back

Returns an array ref of Net::Amazon::EC2::DescribeKeyPairsResponse objects

=cut

sub describe_key_pairs {
	my $self = shift;
	my %args = validate( @_, {
		KeyName => { type => SCALAR | ARRAYREF, optional => 1 },
	});
	
	# If we have a array ref of instances lets split them out into their InstanceId.n format
	if (ref ($args{KeyName}) eq 'ARRAY') {
		my $keynames	= delete $args{KeyName};
		my $count		= 1;
		foreach my $keyname (@{$keynames}) {
			$args{"KeyName." . $count} = $keyname;
			$count++;
		}
	}
	
	my $xml = $self->_sign(Action  => 'DescribeKeyPairs', %args);

	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {	
			my $structs;
			
			$structs = $xml->{keySet}{item};
	
			return $structs;
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {	
			my $key_pairs;
	
			foreach my $pair (@{$xml->{keySet}{item}}) {
				my $key_pair = Net::Amazon::EC2::DescribeKeyPairsResponse->new(
					key_name		=> $pair->{keyName},
					key_fingerprint	=> $pair->{keyFingerprint},
				);
				
				push @$key_pairs, $key_pair;
			}
	
			return $key_pairs;
		}
	}
}

=head2 describe_security_groups(%params)

This method describes the security groups available to this account. It takes the following parameter:

=over

=item GroupName (optional)

The name of the security group(s) to be described. Can be either a scalar or an array ref.

=back

Returns an array ref of Net::Amazon::EC2::SecurityGroup objects

=cut

sub describe_security_groups {
	my $self = shift;
	my %args = validate( @_, {
		GroupName => { type => SCALAR | ARRAYREF, optional => 1 },
	});
	
	# If we have a array ref of instances lets split them out into their InstanceId.n format
	if (ref ($args{GroupName}) eq 'ARRAY') {
		my $groups = delete $args{GroupName};
		my $count = 1;
		foreach my $group (@{$groups}) {
			$args{"GroupName." . $count} = $group;
			$count++;
		}
	}
	
	my $xml = $self->_sign(Action  => 'DescribeSecurityGroups', %args);
	
	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			return $xml->{securityGroupInfo}{item};
		}	
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			my $security_groups;
			foreach my $sec_grp (@{$xml->{securityGroupInfo}{item}}) {
				my $owner_id = $sec_grp->{ownerId};
				my $group_name = $sec_grp->{groupName};
				my $group_description = $sec_grp->{groupDescription};
				my $ip_permissions;
				foreach my $ip_perm (@{$sec_grp->{ipPermissions}{item}}) {
					my $ip_protocol = $ip_perm->{ipProtocol};
					my $from_port	= $ip_perm->{fromPort};
					my $to_port		= $ip_perm->{toPort};
					my $groups;
					my $ip_ranges;
					
					if (grep { defined && length } $ip_perm->{groups}{item}) {
						foreach my $grp (@{$ip_perm->{groups}{item}}) {
							my $group = Net::Amazon::EC2::UserIdGroupPair->new(
								user_id		=> $grp->{userId},
								group_name	=> $grp->{groupName},
							);
							
							push @$groups, $group;
						}
					}
					
					if (grep { defined && length } $ip_perm->{ipRanges}{item}) {
						foreach my $rng (@{$ip_perm->{ipRanges}{item}}) {
							my $ip_range = Net::Amazon::EC2::IpRange->new(
								cidr_ip => $rng->{cidrIp},
							);
							
							push @$ip_ranges, $ip_range;
						}
					}
									
					my $ip_permission = Net::Amazon::EC2::IpPermission->new(
						ip_protocol			=> $ip_protocol,
						group_name			=> $group_name,
						group_description	=> $group_description,
						from_port			=> $from_port,
						to_port				=> $to_port,
					);
					
					if ($ip_ranges) {
						$ip_permission->ip_ranges($ip_ranges);
					}
	
					if ($groups) {
						$ip_permission->groups($groups);
					}
					
					push @$ip_permissions, $ip_permission;
				}
				
				my $security_group = Net::Amazon::EC2::SecurityGroup->new(
					owner_id			=> $owner_id,
					group_name			=> $group_name,
					group_description	=> $group_description,
					ip_permissions		=> $ip_permissions,
				);
				
				push @$security_groups, $security_group;
			}
			
			return $security_groups;	
		}
	}
}

=head2 get_console_output(%params)

This method gets the output from the virtual console for an instance.  It takes the following parameters:

=over

=item InstanceId (required)

A scalar containing a instance id.

=back

Returns a Net::Amazon::EC2::ConsoleOutput object.

=cut

sub get_console_output {
	my $self = shift;
	my %args = validate( @_, {
		InstanceId	=> { type => SCALAR },
	});
	
	
	my $xml = $self->_sign(Action  => 'GetConsoleOutput', %args);
	
	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			return decode_base64($xml->{output});
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			my $console_output = Net::Amazon::EC2::ConsoleOutput->new(
				instance_id	=> $xml->{instanceId},
				timestamp	=> $xml->{timestamp},
				output		=> decode_base64($xml->{output}),
			);
			
			return $console_output;
		}
	}
}

=head2 modify_image_attribute(%params)

This method modifies attributes of an AMI on EC2.  Right now the only attribute that can be modified is to grant launch permissions.  It takes the following parameters:

=over

=item ImageId (required)

The AMI to modify the attributes of.

=item Attribute (required)

The attribute you wish to modify, right now the attributes you can modify are launchPermission and productCodes

=item OperationType (required for launchPermission)

The operation you wish to perform on the attribute. Right now just 'add' and 'remove' are supported.

=item UserId (required for launchPermission)

User Id's you wish to add/remove from the attribute.

=item UserGroup (required for launchPermission)

Groups you wish to add/remove from the attribute.  Currently there is only one User Group available 'all' for all Amazon EC2 customers.

=item ProductCode (required for productCodes)

Attaches a product code to the AMI. Currently only one product code can be assigned to the AMI.  Once this is set it cannot be changed or reset.

=back

Returns 1 if the modification succeeds.

=cut

sub modify_image_attribute {
	my $self = shift;
	my %args = validate( @_, {
		ImageId			=> { type => SCALAR },
		Attribute 		=> { type => SCALAR },
		OperationType	=> { type => SCALAR, optional => 1 },
		UserId 			=> { type => SCALAR | ARRAYREF, optional => 1 },
		UserGroup 		=> { type => SCALAR | ARRAYREF, optional => 1 },
		ProductCode		=> { type => SCALAR, optional => 1 },
	});
	
	
	my $xml = $self->_sign(Action  => 'ModifyImageAttribute', %args);
	
	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
}

=head2 reboot_instances(%params)

This method reboots an instance.  It takes the following parameters:

=over

=item InstanceId (required)

Instance Id of the instance you wish to reboot. Can be either a scalar or array ref of instances to reboot.

=back

Returns 1 if the reboot succeeded.

=cut

sub reboot_instances {
	my $self = shift;
	my %args = validate( @_, {
		InstanceId	=> { type => SCALAR },
	});
	
	# If we have a array ref of instances lets split them out into their InstanceId.n format
	if (ref ($args{InstanceId}) eq 'ARRAY') {
		my $instance_ids = delete $args{InstanceId};
		my $count = 1;
		foreach my $instance_id (@{$instance_ids}) {
			$args{"InstanceId." . $count} = $instance_id;
			$count++;
		}
	}
	
	my $xml = $self->_sign(Action  => 'RebootInstances', %args);
	
	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
}

=head2 register_image(%params)

This method registers an AMI on the EC2. It takes the following parameter:

=over

=item ImageLocation (required)

The location of the AMI manifest on S3

=back

Returns the image id of the new image on EC2.

=cut

sub register_image {
	my $self = shift;
	my %args = validate( @_, {
		ImageLocation => { type => SCALAR },
	});
		
	my $xml	= $self->_sign(Action  => 'RegisterImage', %args);

	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			return $xml->{imageId};
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			return $xml->{imageId};
		}
	}
}

=head2 reset_image_attribute(%params)

This method resets an attribute for an AMI to its default state (NOTE: product codes cannot be reset).  
It takes the following parameters:

=over

=item ImageId (required)

The image id of the AMI you wish to reset the attributes on.

=item Attribute (required)

The attribute you want to reset.  Right now the only attribute which can be modified is launchPermission.

=back

Returns 1 if the attribute reset succeeds.

=cut

sub reset_image_attribute {
	my $self = shift;
	my %args = validate( @_, {
		ImageId			=> { type => SCALAR },
		Attribute 		=> { type => SCALAR },
	});
	
	my $xml = $self->_sign(Action  => 'ResetImageAttribute', %args);

	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
}

=head2 revoke_security_group_ingress(%params)

This method revoke permissions to a security group.  It takes the following parameters:

=over

=item GroupName (required)

The name of the group to revoke security rules from.

=item SourceSecurityGroupName (requred when revoking a user and group together)

Name of the group to revoke access from.

=item SourceSecurityGroupOwnerId (required when revoking a user and group together)

Owner of the group to revoke access from.

=item IpProtocol (required when revoking access from a CIDR)

IP Protocol of the rule you are revoking access from (TCP, UDP, or ICMP)

=item FromPort (required when revoking access from a CIDR)

Beginning of port range to revoke access from.

=item ToPort (required when revoking access from a CIDR)

End of port range to revoke access from.

=item CidrIp (required when revoking access from a CIDR)

The CIDR IP space we are revoking access from.

=back

Revoking a rule can be done in two ways: revoking a source group name + source group owner id, or, by Protocol + start port + end port + CIDR IP.  The two are mutally exclusive.

Returns 1 if rule is revoked successfully.

=cut

sub revoke_security_group_ingress {
	my $self = shift;
	my %args = validate( @_, {
								GroupName					=> { type => SCALAR },
								SourceSecurityGroupName 	=> { 
																	type => SCALAR,
																	depends => ['SourceSecurityGroupOwnerId'],
																	optional => 1 ,
								},
								SourceSecurityGroupOwnerId	=> { type => SCALAR, optional => 1 },
								IpProtocol 					=> { 
																	type => SCALAR,
																	depends => ['FromPort', 'ToPort', 'CidrIp'],
																	optional => 1 
								},
								FromPort 					=> { type => SCALAR, optional => 1 },
								ToPort 						=> { type => SCALAR, optional => 1 },
								CidrIp						=> { type => SCALAR, optional => 1 },
	});
	
	
	my $xml = $self->_sign(Action  => 'RevokeSecurityGroupIngress', %args);

	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			if ($xml->{return} eq 'true') {
				return 1;
			}
			else {
				return undef;
			}
		}
	}
}

=head2 run_instances(%params)

This method will start instance(s) of AMIs on EC2. The parameters indicate which AMI to instantiate and how many / what properties they have:

=over

=item ImageId (required)

The image id you want to start an instance of.

=item MinCount (required)

The minimum number of instances to start.

=item MaxCount (required)

The maximum number of instances to start.

=item KeyName (optional)

The keypair name to associate this instance with.  If omitted, will use your default keypair.

=item SecurityGroup (optional)

An scalar or array ref. Will associate this instance with the group names passed in.  If omitted, will be associated with the default security group.

=item UserData (optional)

Optional data to pass into the instance being started.  Needs to be base64 encoded.

=item AddressingType (optional)

Optional addressing scheme to launch the instance.  If passed in it should have a value of either "direct" or "public".

=item instanceType (optional)

Specifies the type of instance to start.  The options are:

=over

=item m1.small (default)

1 EC2 Compute Unit (1 virtual core with 1 EC2 Compute Unit). 32-bit, 1.7GB RAM, 160GB disk

=item m1.large

4 EC2 Compute Units (2 virtual core with 2 EC2 Compute Units each). 64-bit, 7.5GB RAM, 850GB disk

=item m1.xlarge

8 EC2 Compute Units (4 virtual core with 2 EC2 Compute Units each). 64-bit, 15GB RAM, 1690GB disk

=back 

=back

Returns a Net::Amazon::EC2::ReservationInfo object

=cut 

sub run_instances {
	my $self = shift;
	my %args = validate( @_, {
		ImageId			=> { type => SCALAR },
		MinCount		=> { type => SCALAR },
		MaxCount		=> { type => SCALAR },
		KeyName			=> { type => SCALAR, optional => 1 },
		SecurityGroup	=> { type => SCALAR | ARRAYREF, optional => 1 },
		UserData		=> { type => SCALAR, optional => 1 },
		AddressingType	=> { type => SCALAR, optional => 1 },
		InstanceType	=> { type => SCALAR, optional => 1 },
	});
	
	# If we have a array ref of instances lets split them out into their SecurityGroup.n format
	if (ref ($args{SecurityGroup}) eq 'ARRAY') {
		my $security_groups	= delete $args{SecurityGroup};
		my $count			= 1;
		foreach my $security_group (@{$security_groups}) {
			$args{"SecurityGroup." . $count} = $security_group;
			$count++;
		}
	}

	my $xml = $self->_sign(Action  => 'RunInstances', %args);
	
	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			# Lets create our custom data struct here
			my $struct;
			
			$struct->{reservationId} = $xml->{reservationId};
			$struct->{ownerId} = $xml->{ownerId};
			$struct->{instance} = $xml->{instancesSet}{item};
			foreach my $group_arr (@{$xml->{groupSet}{item}}) {
				push @{$struct->{groups}}, $group_arr->{groupId};
			}
			
			return $struct;
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			my $group_sets;
			foreach my $group_arr (@{$xml->{groupSet}{item}}) {
				my $group = Net::Amazon::EC2::GroupSet->new(
					group_id => $group_arr->{groupId},
				);
				push @$group_sets, $group;
			}
	
			my $running_instances;
			foreach my $instance_elem (@{$xml->{instancesSet}{item}}) {
				my $instance_state_type = Net::Amazon::EC2::InstanceState->new(
					code	=> $instance_elem->{instanceState}{code},
					name	=> $instance_elem->{instanceState}{name},
				);
				
				my $product_codes;
				
				if (grep { defined && length } $instance_elem->{productCodes} ) {
					foreach my $pc (@{$instance_elem->{productCodes}{item}}) {
						my $product_code = Net::Amazon::EC2::ProductCode->new( product_code => $pc->{productCode} );
						push @$product_codes, $product_code;
					}
				}
	
				unless ( grep { defined && length } $instance_elem->{reason} and ref $instance_elem->{reason} ne 'HASH' ) {
					$instance_elem->{reason} = undef;
				}
	
				unless ( grep { defined && length } $instance_elem->{privateDnsName} and ref $instance_elem->{privateDnsName} ne 'HASH') {
					$instance_elem->{privateDnsName} = undef;
				}
	
				unless ( grep { defined && length } $instance_elem->{dnsName} and ref $instance_elem->{dnsName} ne 'HASH') {
					$instance_elem->{dnsName} = undef;
				}
				
				my $running_instance = Net::Amazon::EC2::RunningInstances->new(
					instance_id			=> $instance_elem->{instanceId},
					image_id			=> $instance_elem->{imageId},
					instance_state		=> $instance_state_type,
					private_dns_name	=> $instance_elem->{privateDnsName},
					dns_name			=> $instance_elem->{dnsName},
					reason				=> $instance_elem->{reason},
					key_name			=> $instance_elem->{keyName},
					ami_launch_index	=> $instance_elem->{amiLaunchIndex},
					instance_type		=> $instance_elem->{instanceType},
					launch_time			=> $instance_elem->{launchTime},
				);
	
				if ($product_codes) {
					$running_instance->product_codes($product_codes);
				}
				
				push @$running_instances, $running_instance;
			}
			
			my $reservation = Net::Amazon::EC2::ReservationInfo->new(
				reservation_id	=> $xml->{reservationId},
				owner_id		=> $xml->{ownerId},
				group_set		=> $group_sets,
				instances_set	=> $running_instances,
			);
			
			return $reservation;
		}
	}
}


=head2 terminate_instances(%params)

This method shuts down instance(s) passed into it. It takes the following parameter:

=over

=item InstanceId (required)

Either a scalar or an array ref can be passed in (containing instance ids)

=back

Returns an array ref of Net::Amazon::EC2::TerminateInstancesResponse objects.

=cut

sub terminate_instances {
	my $self = shift;
	my %args = validate( @_, {
		InstanceId => { type => SCALAR | ARRAYREF, optional => 1 },
	});
	
	# If we have a array ref of instances lets split them out into their InstanceId.n format
	if (ref ($args{InstanceId}) eq 'ARRAY') {
		my $instance_ids	= delete $args{InstanceId};
		my $count			= 1;
		foreach my $instance_id (@{$instance_ids}) {
			$args{"InstanceId." . $count} = $instance_id;
			$count++;
		}
	}
	
	my $xml = $self->_sign(Action  => 'TerminateInstances', %args);	

	if ($self->use_old_api) {
		if ( grep { defined && length } $xml->{Errors} ) {
			$self->_debug("ERROR: $xml->{Errors}{Error}{Message}");
			$self->{error} = $xml->{Errors}{Error}{Message};
	
			return undef;
		}
		else {
			my $structs;
			
			$structs = $xml->{instancesSet}{item};
	
			return $structs;
		}
	}
	else {
		if ( grep { defined && length } $xml->{Errors} ) {
			return $self->_parse_errors($xml);
		}
		else {
			my $terminated_instances;
			
			foreach my $inst (@{$xml->{instancesSet}{item}}) {
				my $terminated_instance = Net::Amazon::EC2::TerminateInstancesResponse->new(
					instance_id	=> $inst->{instanceId},
				);
				
				push @$terminated_instances, $terminated_instance;
			}
			
			return $terminated_instances;
		}
	}
}

no Moose;
1;

__END__

=head1 TODO

=over

=item * Add more documentation of the return type modules.

=back

=head1 UPCOMING BACKWARDS INCOMPATIBILITY NOTICE

I've implemented the returned data structures as objects as opposed to data structures.  In this release I am supporting both the deprecated and the new object-based returned data.  In the next release (0.07) the data structures _WILL NO LONGER BE SUPPORTED_

=head1 TESTING

Set AWS_ACCESS_KEY_ID and SECRET_ACCESS_KEY environment variables to run the live tests.  Note: because the live tests start an instance (and kill it) in both the tests and backwards compat tests there will be 2 hours of machine instance usage charges (since there are 2 instances started) which as of Feb 15th, 2008 costs a total of $0.20 USD

=head1 AUTHOR

Jeff Kim <jkim@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2008 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Amazon EC2 API: L<http://docs.amazonwebservices.com/AWSEC2/2007-08-29/DeveloperGuide/>