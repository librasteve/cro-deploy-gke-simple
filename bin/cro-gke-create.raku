#!/usr/bin/env raku
use lib '../lib';
use Cro::Deploy::GKE::Simple;

sub MAIN(
        Str $directory where *.IO.d = '../examples/hicro',
        Str :$app-name = '',
        Str :$version = '1.0',
        Bool :$check-local = False,
         ) {
    chdir($directory);

    # Get app name as enclosing directory name unless specified on command line
    my $name = $app-name || ( $directory.IO.absolute ~~ m|'/' (<-[/]>*?) $| ).[0].Str;

    # Get target-port from Dockerfile
    my $target-port = 'Dockerfile'.IO.lines.grep(/EXPOSE/).split(" ").[1].Int;

    # Get project items from gcloud config
    my $proc;
    $proc = shell("gcloud config list", :out);
    my $gconfig = $proc.out.slurp: :close;
    my %gconfig = $gconfig.split("\n").grep(/'='/).split(" = ").split(" ");

    my $app = App.new(
            :$name,
            :$version,
            :$target-port,
            project-id => %gconfig<project>,
            );
    say "Loading app parameters => ", $app.gist;

    my $dpm = Deployment.new( app => $app );
    my $isi = IngressStaticIP.new( app => $app );

    if not "manifests".IO.d {
        say "Creating manifests sub-directory for GKE...";
        mkdir("manifests");
        chdir("manifests");

        say "Writing Deployment manifest...";
        spurt $dpm.filename, $dpm.document;

        say "Writing IngressStaticIP manifest...";
        spurt $isi.filename, $isi.document;

        chdir("..");
    } else {
        say "Using existing manifests [delete 'manifests' sub-dir to rebuild...";
    }

    say "Building and tagging docker image for GCR...";
    shell("docker build -t { $app.cont-image } .");

    say "Checking docker image...";
    say "REPOSITORY                   TAG            IMAGE ID       CREATED             SIZE";
    shell("docker images | grep 'gcr'");

    if $check-local {
        say "Checking image runs locally...";
        $proc = Proc::Async.new("echo checking...");
        $proc.start;
        $proc.ready.then: {
            shell("docker run --rm -p { $app.target-port }:{ $app.target-port } { $app.cont-image }");
        }
        sleep 5;
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
        say "Hmmm - looks like we need to create one ...";
        say "Creating a GKE Standard cluster (please be patient) [{ $app.cluster-name }]...";
        shell("gcloud container clusters create { $app.cluster-name }");
    }

    chdir("manifests");

    say "Applying Deployment manifest { $dpm.filename }...";
    shell("kubectl apply -f { $dpm.filename }");

    sub check-ip {
        my $proc = shell "gcloud compute addresses describe { $app.ip-name } --global", :out, :err;
        return False if $proc.err.slurp: :close;
        my %ip-desc = ($proc.out.slurp: :close).lines.map({ .split(": ") }).flat;
        %ip-desc<address>;
    }

    say "Checking static IP address status...";
    if my $ip = check-ip() {
        $app.ip-address = $ip;
        say "...static IP address { $app.ip-address } already created."
    } else {
        say "...creating a global static IP address with name { $app.ip-name } ...";
        shell("gcloud compute addresses create { $app.ip-name } --global");
        say "...done with IP address { $app.ip-address = check-ip }.";
    }

    say "Applying Ingress-Service manifest { $isi.filename }...";
    shell("kubectl apply -f { $isi.filename }");
    sleep 5;
    shell("kubectl get ingress");

    say "deployment done...";
    say "...takes approx. 3-5 mins to go live at { $app.ip-address } ...";
    say "...use <<kubectl get ingress>> for status...";
    say "...or viz. https://console.cloud.google.com";
}