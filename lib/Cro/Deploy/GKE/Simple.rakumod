unit module Cro::Deploy::GKE::Simples:ver<0.0.1>:auth<Steve Roe (p6steve@furnival.net)>;

use YAMLish;

#cro stub sets ENV HICRO_HOST="0.0.0.0" HICRO_PORT="10000"

constant $sub-dir ='manifests';
constant $dep-suff ='deployment';
constant $isi-suff ='ingress-static-ip';

constant $backend='backend';
constant $app='app';
constant $web='web';
constant $ip='ip';


class Cro::App is export {
    has Str $.name;
    has Str $.location;
}

class Manifest {
    has Cro::App $!app;
    has $!document;

    method location() {
        $!app.location ~ '/' ~ $sub-dir
    }
    method load(Str $input) {
        $!document = load-yaml($input)
    }
    method save() {
        save-yaml($!document)
    }
}

class Deployment is Manifest {
    method name() {
        $!app.name ~ 'web-' ~
    }
}
class IngressStaticIP is Manifest {
    ...
}



say "ho"
#EOF

#fixme - change LICENCE to Apache License, Version 2.0
