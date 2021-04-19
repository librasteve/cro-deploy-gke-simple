use Cro::HTTP::Log::File;
use Cro::HTTP::Server;
use Routes;

my Cro::Service $http = Cro::HTTP::Server.new(
    http => <1.1>,
    host => %*ENV<HICRO_HOST> ||
        die("Missing HICRO_HOST in environment"),
    port => %*ENV<HICRO_PORT> ||
        die("Missing HICRO_PORT in environment"),
    application => routes(),
    after => [
        Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
    ]
);
$http.start;
say "Listening at http://%*ENV<HICRO_HOST>:%*ENV<HICRO_PORT>";
react {
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
}
