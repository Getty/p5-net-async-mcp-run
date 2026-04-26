use strict;
use warnings;
use Test::More;
use IO::Async::Loop;

use Net::Async::MCP::Run;

my $loop = IO::Async::Loop->new;

subtest 'validator - returns 1 (allowed)' => sub {
    my $server = Net::Async::MCP::Run->new(
        name      => 'test-server',
        validator => sub { 1 },
    );
    $loop->add($server);

    $server->initialize->get;

    my $result = $server->call_tool('run', {
        command => 'echo validated',
    })->get;

    ok( $result->{content}, 'has content' );
    is( $result->{isError}, 0, 'no error' );
    like( $result->{content}[0]{text}, qr/validated/, 'output contains validated text' );
};

subtest 'validator - returns string (denied with reason)' => sub {
    my $server = Net::Async::MCP::Run->new(
        name      => 'test-server',
        validator => sub { 'blocked by policy: no deleting files' },
    );
    $loop->add($server);

    $server->initialize->get;

    my $result = $server->call_tool('run', {
        command => 'echo this should be blocked',
    })->get;

    ok( $result->{content}, 'has content' );
    is( $result->{isError}, 1, 'isError is true' );
    like( $result->{content}[0]{text}, qr/blocked by policy/, 'error message contains reason' );
};

subtest 'validator - returns undef (denied without reason)' => sub {
    my $server = Net::Async::MCP::Run->new(
        name      => 'test-server',
        validator => sub { undef },
    );
    $loop->add($server);

    $server->initialize->get;

    my $result = $server->call_tool('run', {
        command => 'echo this should be blocked',
    })->get;

    ok( $result->{content}, 'has content' );
    is( $result->{isError}, 1, 'isError is true' );
    like( $result->{content}[0]{text}, qr/Command blocked/, 'error message about being blocked' );
};

done_testing;