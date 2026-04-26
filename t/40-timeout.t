use strict;
use warnings;
use Test::More;
use IO::Async::Loop;

use Net::Async::MCP::Run;

my $loop = IO::Async::Loop->new;

subtest 'timeout - command that times out returns exit code 124' => sub {
    my $server = Net::Async::MCP::Run->new(
        name    => 'test-server',
        timeout => 1,
    );
    $loop->add($server);

    $server->initialize->get;

    my $result = $server->call_tool('run', {
        command => 'sleep 10',
        timeout => 1,
    })->get;

    ok( $result->{content}, 'has content' );
    is( $result->{isError}, 1, 'isError is true' );
    like( $result->{content}[0]{text}, qr/124/, 'exit code 124 for timeout' );
};

done_testing;