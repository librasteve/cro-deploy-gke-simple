#!/usr/bin/env raku
use lib '../lib';
use Cro::Deploy::GKE::Simple;

sub MAIN(
        Str $directory where *.IO.d = '../examples/hicro',
        Str :$appname = '',
        Str :$version = '1.0',
         ) {
    chdir($directory);

    # Get app name as enclosing directory name unless specified on command line
    my $name = $appname || ($directory.IO.absolute ~~ m|'/' (<-[/]>*?) $|).[0].Str;

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

    my $dpm = Deployment.new(app => $app);

    prompt("OK to delete Cro GKE ingress,service { $app.name }?[ret]");
    say "This can take several minutes, please be patient.";

    say "Deleting ingress,service...";
    shell("kubectl delete ingress,service -l app={ $app.name }");

    say "Deleting static IP...";
    shell("gcloud compute addresses delete { $app.ip-name } --global");

    chdir("manifests");
    say "Deleting deployment...";
    shell("kubectl delete -f { $dpm.filename }");

    say "Deleting cluster...";
    shell("gcloud container clusters delete { $app.cluster-name }");

    say "Deleting container image...";
    shell("gcloud container images delete { $app.cont-image } --force-delete-tags --quiet");

    say "deletion done";
}