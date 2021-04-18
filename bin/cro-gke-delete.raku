#!/usr/bin/env raku
use lib '../lib';

#FIXME- change name to eg. deploy.raku??

use Cro::Deploy::GKE::Simple;

sub MAIN(
        Str $app-path='../examples/hello-app',
        Str $app-name='helloweb',
        Str $app-label='hello',
        Str $cont-name='hello-app',
        Str $cont-tag='1.0',
         ) {

    #Cluster params
    my $cluster-name="{$app-name}-cluster";

    #Service params     #fixme - not used
    my $service-name="{$app-name}-service";

    #Ingress params
    my $ip-name="{$app-name}-ip";

    my $proc;       #re-used

    $proc = shell "gcloud config list", :out;
    my $config = $proc.out.slurp: :close;
    my %config = $config.split("\n").grep(/'='/).split(" = ").split(" ");

    my Str $project-id = %config<project>;
    my Str $project-zone = %config<zone>;

    say $app-path;
    say $app-name;
    say $app-label;
    say $cont-name;
    say $cont-tag;
    say $cluster-name;
    say $project-id;
    say $project-zone;

    chdir("$app-path/manifests");
    prompt("OK to delete Cro GKE ingress,service $app-label?[ret]");
    say "This can take several minutes, please be patient.";

    say "Deleting ingress,service...";
    shell("kubectl delete ingress,service -l app=$app-label");

    say "Deleting static IP...";
    shell("gcloud compute addresses delete $ip-name --global");

    say "Deleting deployment...";
    shell("kubectl delete -f {$app-name}-deployment.yaml");

    say "Deleting cluster...";
    shell("gcloud container clusters delete $cluster-name");

    say "Deleting container image...";
    shell("gcloud container images delete gcr.io/$project-id/$cont-name:$cont-tag  --force-delete-tags --quiet");

    say "deletion done";
}