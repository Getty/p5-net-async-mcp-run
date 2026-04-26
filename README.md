# NAME

Net::Async::MCP::Server - Async MCP server for command execution

# SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::MCP::Server;

    my $loop = IO::Async::Loop->new;

    my $server = Net::Async::MCP::Server->new(
        name             => 'command-runner',
        allowed_commands => ['ls', 'cat', 'grep'],
        working_directory => '/tmp',
        timeout           => 30,
        compress          => 1,
    );

    $loop->add($server);

    async sub main {
        await $server->initialize;

        my $tools = await $server->list_tools;
        # [{name => 'run', description => '...', inputSchema => {...}}]

        my $result = await $server->call_tool('run', {
            command => 'ls -la',
            working_directory => '/tmp',
            timeout => 10,
        });
        # {content => [{type => 'text', text => '...'}], isError => 0}
    }

    main()->get;

# DESCRIPTION

L<Net::Async::MCP::Server> is an asynchronous MCP (Model Context Protocol) server
for command execution, built on L<IO::Async> and L<Future::AsyncAwait>.

Extends L<Net::Async::MCP> to act as an MCP server (not client) that exposes a
C<run> tool for command execution. The async counterpart to L<MCP::Run::Bash>.

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

Enable output compression via L<MCP::Run::Compress>. When enabled, command
output is filtered through compression filters before returning to the client.

    $server->compress(1);

## validator

Coderef that validates a command before execution.

    $server->validator(sub ($cmd, $dir) {
        return 1 if $cmd =~ /^ls|^cat|^grep/;
        return "blocked by policy";
    });

# METHODS

## async method initialize()

Performs MCP server initialization. Handles the C<initialize> request from the
client, sends server info and capabilities, registers the 'run' tool.

## async method list_tools()

Returns ArrayRef of tool definitions. Returns the registered 'run' tool.

## async method call_tool($name, $arguments)

Calls the specified tool with arguments. For the 'run' tool:

    my $result = await $server->call_tool('run', {
        command => 'ls -la',
        working_directory => '/tmp',
        timeout => 10,
    });

## run_stdio class method

Convenience constructor that creates a server and runs it in stdio mode.

    Net::Async::MCP::Server->run_stdio(name => 'my-server');

# SEE ALSO

L<Net::Async::MCP>, L<MCP>, L<MCP::Server>, L<MCP::Run>, L<MCP::Run::Bash>.

# AUTHOR

Torsten Raudssus L<https://raudssus.de/>

# COPYRIGHT

Copyright 2026 Torsten Raudssus

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.