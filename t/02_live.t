use strict;
use blib;
use Test::More;

BEGIN { 
    if (! $ENV{AWS_ACCESS_KEY_ID} || ! $ENV{SECRET_ACCESS_KEY} ) {
        plan skip_all => "Set AWS_ACCESS_KEY_ID and SECRET_ACCESS_KEY environment variables to run these _LIVE_ tests (NOTE: they will incur one instance hour of costs from EC2)";
    }
    else {
        plan tests => 16;
        use_ok( 'Net::Amazon::EC2' );
    }
};

my $ec2 = Net::Amazon::EC2->new(
	AWSAccessKeyId  => $ENV{AWS_ACCESS_KEY_ID}, 
	SecretAccessKey => $ENV{SECRET_ACCESS_KEY},
	use_old_api     => 0,
	debug           => 0,
);

isa_ok($ec2, 'Net::Amazon::EC2');

my $delete_key_result   = $ec2->delete_key_pair(KeyName => "test_keys");
my $delete_group_result = $ec2->delete_security_group(GroupName => "test_group");

# create_key_pair
my $key_pair = $ec2->create_key_pair(KeyName => "test_keys");
isa_ok($key_pair, 'Net::Amazon::EC2::KeyPair');
is($key_pair->key_name, "test_keys", "Does new key pair come back?");

# describe_key_pairs
my $key_pairs       = $ec2->describe_key_pairs;
my $seen_test_key   = 0;
foreach my $key_pair (@{$key_pairs}) {
    if ($key_pair->key_name eq "test_keys") {
        $seen_test_key = 1;
    }
}
ok($seen_test_key == 1, "Checking for created key pair in describe keys");

# For cleanup purposes
$ec2->delete_security_group(GroupName => "test_group");

# create_security_group
my $create_result = $ec2->create_security_group(GroupName => "test_group", GroupDescription => "test description");    
ok($create_result == 1, "Checking for created security group");

# authorize_security_group_ingress
my $authorize_result = $ec2->authorize_security_group_ingress(GroupName => "test_group", IpProtocol => 'tcp', FromPort => '7003', ToPort => '7003', CidrIp => '10.253.253.253/32');
ok($authorize_result == 1, "Checking for authorization of rule for security group");

# describe_security_groups
my $security_groups = $ec2->describe_security_groups();
my $seen_test_group = 0;
my $seen_test_rule  = 0;
foreach my $security_group (@{$security_groups}) {
    if ($security_group->group_name eq "test_group") {
        $seen_test_group = 1;
        if ($security_group->ip_permissions->[0]->ip_ranges->[0]->cidr_ip eq '10.253.253.253/32') {
            $seen_test_rule = 1;
        }
    }
}
ok($seen_test_group == 1, "Checking for created security group in describe results");
ok($seen_test_rule == 1, "Checking for created authorized security group rule in describe results");

# revoke_security_group_ingress
my $revoke_result = $ec2->revoke_security_group_ingress(GroupName => "test_group", IpProtocol => 'tcp', FromPort => '7003', ToPort => '7003', CidrIp => '10.253.253.253/32');
ok($revoke_result == 1, "Checking for revocation of rule for security group");

# run_instances
my $run_result = $ec2->run_instances(
        MinCount        => 1, 
        MaxCount        => 1, 
        ImageId         => "ami-26b6534f", # ec2-public-images/developer-image.manifest.xml
        KeyName         => "test_keys", 
        SecurityGroup   => "test_group",
        InstanceType    => 'm1.small'
);
isa_ok($run_result, 'Net::Amazon::EC2::ReservationInfo');
ok($run_result->group_set->[0]->group_id eq "test_group", "Checking for running instance");
my $instance_id = $run_result->instances_set->[0]->instance_id;

# describe_instances
my $running_instances = $ec2->describe_instances();
my $seen_test_instance = 0;
foreach my $instance (@{$running_instances}) {
    my $instance_set = $instance->instances_set->[0];
    if ($instance_set->key_name eq "test_keys" and $instance_set->image_id eq "ami-26b6534f") {
        $seen_test_instance = 1;
    }
}
ok($seen_test_instance == 1, "Checking for newly run instance");

# terminate_instances
my $terminate_result = $ec2->terminate_instances(InstanceId => $instance_id);
is($terminate_result->[0]->instance_id, $instance_id, "Checking to see if instance was terminated successfully");

# delete_key_pair
$delete_key_result = $ec2->delete_key_pair(KeyName => "test_keys");
ok($delete_key_result == 1, "Deleting key pair");

# delete_security_group
$delete_group_result = $ec2->delete_security_group(GroupName => "test_group");
ok($delete_group_result == 1, "Deleting security group");

# THE REST OF THE METHODS ARE SKIPPED FOR NOW SINCE IT WOULD REQUIRE A DECENT AMOUNT OF TIME AFTER AN IMAGE HAS BEEN INSTANTIATED TO TEST