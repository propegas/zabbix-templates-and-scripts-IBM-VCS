#!/usr/bin/perl -w

#### Fix for invalid certs on hosts.
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

use utf8;
use strict;
use warnings;
use VMware::VIRuntime;
use VMware::VILib;
use Data::Dumper;
use XML::Simple;
use JSON;
use Cwd;

chdir '/usr/lib/zabbix/externalscripts';
my $current=getcwd();
#print "cwd: " . $current;

binmode(STDOUT,':utf8');

my $debug = 1;

my $zabbixSender="/usr/bin/zabbix_sender";
my $zabbixConfd="/etc/zabbix/zabbix_agentd.conf";
my $sendFile="/var/tmp/zabbixSenderVCenter";
my $zabbixSendCommand="$zabbixSender -vvv -c $zabbixConfd -i ";

my $vclogfile = "VM/vc__vm_discovery.log";

my $function = $ARGV[0];
my $host = $ARGV[1];
my $entity_type = "";

if ($function eq "vm") {
    $entity_type = "VirtualMachine";
}

if ($function eq "host") {
    $entity_type = "HostSystem";#"VirtualMachine";
}

Opts::parse();
Opts::validate();
Util::connect();

#### Get command-line arguments we will need.
my $serverIP = Opts::get_option('server');

#### Obtain all inventory objects of the specified type
#my $entity_type = Opts::get_option('entity');

my $result = "";

#### Process the findings and output per-VM data to $resultfile
if ($function eq "vm" ) {

    my $host_entity_views = Vim::find_entity_view(
        view_type => 'HostSystem',
        filter => {
            'name' => qr/^$host/i #$zabbixhost
        }
    );

    my $vm_views;
    if($host_entity_views) {
        $vm_views = Vim::find_entity_views(
            view_type    => 'VirtualMachine',
            begin_entity => $host_entity_views
        );

    }

    my $zbxArray;
    my $guest_ip= "";
    my $guest_hostname = "";
    #foreach my $entity_view (sort {lc($a->name) cmp lc($b->name)} @$entity_views) {
    foreach my $entity_view (@$vm_views) {
        my $cfg_instance_uuid = $entity_view->config->instanceUuid;
        $guest_ip = $entity_view->guest->ipAddress;
        my $entity_name = $entity_view->name;
        $guest_hostname = $entity_view->guest->hostName;

        #### print VM properties into $resultfile
#        $result .= '  <VM>'."\n";
#        $result .= qq{    <instanceUuid>$cfg_instance_uuid</instanceUuid>\n};
#        $result .= qq{    <ipAddress>$guest_ip</ipAddress>\n};
#        $result .= qq{    <name>$entity_name</name>\n};
#        $result .= qq{    <hostName>$guest_hostname</hostName>\n};
#        $result .= '  </VM>'."\n";

        my $reference = {
            '{#VM_NAME}'            => $entity_name,
            '{#VM_HOSTNAME}'        => $guest_hostname,
            '{#VM_IP}'              => $guest_ip,
            '{#VM_UUID}'            => $cfg_instance_uuid,
            '{#VM_HYPERVISOR_HOST}' => $host
        };

        push @{$zbxArray}, {%{$reference}};


    }

    print to_json({data => $zbxArray} , { ascii => 1, pretty => 1 }) . "\n";
}

if ($function eq "host" ) {

    my $host_entity_views = Vim::find_entity_views(
        view_type => 'HostSystem',
        filter => {
            'name' => qr/^$host/i #$zabbixhost
        }
    );
    #my $guest_ip= "";
    #my $guest_hostname = "";
    #foreach my $entity_view (sort {lc($a->name) cmp lc($b->name)} @$entity_views) {
    foreach my $entity_view (@$host_entity_views) {
        #my $cfg_instance_uuid = $entity_view->config->instanceUuid;
        #$guest_ip = $entity_view->guest->ipAddress;
        my $entity_name = $entity_view->name;
        #$guest_hostname =  $entity_view->guest->hostName;

        #### print VM properties into $resultfile
        $result .= '  <VM>'."\n";
        #$result .= qq{    <instanceUuid>$cfg_instance_uuid</instanceUuid>\n};
        #$result .= qq{    <ipAddress>$guest_ip</ipAddress>\n};
        $result .= qq{    <name>$entity_name</name>\n};
        #$result .= qq{    <hostName>$guest_hostname</hostName>\n};
        $result .= '  </VM>'."\n";

    }
}


#$result .= '  <VM>'."\n";
#$result .= qq{    <instanceUuid>000</instanceUuid>\n};
#$result .= '  </VM>'."\n";

#### Write XML footer into $resultfile
#$result .= '</vcenter>'."\n";

#print "file: \n " . $result;