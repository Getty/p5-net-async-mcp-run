use strict;
use warnings;
use Test::More;
use IO::Async::Loop;

use Net::Async::MCP::Run;

my $loop = IO::Async::Loop->new;

subtest 'allowed_commands - allowed command succeeds' => sub {
    my $server = Net::Async::MCP::Run->new(
        name             => 'test-server',
        allowed_commands => ['echo'],
    );
    $loop->add($server);

    $server->initialize->get;

    my $result = $server->call_tool('run', {
        command => 'echo allowed',
    })->get;

    ok( $result->{content}, 'has content' );
    is( $result->{isError}, 0, 'no error' );
    like( $result->{content}[0]{text}, qr/allowed/, 'output contains allowed text' );
};

subtest 'allowed_commands - disallowed command fails with error' => sub {
    my $server = Net::Async::MCP::Run->new(
        name             => 'test-server',
        allowed_commands => ['echo'],
    );
    $loop->add($server);

    $server->initialize->get;

    my $result = $server->call_tool('run', {
        command => 'rm -rf /',
    })->get;

    ok( $result->{content}, 'has content' );
    is( $result->{isError}, 1, 'isError is true' );
    like( $result->{content}[0]{text}, qr/Command not allowed/, 'error message about not allowed' );
};

subtest 'working_directory - command runs in specified directory' => sub {
    my $server = Net::Async::MCP::Run->new(
        name              => 'test-server',
        working_directory => '/tmp',
    );
    $loop->add($server);

    $server->initialize->get;

    my $result = $server->call_tool('run', {
        command => 'pwd',
        working_directory => '/tmp',
    })->get;

    ok( $result->{content}, 'has content' );
    is( $result->{isError}, 0, 'no error' );
    like( $result->{content}[0]{text}, qr|/tmp|, 'pwd shows /tmp' );
};

done_testing;