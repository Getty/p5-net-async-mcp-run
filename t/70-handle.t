use strict;
use warnings;
use Test::More;
use IO::Async::Loop;
use JSON::MaybeXS qw( encode_json decode_json );

use Net::Async::MCP::Run;

my $loop = IO::Async::Loop->new;

# Build a fully-formed 2026-07-28 request envelope. Every id-bearing request
# to the base server must carry the io.modelcontextprotocol/* _meta keys, so
# tests thread them through here and override individual fields as needed.
sub _req {
    my (%override) = @_;
    my %meta = (
        'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
        'io.modelcontextprotocol/clientCapabilities' => {},
    );
    my $params = delete $override{params} // {};
    $params->{_meta} //= \%meta;
    return {
        jsonrpc => '2.0',
        id      => 1,
        params  => $params,
        %override,
    };
}

subtest 'handle - server/discover request returns server info' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    my $response = $server->handle(_req(
        id     => 1,
        method => 'server/discover',
    ));

    ok( $response, 'has response' );
    is( $response->{id}, 1, 'id matches' );
    is( $response->{result}{supportedVersions}[0], '2026-07-28', 'supported version' );
    is(
        $response->{result}{_meta}{'io.modelcontextprotocol/serverInfo'}{name},
        'test-server',
        'server name in _meta serverInfo',
    );
};

subtest 'handle - tools/list returns run tool' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    $server->discover->get;

    my $response = $server->handle(_req(
        id     => 2,
        method => 'tools/list',
    ));

    ok( $response, 'has response' );
    is( $response->{id}, 2, 'id matches' );
    ok( $response->{result}{tools}, 'has tools' );
    is( $response->{result}{tools}[0]{name}, 'run', 'tool name is run' );
};

subtest 'handle - tools/call executes command' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    $server->discover->get;

    my $response = $server->handle(_req(
        id     => 3,
        method => 'tools/call',
        params => {
            name      => 'run',
            arguments => { command => 'echo hello world' },
        },
    ));

    ok( $response, 'has response' );
    is( $response->{id}, 3, 'id matches' );
    ok( $response->{result}{content}, 'has content' );
    like( $response->{result}{content}[0]{text}, qr/hello world/, 'output contains hello world' );
};

subtest 'handle - legacy ping method is rejected under 2026 protocol' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    my $response = $server->handle(_req(
        id     => 4,
        method => 'ping',
    ));

    ok( $response, 'has response' );
    is( $response->{id}, 4, 'id matches' );
    ok( $response->{error}, 'has error' );
    is( $response->{error}{code}, -32601, 'method not found code' );
};

subtest 'handle - unknown method returns error' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    my $response = $server->handle(_req(
        id     => 5,
        method => 'unknown/method',
    ));

    ok( $response, 'has response' );
    is( $response->{id}, 5, 'id matches' );
    ok( $response->{error}, 'has error' );
    is( $response->{error}{code}, -32601, 'method not found code' );
};

subtest 'handle - missing method returns error' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 6,
    });

    ok( $response, 'has response' );
    is( $response->{id}, 6, 'id matches' );
    ok( $response->{error}, 'has error' );
    is( $response->{error}{code}, -32600, 'invalid request code' );
};

done_testing;
