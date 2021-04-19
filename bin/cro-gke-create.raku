#!/usr/bin/env raku
use lib '../lib';

use Cro::Deploy::GKE::Simple;

#`[
my $dep-manifest = Deployment.new( app => $app );
my $dfn = $dep-manifest.filename;
my $ddc = $dep-manifest.document;

my $isi-manifest = IngressStaticIP.new( app => $app );
my $ifn = $isi-manifest.filename;
my $idc = $isi-manifest.document;
]

sub MAIN(
        Str $directory where *.IO.d = '../examples/hicro',
        Str :$name = '',
        Str :$version = '',
        Bool :$run-local = False,
         ) {

    my $dir-path = IO::Path.new($directory);
    my $dir-abs = $dir-path.absolute;

    $dir-abs ~~ m|'/'

    dd $dir-abs;
    say "path-abs:", $dir-path.absolute;

    chdir($dir-path);



    shell "ls -al";
    die;
    #unless name

    my $proc;   #re-used

    $proc = shell("gcloud config list", :out);
    my $gconfig = $proc.out.slurp: :close;
    my %gconfig = $gconfig.split("\n").grep(/'='/).split(" = ").split(" ");

    my $app = Cro::App.new(
            :$name,
            :$version,
            project-id => %gconfig<project>,
            project-zone => %gconfig<zone>,
            );
    say ~$app;

    say "Building and tagging docker image for GCR...";
    shell("docker build -t { $app.cont-image } .");

    say "Checking docker image...";
    say "REPOSITORY                   TAG            IMAGE ID       CREATED             SIZE";
    shell("docker images | grep 'gcr'");

    if $run-local {
        say "Checking image runs locally...";
        $proc = Proc::Async.new("echo checking...");
        $proc.start;
        $proc.ready.then: {
            shell("docker run --rm -p { $app.target-port }:{ $app.target-port } { $app.cont-image }");
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
    shell("docker push { $app.cont-image }");

    sub cluster-up {
        my $proc = shell "kubectl get nodes", :out;
        my $out = $proc.out.slurp: :close;

        if    $out ~~ /Ready/ { True }
        else { False }
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
        my %ip-desc = ($proc.out.slurp: :close).lines.map({ .split(": ") }).flat;
        %ip-desc<address>;
    }

    say "Checking static IP address status...";
    if $app.ip-address = ip-address() {
        say "...static IP address { $app.ip-address } already created."
    } else {
        say "...creating a global static IP address with name { $app.ip-name } ...";
        shell("gcloud compute addresses create { $app.ip-name } --global");
        say "...done with IP address { $app.ip-address = ip-address }.";
    }

    say "Applying Ingress-Service manifest { $app.name }-ingress-static-ip.yaml.";
    shell("kubectl apply -f { $app.name }-ingress-static-ip.yaml");
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