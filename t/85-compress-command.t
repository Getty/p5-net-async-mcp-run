use strict;
use warnings;
use Test::More;
use IO::Async::Loop;

use Net::Async::MCP::Run;

my $loop = IO::Async::Loop->new;

subtest '_execute_command records the executed command in its result' => sub {
    my $server = Net::Async::MCP::Run->new(
        name => 'test-server',
    );
    $loop->add($server);

    my $result = $server->_execute_command( 'echo hi', undef, 30 )->get;

    is( $result->{command}, 'echo hi', 'result carries the executed command' );
};

subtest 'compress receives the command so command-specific filters fire' => sub {
    my $server = Net::Async::MCP::Run->new(
        name     => 'test-server',
        compress => 1,
    );
    $loop->add($server);
    $server->discover->get;

    # No public API registers filters, so reach into the internal compressor.
    # This filter fires only if compress is actually handed the command: it
    # matches the printf command and strips the DROPME line from stdout. With
    # the command absent (the bug), the filter never matches and DROPME stays.
    $server->{_compressor}->register_filter(
        command              => '^printf',
        strip_lines_matching => [ qr/^DROPME$/ ],
    );

    my $result = $server->call_tool('run', {
        command  => q{printf 'keep\nDROPME\n'},
        compress => 1,
    })->get;

    is( $result->{isError}, 0, 'exit 0, not an error' );
    like( $result->{content}[0]{text}, qr/keep/, 'unmatched line survives' );
    unlike( $result->{content}[0]{text}, qr/DROPME/, 'command-matched filter stripped the line' );
};

done_testing;
