#!/usr/bin/env raku
use lib '../lib';

#FIXME- change name to eg. deploy.raku??

use Cro::Deploy::GKE::Simple;

sub MAIN(
        Str $app-path='../examples',
        Str $app-name='hello-app',
        Str $app-tag='v1',
         ) {

    my $proc;       #re-used

    $proc = shell "gcloud config list", :out;
    my $config = $proc.out.slurp: :close;
    my %config = $config.split("\n").grep(/'='/).split(" = ").split(" ");

    my Str $project-id = %config<project>;
    my Str $project-zone = %config<zone>;

    say $app-path;
    say $app-name;
    say $app-tag;
    say $project-id;
    say $project-zone;

    chdir("$app-path/$app-name");
    prompt("OK to delete Cro GKE service $service-name?[ret]");

    say "Deleting service...";
    shell("kubectl delete service $service-name");

    say "Deleting cluster...";
    shell("gcloud container clusters delete $cluster-name --zone $project-zone");

    say "Deleting container image...";
    shell("gcloud container images delete gcr.io/$project-id/$app-name:$app-tag  --force-delete-tags --quiet");

    say "delete done";
}