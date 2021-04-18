#!/usr/bin/env raku
use lib '../lib';

use Cro::Deploy::GKE::Simple;

#`[
my $app = Cro::App.new( name => 'hicro', project => 'hcccro1', version =>  '1.0' );

my $dep-manifest = Deployment.new( app => $app );
my $dfn = $dep-manifest.filename;
my $ddc = $dep-manifest.document;

my $isi-manifest = IngressStaticIP.new( app => $app );
my $ifn = $isi-manifest.filename;
my $idc = $isi-manifest.document;
]

sub MAIN(
        Str $app-path='../examples/hello-app',
        Str $app-name='helloweb',
        Str $app-label='hello',
        Str $cont-name='hello-app',
        Str $cont-tag='1.0',
        Bool $run-local=False,
         ) {

    my $app = Cro::App.new( name => 'hicro', project => 'hcccro1', version =>  '1.0' );

    #Ingress params
    #my $app.ip-name="{$app-name}-ip";
    #my $app.ip-address;

    my $proc;       #re-used

    $proc = shell("gcloud config list", :out);
    my $config = $proc.out.slurp: :close;
    my %config = $config.split("\n").grep(/'='/).split(" = ").split(" ");

    my Str $project-id = %config<project>;
    my Str $project-zone = %config<zone>;

    say $app-path;
    say $app-name;
    say $app-label;
    say $cont-name;
    say $cont-tag;
    say $app.cluster-name;
    say $project-id;
    say $project-zone;

    chdir("$app-path");

    die;

    say "Building and tagging docker image for GCR...";
    shell("docker build -t gcr.io/$project-id/$cont-name:$cont-tag .");

    say "Checking docker image...";
    say "REPOSITORY                   TAG            IMAGE ID       CREATED             SIZE";
    shell("docker images | grep 'gcr'");

    if $run-local {
        say "Checking image runs locally...";
        $proc = Proc::Async.new("echo checking...");
        $proc.start;
        $proc.ready.then: {
            shell("docker run --rm -p { $app.target-port }:{ $app.target-port } gcr.io/$project-id/$cont-name:$cont-tag");
        }
        sleep 2;
        shell("curl http://localhost:{ $app.target-port }");
        prompt("If OK, please stop docker container using app, OK to proceed?[ret]");
        $proc.kill(SIGTERM);
    }

    say "Enabling container registry API for project and docker auth...";
    shell("gcloud services enable containerregistry.googleapis.com");
    shell("gcloud auth configure-docker");

    say "Pushing docker image to GCR...";
    shell("docker push gcr.io/$project-id/$cont-name:$cont-tag");

    sub cluster-up {
        my $proc = shell "kubectl get nodes", :out;
        my $out = $proc.out.slurp: :close;

        if    $out ~~ /Ready/   { True  }
        else                    { False }
    }

    say "Checking cluster status...";
    if cluster-up() {
        say "Cluster already created."
    } else {
        say "Creating a GKE Standard cluster (please be patient) [{ $app.cluster-name }]...";
        shell("gcloud container clusters create { $app.cluster-name }");
    }

    chdir("manifests");

    say "Applying Deployment manifest { $app.name }-deployment.yaml.";
    shell("kubectl apply -f { $app.name }-deployment.yaml");

    sub ip-address {
        my $proc = shell "gcloud compute addresses describe { $app.ip-name } --global", :out;
        my %ip-desc = ($proc.out.slurp: :close).lines.map({.split(": ")}).flat;
        %ip-desc<address>;
    }

    say "Checking static IP address status...";
    if $app.ip-address=ip-address() {
        say "...static IP address { $app.ip-address } already created."
    } else {
        say "...creating a global static IP address with name { $app.ip-name } ...";
        shell("gcloud compute addresses create { $app.ip-name } --global");
        say "...done with IP address { $app.ip-address=ip-address }.";
    }

    say "Applying Ingress-Service manifest {$app-name}-ingress-static-ip.yaml.";
    shell("kubectl apply -f { $app-name }-ingress-static-ip.yaml");
    sleep 5;
    shell("kubectl get ingress");

    say "deployment done...";
    say "...takes approx. 3m30s to go live at { $app.ip-address } ...";
    say "...use <<kubectl get ingress>> for status.";

    #`[
    also clean up
    * static IP
    * ingress
    ]
}