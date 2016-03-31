#!/usr/bin/perl -w

package IbmVCS;

#use warnings;
#use strict;
#use strict;
use warnings ;
use Data::Dumper;
use XML::Simple;
use Net::Telnet;
use JSON;
use IO::CaptureOutput qw(capture_exec);

my $debug = 0;

my $zabbixSender="/usr/bin/zabbix_sender";
my $zabbixConfd="/etc/zabbix/zabbix_agentd.conf";
my $sendFile="/var/tmp/zabbixSenderHPP2000";
my $zabbixSendCommand="$zabbixSender -c $zabbixConfd -i ";



#$$debug == 1_commands = 1;
my $ipAddr = $ARGV[0];
my $ipPort = $ARGV[1];
my $username = $ARGV[2];
my $password = $ARGV[3];
my $command = $ARGV[4];
my $object = $ARGV[5];
my $zabbixhost = $ARGV[6];
# $ipPort = $ARGV[6];
#

# $telnet = new Net::Telnet ( Timeout=>10,
# 	Errmode=>'die',
# 	Prompt => '/\# $/i',
#     Max_buffer_length => 4048576 );

# if ( !cLogin($ipAddr, $username, $password) == 1 )
# {
#     print("Error: $username user failed to log in. Exiting.\n");
#     $telnet->close;
#     exit(0);
# }

# print("Info: Logged in. \n");

# @output = $telnet->cmd("set cli-parameters api-embed pager disabled");
# $scal = join("", @output);
#print Dumper($scal);

# my $ref = XMLin($scal);

# if (exists $ref->{OBJECT}->{PROPERTY}->{"return-code"} && $ref->{OBJECT}->{PROPERTY}->{"return-code"}->{content} == 0) {
#     $sessionKey = $ref->{OBJECT}->{PROPERTY}->{"response"}->{content};
# } else {
#     die($ref->{OBJECT}->{PROPERTY}->{"response"}->{content});
# }

if ($command eq 'lld') {
    my $zbxArray = [];

    ### IBM VSC
    if ($object eq 'spools'){
        getHPObjects ( "/root/ibm:IBMTSSVC_ConcreteStoragePool", "ElementName",
            "PoolID", "IBMTSSVC_ConcreteStoragePool", $zbxArray );
    }
    if ($object eq 'volumes'){
        getHPObjects ( "/root/ibm:IBMTSSVC_StorageVolume", "ElementName",
            "DeviceID", "IBMTSSVC_StorageVolume", $zbxArray, "IBMTSSVC_ConcreteStoragePool", "PoolName" );
    }
    if ($object eq 'mdisks'){
        getHPObjects ( "/root/ibm:IBMTSSVC_BackendVolume", "ElementName",
            "DeviceID", "IBMTSSVC_BackendVolume", $zbxArray, "IBMTSSVC_ConcreteStoragePool", "Poolname"  );
    }
    if ($object eq 'clusters'){
        getHPObjects ( "/root/ibm:IBMTSSVC_Cluster", "ElementName",
            "ID", "IBMTSSVC_Cluster", $zbxArray );
    }
    if ($object eq 'chassis'){
        getHPObjects ( "/root/ibm:IBMTSSVC_Chassis", "ElementName",
            "Name", "IBMTSSVC_Chassis", $zbxArray );
    }
    if ($object eq 'enclosures'){
        getHPObjects ( "/root/ibm:IBMTSSVC_Enclosure", "ElementName",
            "ElementName", "IBMTSSVC_Enclosure", $zbxArray );
    }
    if ($object eq 'nodes'){
        getHPObjects ( "/root/ibm:IBMTSSVC_Node", "ElementName",
            "ElementName", "IBMTSSVC_Node", $zbxArray );
    }
    if ($object eq 'drives'){
        getHPObjects ( "/root/ibm:IBMTSSVC_DiskDrive", "Name",
            "DeviceID", "IBMTSSVC_DiskDrive", $zbxArray, "IBMTSSVC_Enclosure", "EnclosureID" );
    }
    if ($object eq 'hosts'){
        getHPObjects ( "/root/ibm:IBMTSSVC_ProtocolController", "Name",
            "DeviceID", "IBMTSSVC_ProtocolController", $zbxArray, );
    }



    print to_json({data => $zbxArray} , { ascii => 1, pretty => 1 }) . "\n";


    #logOut($ua, $sessionKey, $hostname);
    #logOut();

}
elsif ($command eq 'stats') {
    my $objects = {};
    my $ctrls = {};
    my $vdisks = {};
    my $volumes = {};
    my $disks = {};
    my $fans = {};
    my $outputString = "";

    ### IBM VSC
    if ($object eq 'spools'){
        if ($debug == 1) {
            print 'spools\n';
        }
        getHPStats ( "/root/ibm:IBMTSSVC_ConcreteStoragePool",
            "OperationalStatus|NativeStatus|TotalManagedSpace|UsedCapacity|RemainingManagedSpace|Warning|Overallocation|VirtualCapacity",
            "PoolID", "IBMTSSVC_ConcreteStoragePool", $objects );

        $outputString .= getZabbixValues($zabbixhost, $objects, "spools");
    }
    if ($object eq 'volumes'){
        if ($debug == 1) {
            print 'volumes\n';
        }
        getHPStats ( "/root/ibm:IBMTSSVC_StorageVolume",
            "NativeStatus|OperationalStatus|EnabledState|RequestedState|PoolName",
            "DeviceID|", "IBMTSSVC_StorageVolume", $objects );

        $outputString .= getZabbixValues($zabbixhost, $objects, "volumes");
    }
    if ($object eq 'mdisks'){
        if ($debug == 1) {
            print 'mdisks\n';
        }
        getHPStats ( "/root/ibm:IBMTSSVC_BackendVolume",
            "NativeStatus|OperationalStatus|EnabledState|RequestedState|Poolname|Mode",
            "DeviceID|", "IBMTSSVC_BackendVolume", $objects );

        $outputString .= getZabbixValues($zabbixhost, $objects, "mdisks");
    }
    if ($object eq 'clusters'){
        if ($debug == 1) {
            print 'clusters\n';
        }
        getHPStats ( "/root/ibm:IBMTSSVC_Cluster",
            "ElementName|OperationalStatus|EnabledState|RequestedState|PoolCapacity|Status|StatusDescriptions|TotalUsedCapacity|TotalOverallocation|TotalVdiskCapacity|TotalVdiskCopyCapacity",
            "ID", "IBMTSSVC_Cluster", $objects );

        $outputString .= getZabbixValues($zabbixhost, $objects, "clusters");
    }
    if ($object eq 'chassis'){
        if ($debug == 1) {
            print 'chassis\n';
        }
        getHPStats ( "/root/ibm:IBMTSSVC_Chassis",
            "ElementName|OperationalStatus|EnabledState|RequestedState|PoolCapacity|Status|StatusDescriptions|TotalUsedCapacity|TotalOverallocation|TotalVdiskCapacity|TotalVdiskCopyCapacity",
            "Name", "IBMTSSVC_Chassis", $objects );

        $outputString .= getZabbixValues($zabbixhost, $objects, "chassis");
    }
    if ($object eq 'enclosures'){
        if ($debug == 1) {
            print 'enclosures\n';
        }
        getHPStats ( "/root/ibm:IBMTSSVC_Enclosure",
            "EnclosureStatus|Managed|IOGroupName|TotalCanisters|OnlineCanisters|TotalPSUs|OnlinePSUs",
            "ElementName", "IBMTSSVC_Enclosure", $objects );

        $outputString .= getZabbixValues($zabbixhost, $objects, "enclosures");
    }
    if ($object eq 'nodes'){
        if ($debug == 1) {
            print 'nodes\n';
        }
        getHPStats ( "/root/ibm:IBMTSSVC_Node",
            "NativeStatus|OperationalStatus|EnabledState|RequestedState|StatusDescriptions",
            "ElementName", "IBMTSSVC_Node", $objects );

        $outputString .= getZabbixValues($zabbixhost, $objects, "nodes");
    }
    if ($object eq 'drives'){
        if ($debug == 1) {
            print 'drives\n';
        }
        getHPStats ( "/root/ibm:IBMTSSVC_DiskDrive",
            "OperationalStatus|EnabledState|RequestedState",
            "DeviceID", "IBMTSSVC_DiskDrive", $objects );

        $outputString .= getZabbixValues($zabbixhost, $objects, "drives");
    }
    if ($object eq 'hosts'){
        if ($debug == 1) {
            print 'hosts\n';
        }
        getHPStats ( "/root/ibm:IBMTSSVC_ProtocolController",
            "OperationalStatus|EnabledState|RequestedState",
            "DeviceID", "IBMTSSVC_ProtocolController", $objects );

        $outputString .= getZabbixValues($zabbixhost, $objects, "hosts");
    }

    if ($object eq 'perf'){
        if ($debug == 1) {
            print 'perf\n';
        }
        getHPPerf( $objects );

        $outputString .= getZabbixValues($zabbixhost, $objects, "perf");
    }

    if ($debug == 1) {
        print $outputString . "";
    }


    $sendFile .= "_${hostname}_$$";
    die "Could not open file $sendFile!" unless (open(FH, ">", $sendFile));
    print FH $outputString;
    die "Could not close file $sendFile!" unless (close(FH));
    my $res;

    $zabbixSendCommand .= $sendFile;
    if ( qx($zabbixSendCommand) =~ /Failed 0/ ) {
        $res = 1;
    } else {
        $res = 0;
    }

    die "Can not remove file $sendFile!" unless(unlink ($sendFile));
    print "$res\n";
    exit ($res - 1);
}


sub getHPObjects {

    my $command = shift; # 1
    my $Name = shift; # 2
    my $idName = shift; # 2
    my $type = shift; # 3
    my $zbxArray = shift; # 4

    my $parentType = shift; # 5
    if (!defined($parentType)) {
        $parentType = "";
    }

    my $parentName = shift; # 6
    if (!defined($parentName)) {
        $parentName = "";
    }

    # print("Info: $command \n");
    # print("Info: $idName \n");
    # print("Info: $type \n");


    my $commandbegin = "wbemcli -noverify  ei -cte  -dx";

    my $cim = sprintf("'https://%s:%s\@%s:%s%s'", $username, $password, $ipAddr, $ipPort, $command);

    $command = sprintf("%s %s  ", $commandbegin, $cim );
    # 1 > /dev/null
    #print Dumper($command);
    #print $command;


    my $disks = `$command 2>&1 `;

    #$disks = join("",$disks);
    # $fans = join("", @fans);

    # print "**************";
    #print Dumper($disks);

    # print "111 ***-*-*-*-*", "\n";
    if ($disks =~ /From server: <\?xml version="1.0" encoding="utf-8" \?>\n<CIM CIMVERSION="2.0" DTDVERSION="2.0">(.*)<\/CIM>/gs ) {
        #print "222 ***-*-*-*-*", "\n";
        #print $1, "\n";
        $disks = $1;
    }

    #my $booklist = XMLin(@disk);

    #print Dumper($disks);
    #my $zbxArray = [];
    #my $ref = XMLin($disks, KeyAttr => { INSTANCE => 'CLASSNAME' });
    my $ref = XMLin($disks);

    if ($debug == 1) {
        print Dumper($ref);
    }

    # print "333 ***-*-*-*-*", "\n";

    my $array = $ref->{SIMPLERSP}->{IMETHODRESPONSE}->{IRETURNVALUE};
    #print Dumper($array);
    #print "444 ***-*-*-*-*", "\n";

    #print Dumper($array[0]);
    #print "555 ***-*-*-*-*", "\n";
    #foreach my $oid (values %{$ref->{SIMPLERSP}->{IMETHODRESPONSE}->{IRETURNVALUE}->{'VALUE.NAMEDINSTANCE'}->{INSTANCE}}) {

    my $finarr;
    eval {$finarr = @{$array->{'VALUE.NAMEDINSTANCE'}}};
    if ($@) {
        $finarr = '$array->{\'VALUE.NAMEDINSTANCE\'}';
    }
    else {
        $finarr = '@{$array->{\'VALUE.NAMEDINSTANCE\'}}';
    }

    if ($debug == 1) {
        print "arrayeval: ". $finarr;
    }



    #foreach my $oid (@{$array->{'VALUE.NAMEDINSTANCE'}}) {

    foreach my $oid (eval($finarr)) {


        #print "666 ***-*-*-*-*", "\n";
        #print Dumper($oid);
        #print($oid->{INSTANCE}->{CLASSNAME} . " *** \n");

        #if ($oid->{INSTANCE}->{CLASSNAME} eq $type) {
        if ($oid->{INSTANCE}->{CLASSNAME} =~ /^($type)$/ ) {
#            if ($debug == 1) {
#                print Dumper($oid);
#            }

            my $type = $1;

            #print($oid->{INSTANCE}->{CLASSNAME} . " 2*** \n");
            my $reference;
            my $name="";
            my $originName = "";
            my $id;
            my $description;
            my $parentname;

            my $elementName = "";
            my $parentName2 = "";
            my $SystemName = "";
            my $SystemCreationClassName = "";
            my $CreationClassName = "";
            my $hashKey;
            foreach my $entry (@{$oid->{INSTANCE}->{PROPERTY}}) {
                #print($entry->{NAME} . " ---- \n");
                #if ($entry->{NAME} eq "DeviceID" ) {
                #    $deviceid = $entry->{VALUE};
                #}
                if ($entry->{NAME} eq $Name ) {
                    $name = $entry->{VALUE};
                    ##last;
                }
                if ($entry->{NAME} eq "Name" ) {
                    $originName = $entry->{VALUE};
                    ##last;
                }
                if ($entry->{NAME} eq $idName ) {
                    $id = $entry->{VALUE};
                    ##last;
                }
                if ($entry->{NAME} eq $parentName ) {
                    $parentName2 = $entry->{VALUE};
                    ##last;
                }
                if ($entry->{NAME} eq "ElementName" ) {
                    $elementName = $entry->{VALUE};
                    ##last;
                }
                if ($entry->{NAME} eq "SystemName" ) {
                    $SystemName = $entry->{VALUE};
                    ##last;
                }
                if ($entry->{NAME} eq "SystemCreationClassName" ) {
                    $SystemCreationClassName = $entry->{VALUE};
                    ##last;
                }
                if ($entry->{NAME} eq "CreationClassName" ) {
                    $CreationClassName = $entry->{VALUE};
                    ##last;
                }

            }


            if ( $SystemCreationClassName eq "HP_TopComputerSystem") {
                $SystemName = "";
                $SystemCreationClassName = "";
            }
            elsif ( $SystemCreationClassName ne "" ) {
                $SystemName .= " (" . $SystemCreationClassName . ")" . "::";
                # $SystemCreationClassName = " (" . $SystemCreationClassName . ")";
            }

            if ("" ne $parentType && defined($parentType)) {
                $SystemName = $parentName2 . " (" . $parentType . ")" . "::";
                $SystemCreationClassName = $parentType;
            }

            #if ($name eq "") {
            #    $name = $id;
            #}

            if ($CreationClassName eq "") {
                if ($debug == 1) {
                    print "CreationClassName is empty! \n";
                    print "type:" . $type . " \n";
                }
                $CreationClassName = $type;
            }

            $reference = {
                '{#HP_P2000_NAME}'          => $name,
                '{#HP_P2000_ORIGINNAME}'    => $originName,
                '{#HP_P2000_ELEMENTNAME}'   => $elementName,
                '{#HP_P2000_ID}'            => $id,
                '{#HP_P2000_PARENT}'        => $SystemName,
                '{#HP_P2000_PARENTTYPE}'    => $SystemCreationClassName,
                '{#HP_P2000_TYPE}'          => $CreationClassName };

            #$colHash->{$hashKey} = {%{$reference}};
            push @{$zbxArray}, {%{$reference}};
        }
    }

    %h = (a => 1, b => 2, b => 3);

    keys %h;
    while(my($k, $v) = each %h)
    {
        #$h{uc $k} = $h{$k} * 2; # BAD IDEA!
        #	print "key: $k, value: $v\n";
    }
    #print Dumper($h);

    # my $ref_fans = XMLin($fans, KeyAttr => ["oid_fans"]);
    # foreach my $oid_fans (values %{$ref_fans->{OBJECT}}) {
    #     #print($oid->{name} . " *** \n");
    #     if ($oid_fans->{name} eq $type) {
    #         my $reference_fans;
    #         my $hashKey_fans;
    #         foreach my $entry_fans (@{$oid_fans->{PROPERTY}}) {
    #             #print($entry->{name} . " ---- \n");
    #             if ($entry_fans->{name} eq $idName ) {
    #                 $reference_fans = {'{#HP_P2000_ID}' => $entry->{content}, '{#HP_P2000_TYPE}' => $oid->{name}};
    #                 last;
    #             }
    #         }
    #         #$colHash->{$hashKey} = {%{$reference}};
    #     push @{$zbxArray}, {%{$reference}};
    #     }
    # }

}

sub getHPPerf {

    $debug = 1;

    my $colHash = shift; # 5

    my $commandbegin = "ssh -q -i /usr/lib/zabbix/externalscripts/id_rsa -o PasswordAuthentication=no ";

    my $ssh = sprintf("%s\@%s", $username, $ipAddr );

    $command = sprintf("%s %s lssystemstats -delim : 2>&1  ", $commandbegin, $ssh );

    #$command

    # 1 > /dev/null
    #print Dumper($command);
   # print "11111" . $command . "\n";

    #my ($stdout, $stderr, $success, $exitcode) = qx( $command );;

    my @perfstats = `$command`; #2>&1;

    if ($debug == 1) {
        #print "****" . $stdout;
        #print "****" . $lines_from_ssh;
        print Dumper(@perfstats);
    }
    my $reference;
    foreach my $oid (@perfstats) {
        my $item;
        my $value;


        if ($oid =~ /^(.*):(\d+):(\d+):(\d+)\n$/ ) {


            $item = $1;
            $value = $2;
            $reference->{$item} = $value;


        }


    }
    $colHash->{'System'} = {%{$reference}};

    if ($debug == 1) {
        print Dumper($colHash);
    }

}

sub getHPStats {

    my $command = shift; # 1
    my $item = shift; # 2
    my $idName = shift; # 3
    my $type = shift; # 4
    my $colHash = shift; # 5

    # print("Info: $command \n");
    # print("Info: $idName \n");
    # print("Info: $type \n");
    my $commandbegin = "wbemcli -noverify  ei -cte  -dx";

    my $cim = sprintf("'https://%s:%s\@%s:%s%s'", $username, $password, $ipAddr, $ipPort, $command);

    $command = sprintf("%s %s  ", $commandbegin, $cim );
    # 1 > /dev/null
    #print Dumper($command);
    #print $command;


    my $disks = `$command 2>&1 `;

    #$disks = join("",$disks);
    # $fans = join("", @fans);

    # print "**************";
    #print Dumper($disks);

    # print "111 ***-*-*-*-*", "\n";
    if ($disks =~ /From server: <\?xml version="1.0" encoding="utf-8" \?>\n<CIM CIMVERSION="2.0" DTDVERSION="2.0">(.*)<\/CIM>/gs ) {
        #print "222 ***-*-*-*-*", "\n";
        #print $1, "\n";
        $disks = $1;
    }

    #my $booklist = XMLin(@disk);

    #print Dumper($disks);

    if ($debug == 1) {
        print Dumper($disks);
    }
    #my $zbxArray = [];
    #my $ref = XMLin($disks, KeyAttr => { INSTANCE => 'CLASSNAME' });
    my $ref = XMLin($disks);



    # print "333 ***-*-*-*-*", "\n";

    my $array = $ref->{SIMPLERSP}->{IMETHODRESPONSE}->{IRETURNVALUE};

    my $finarr;
    eval {$finarr = @{$array->{'VALUE.NAMEDINSTANCE'}}};
    if ($@) {
        $finarr = '$array->{\'VALUE.NAMEDINSTANCE\'}';
    }
    else {
        $finarr = '@{$array->{\'VALUE.NAMEDINSTANCE\'}}';
    }

    if ($debug == 1) {
        print "arrayeval: ". $finarr;
    }
    #my $ref = XMLin($disks, KeyAttr => ["oid"]);
    foreach my $oid (eval($finarr)) {
        #print "666 ***-*-*-*-*", "\n";
        #print Dumper($oid);
        if ($debug == 1) {
            print Dumper($oid);
        }
        #print($oid->{INSTANCE}->{CLASSNAME} . " *** \n");

        #if ($oid->{INSTANCE}->{CLASSNAME} eq $type) {
        if ($oid->{INSTANCE}->{CLASSNAME} =~ /^($type)$/ ) {


            #print($oid->{INSTANCE}->{CLASSNAME} . " 2*** \n");
            my $reference;
            my $name;
            my $description;
            my $parentname;
            my $type;
            my $SystemName = "";
            my $SystemCreationClassName = "";
            my $hashKey;
            my $id;
            foreach my $entry (@{$oid->{INSTANCE}->{PROPERTY}}) {
                if ($debug == 1) {
                    print Dumper($entry);
                }
                #print($entry->{NAME} . " ---- \n");
                #if ($entry->{NAME} eq "DeviceID" ) {
                #    $deviceid = $entry->{VALUE};
                #}
                if ($entry->{NAME} eq $idName ) {
                    $id = $entry->{VALUE};
                    ##last;
                }
                if ($entry->{NAME} =~ /^($idName|$item)$/ ) {
                    my $key = $1;
                    if ($key =~ /^($idName)$/) {
                        #$hashKey = lc($entry->{VALUE});
                        $hashKey = $entry->{VALUE};
                    } else {
                        $reference->{$key} = $entry->{VALUE};
                    }
                }
            }

            #$colHash->{$hashKey} = {%{$reference}};
            if ($debug == 1) {
                #print Dumper($oid->{INSTANCE});
            }

            eval {
                foreach my $entry (@{$oid->{INSTANCE}->{'PROPERTY.ARRAY'}}) {

                    if ($debug == 1) {
                        #print Dumper($entry);
                    }
                    #print($entry->{NAME} . " ---- \n");
                    #if ($entry->{NAME} eq "DeviceID" ) {

                    if ($entry->{NAME} =~ /^($item)$/ ) {
                        my $key = $1;

                        $reference->{$key} = $entry->{'VALUE.ARRAY'}->{VALUE};

                    }
                }
            };
            eval {
                $entry = $oid->{INSTANCE}->{'PROPERTY.ARRAY'};
                if ($debug == 1) {
                    #print Dumper($entry);
                }
                if ($entry->{NAME} =~ /^($item)$/ ) {
                    my $key = $1;

                    $reference->{$key} = $entry->{'VALUE.ARRAY'}->{VALUE};

                }
            };

            $colHash->{$hashKey} = {%{$reference}};

        }
    }

    if ($debug == 1) {
        #print Dumper($colHash);
    }


}

sub getZabbixValues {
    our $hostname = shift;
    my $colHash = shift;
    my $type = shift;
    my $outputString = "";

    foreach my $key (keys %{$colHash}) {
        foreach my $itemKey (keys %{$colHash->{$key}}) {
            my $itemKeyPrefix = "ibm.vcs.stats.$type" . "." . $itemKey;
            $outputString .= "\"$hostname\" \"$itemKeyPrefix" . "[$key]\" \"$colHash->{$key}->{$itemKey}\"\n";
        }
    }

    #print $outputString;
    $outputString;
}

# @sV = $telnet->cmd("show configuration");
# for ($i=0; $i<scalar(@sV); $i++)
# {
#     print ("@sV[ $i ]");
# }

