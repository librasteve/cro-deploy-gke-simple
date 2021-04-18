#!/usr/bin/env raku
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
#plan 1;

use Cro::Deploy::GKE::Simple;

my $app = Cro::App.new( name => 'hicro', project => 'hcccro1', version =>  '1.0' );

my $dep-manifest = Deployment.new( app => $app );
is $dep-manifest.filename, 'hicroweb-deployment.yaml',          'dep-fn';

my $isi-manifest = IngressStaticIP.new( app => $app );
is $isi-manifest.filename, 'hicroweb-ingress-static-ip.yaml',   'isi-fn';

done-testing;
