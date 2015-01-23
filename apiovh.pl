#!/usr/bin/perl
#usage
# print "Error please give me userovh passwordovh domaintest\n";
# print "exemple apiovh.pl -user gsuser-ovh -password password -domain domaineforcheck.com -query domainList\n";
# exit;
#

use Getopt::Long;
use strict;
use Data::Dumper;
use SOAP::Lite
on_fault => sub { my($soap, $res) = @_; die ref $res ? $res->faultstring : $soap->transport->status; };
use DateTime;
use DateTime::Format::Strptime;
use DateTime::Format::Duration;

my $ouser;
my $opassword;
my $odomain;
my $query;

GetOptions ('user=s' => \$ouser,
'password=s' => \$opassword,
'domain=s' => \$odomain,
'query=s' => \$query);

#debug
#open(my $fh, '>>', '/tmp/report.txt');
#print $fh "executed\n";
#close $fh;
#debug

my $soap = SOAP::Lite
    -> uri('https://soapi.ovh.com/manager')
    -> proxy('https://www.ovh.com:1664')
    -> login ($ouser, $opassword, 'fr')
;
my $res = $soap->result;                               

if ($query eq "domainList")
{
    $soap = SOAP::Lite
	-> uri('https://soapi.ovh.com/manager')
	-> proxy('https://www.ovh.com:1664')
	-> $query ($res)
	;
    my $i = 1;
    my @listings = @{$soap->result};
    print '{  "data":['."\n";
    foreach my $listing (@listings) {
	print '{"{#FQDN}":"';
	print $listing;
	$i++;
	if ($i <= (scalar @listings))
	{
	    print "\"},\n";
	}
	else
	{
	    print "\"}\n";
	}
    }
    print "] }\n";
}
elsif ($query eq "domainInfo")
{
    $soap = SOAP::Lite
        -> uri('https://soapi.ovh.com/manager')
        -> proxy('https://www.ovh.com:1664')
        -> domainInfo ($res, $odomain)
        ;
    my $listings = $soap->result;
    foreach my $listing ($listings) {
	my $today = DateTime->now( time_zone => 'Europe/Brussels' );
	my $parser = DateTime::Format::Strptime->new(
	    pattern => '%Y-%m-%d',
	    on_error => 'croak',
	    );
	my $expiration = $parser->parse_datetime($listing->{expiration});
	
	my $d = DateTime::Format::Duration->new(
                pattern => "%j\n");
	print $d->format_duration($expiration->subtract_datetime($today));
    }
}
