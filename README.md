# NAME

Net::Async::MCP::Run - Async MCP server with command execution

# SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::MCP::Run;
    use Net::Async::MCP::Server::Transport::Stdio;

    my $loop = IO::Async::Loop->new;

    my $server = Net::Async::MCP::Run->new(
        name             => 'command-runner',
        allowed_commands => ['ls', 'cat', 'grep'],
        working_directory => '/tmp',
        timeout           => 30,
        compress          => 1,
    );

    $loop->add($server);

    Net::Async::MCP::Server::Transport::Stdio->new(
        server => $server,
    )->handle_requests;

# DESCRIPTION

L<Net::Async::MCP::Run> is an asynchronous MCP server that exposes a C<run> tool
for command execution. Built on L<IO::Async> and L<Future::AsyncAwait>.

Extends L<Net::Async::MCP::Server> with a command execution tool.

# ATTRIBUTES

## name (required)

The server name exposed via MCP protocol.

## allowed_commands

ArrayRef of command names (first words) that are permitted. Commands not in
this list are rejected with an error result.

    $server->allowed_commands(['ls', 'cat', 'grep']);

## working_directory

Default working directory for command execution. Can be overridden per-invocation.

    $server->working_directory('/var/data');

## timeout

Default timeout in seconds. Defaults to 30.

    $server->timeout(60);

## compress

Enable output compression via L<MCP::Run::Compress>.

## validator

Coderef that validates a command before execution.

    $server->validator(sub ($cmd, $dir) {
        return 1 if $cmd =~ /^ls|^cat|^grep/;
        return "blocked by policy";
    });

# METHODS

## async method initialize()

Performs MCP server initialization.

## async method list_tools()

Returns ArrayRef containing the 'run' tool definition.

## async method call_tool($name, $arguments)

Executes the specified tool. For 'run' tool:

    my $result = await $server->call_tool('run', {
        command => 'ls -la',
        working_directory => '/tmp',
        timeout => 10,
    });

## run_stdio class method

Convenience constructor that creates a server and runs it in stdio mode.

    Net::Async::MCP::Run->run_stdio(name => 'my-server');

# SEE ALSO

L<Net::Async::MCP::Server>, L<IO::Async::Notifier>, L<Future::AsyncAwait>.

# AUTHOR

Torsten Raudssus L<https://raudssus.de/>

# COPYRIGHT

Copyright 2026 Torsten Raudssus

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
test
test
hook test
test
test2
live test
add test
test ohne co-authored
real test
real test ohne co
final test
