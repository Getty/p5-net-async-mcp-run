use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::Async::Loop;
use Future::AsyncAwait;

use Net::Async::MCP::Run;

subtest 'constructor with all parameters' => sub {
    my $server = Net::Async::MCP::Run->new(
        name             => 'test-server',
        allowed_commands => ['ls', 'cat'],
        working_directory => '/tmp',
        timeout           => 60,
        compress          => 1,
        validator         => sub { 1 },
    );

    ok( $server, 'server created' );
    is( $server->name, 'test-server', 'name is set' );
    is_deeply( $server->allowed_commands, ['ls', 'cat'], 'allowed_commands is set' );
    is( $server->working_directory, '/tmp', 'working_directory is set' );
    is( $server->timeout, 60, 'timeout is set' );
    ok( $server->compress, 'compress is set' );
    ok( $server->validator, 'validator is set' );
};

subtest 'constructor with minimal parameters' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'minimal-server',
    );

    ok( $server, 'server created with minimal params' );
    is( $server->name, 'minimal-server', 'name is set' );
};

done_testing;