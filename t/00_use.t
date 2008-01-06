use strict;
use blib;
use Test::More;

BEGIN { 
	my @modules = qw(
		Net::Amazon::EC2::ConfirmProductInstanceResponse
		Net::Amazon::EC2::ConsoleOutput
		Net::Amazon::EC2::DescribeImageAttribute
		Net::Amazon::EC2::DescribeImagesResponse
		Net::Amazon::EC2::DescribeKeyPairsResponse
		Net::Amazon::EC2::Errors
		Net::Amazon::EC2::Error
		Net::Amazon::EC2::GroupSet
		Net::Amazon::EC2::InstanceState
		Net::Amazon::EC2::IpPermission
		Net::Amazon::EC2::IpRange
		Net::Amazon::EC2::KeyPair
		Net::Amazon::EC2::LaunchPermission
		Net::Amazon::EC2::LaunchPermissionOperation
		Net::Amazon::EC2::ProductCode
		Net::Amazon::EC2::ProductInstanceResponse
		Net::Amazon::EC2::ReservationInfo
		Net::Amazon::EC2::RunInstance
		Net::Amazon::EC2::RunningInstances
		Net::Amazon::EC2::SecurityGroup
		Net::Amazon::EC2::TerminateInstancesResponse
		Net::Amazon::EC2::UserData
		Net::Amazon::EC2::UserIdGroupPair
	);

	plan tests => scalar @modules;
	use_ok($_) for @modules;
}