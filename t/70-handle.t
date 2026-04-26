use strict;
use warnings;
use Test::More;
use IO::Async::Loop;
use JSON::MaybeXS qw( encode_json decode_json );

use Net::Async::MCP::Run;

my $loop = IO::Async::Loop->new;

subtest 'handle - initialize request returns server info' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 1,
        method  => 'initialize',
        params  => { protocolVersion => '2025-11-25', capabilities => {} },
    });

    ok( $response, 'has response' );
    is( $response->{id}, 1, 'id matches' );
    is( $response->{result}{protocolVersion}, '2025-11-25', 'protocol version' );
    is( $response->{result}{serverInfo}{name}, 'test-server', 'server name' );
};

subtest 'handle - tools/list returns run tool' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    $server->initialize->get;

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 2,
        method  => 'tools/list',
        params  => {},
    });

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

    $server->initialize->get;

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 3,
        method  => 'tools/call',
        params  => {
            name      => 'run',
            arguments => { command => 'echo hello world' },
        },
    });

    ok( $response, 'has response' );
    is( $response->{id}, 3, 'id matches' );
    ok( $response->{result}{content}, 'has content' );
    like( $response->{result}{content}[0]{text}, qr/hello world/, 'output contains hello world' );
};

subtest 'handle - ping returns success' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 4,
        method  => 'ping',
        params  => {},
    });

    ok( $response, 'has response' );
    is( $response->{id}, 4, 'id matches' );
};

subtest 'handle - unknown method returns error' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 5,
        method  => 'unknown/method',
        params  => {},
    });

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