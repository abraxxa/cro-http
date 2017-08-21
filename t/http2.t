use Cro::HTTP::Server;
use Cro::HTTP::Client;
use Test;

class MyServer does Cro::Transform {
    method consumes() { Cro::HTTP::Request }
    method produces() { Cro::HTTP::Response }

    method transformer($request-stream) {
        supply {
            whenever $request-stream -> $request {
                given Cro::HTTP::Response.new(:200status, :$request) {
                    .append-header('content-type', 'text/html');
                    .set-body("Response");
                    .emit;
                }
            }
        }
    }
}

constant %ca := { ca-file => 't/certs-and-keys/ca-crt.pem' };
constant %ssl := {
    private-key-file => 't/certs-and-keys/server-key.pem',
    certificate-file => 't/certs-and-keys/server-crt.pem'
};

my Cro::Service $http2-service = Cro::HTTP::Server.new(
    :http<2>, :host<localhost>, :port(8000), :%ssl,
    :application(MyServer)
);

$http2-service.start;
note "Started at 8000";
END { $http2-service.stop; }

my $client = Cro::HTTP::Client.new(:http<2>);

given $client.get("https://localhost:8000", :%ca) -> $resp {
    my $res = await $resp;
    is (await $res.body), 'Response', 'HTTP/2 response is get';
}

done-testing;