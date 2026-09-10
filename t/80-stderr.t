use strict;
use warnings;
use Test::More;
use IO::Async::Loop;

use Net::Async::MCP::Run;

my $loop = IO::Async::Loop->new;

subtest 'stderr is captured and surfaced in the run result' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);
    $server->discover->get;

    my $result = $server->call_tool('run', {
        command => 'echo oops >&2',
    })->get;

    ok( $result->{content}, 'has content' );
    is( $result->{isError}, 0, 'exit 0, not an error' );
    like( $result->{content}[0]{text}, qr/=== STDERR ===/, 'STDERR section is present' );
    like( $result->{content}[0]{text}, qr/oops/, 'stderr text is captured' );
};

subtest 'stdout and stderr are both captured' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);
    $server->discover->get;

    my $result = $server->call_tool('run', {
        command => 'echo to-out; echo to-err >&2',
    })->get;

    is( $result->{isError}, 0, 'exit 0, not an error' );
    like( $result->{content}[0]{text}, qr/=== STDOUT ===\nto-out/, 'stdout captured' );
    like( $result->{content}[0]{text}, qr/=== STDERR ===\nto-err/, 'stderr captured' );
};

subtest 'no STDERR section when the command writes nothing to stderr' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);
    $server->discover->get;

    my $result = $server->call_tool('run', {
        command => 'echo only-stdout',
    })->get;

    is( $result->{isError}, 0, 'exit 0, not an error' );
    like( $result->{content}[0]{text}, qr/only-stdout/, 'stdout present' );
    unlike( $result->{content}[0]{text}, qr/=== STDERR ===/, 'no STDERR section for empty stderr' );
};

subtest '_execute_command captures stderr on the raw result' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    my $result = $server->_execute_command( 'echo raw-err >&2', undef, 30 )->get;

    is( $result->{exit_code}, 0, 'exit code 0' );
    is( $result->{stdout}, '', 'stdout empty' );
    like( $result->{stderr}, qr/raw-err/, 'raw stderr field carries the output' );
};

done_testing;
