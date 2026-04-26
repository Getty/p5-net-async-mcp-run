use strict;
use warnings;
use Test::More;
use IO::Async::Loop;
use JSON::MaybeXS qw( encode_json decode_json );

use Net::Async::MCP::Run;
use Net::Async::MCP::Server::Transport::Stdio;

my $loop = IO::Async::Loop->new;

subtest 'Transport::Stdio - instantiation and basic properties' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    my $transport = Net::Async::MCP::Server::Transport::Stdio->new(
        server => $server,
    );

    ok( $transport, 'transport created' );
    is( $transport->server, $server, 'server accessor works' );
};

done_testing;