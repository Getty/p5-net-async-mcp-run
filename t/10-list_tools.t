use strict;
use warnings;
use Test::More;
use IO::Async::Loop;

use Net::Async::MCP::Run;

my $loop = IO::Async::Loop->new;

subtest 'list_tools returns run tool definition' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    $server->initialize->get;

    my $tools = $server->list_tools->get;

    is( scalar @$tools, 1, 'one tool registered' );
    is( $tools->[0]{name}, 'run', 'tool name is run' );
    like( $tools->[0]{description}, qr/execute/i, 'tool has description' );
    ok( $tools->[0]{inputSchema}, 'has inputSchema' );
    is( $tools->[0]{inputSchema}{required}[0], 'command', 'command is required' );
};

done_testing;