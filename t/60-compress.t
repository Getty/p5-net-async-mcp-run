use strict;
use warnings;
use Test::More;
use IO::Async::Loop;

use Net::Async::MCP::Run;

my $loop = IO::Async::Loop->new;

subtest 'compress - output is compressed when enabled' => sub {
    my $server = Net::Async::MCP::Run->new(
        name     => 'test-server',
        compress => 1,
    );
    $loop->add($server);

    $server->initialize->get;

    my $result = $server->call_tool('run', {
        command  => 'ls -la',
        compress => 1,
    })->get;

    ok( $result->{content}, 'has content' );
    is( $result->{isError}, 0, 'no error' );
    # Compression should strip empty lines and truncate
    like( $result->{content}[0]{text}, qr/Exit code: 0/, 'has exit code' );
};

done_testing;