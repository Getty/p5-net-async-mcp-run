use strict;
use warnings;
use Test::More;
use IO::Async::Loop;

use Net::Async::MCP::Run;

my $loop = IO::Async::Loop->new;

subtest 'call_tool executes command and returns result' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    $server->initialize->get;

    my $result = $server->call_tool('run', {
        command => 'echo hello world',
    })->get;

    ok( $result->{content}, 'has content' );
    is( $result->{isError}, 0, 'no error' );
    like( $result->{content}[0]{text}, qr/hello world/, 'output contains echo text' );
};

subtest 'call_tool with exit code 0' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    $server->initialize->get;

    my $result = $server->call_tool('run', {
        command => 'true',
    })->get;

    ok( $result->{content}, 'has content' );
    is( $result->{isError}, 0, 'no error' );
    like( $result->{content}[0]{text}, qr/Exit code: 0/, 'exit code 0' );
};

subtest 'call_tool with exit code != 0' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    $server->initialize->get;

    my $result = $server->call_tool('run', {
        command => 'false',
    })->get;

    ok( $result->{content}, 'has content' );
    is( $result->{isError}, 1, 'isError is true' );
    like( $result->{content}[0]{text}, qr/Exit code: 1/, 'exit code 1' );
};

done_testing;