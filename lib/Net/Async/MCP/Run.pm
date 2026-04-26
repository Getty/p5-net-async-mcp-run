package Net::Async::MCP::Run;
# ABSTRACT: Async MCP server with command execution

use strict;
use warnings;

use parent 'Net::Async::MCP::Server';

use IO::Async::Process;
use IO::Async::Timer::Countdown;
use Future::AsyncAwait;

our $VERSION = '0.001';

=head1 SYNOPSIS

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

=head1 DESCRIPTION

L<Net::Async::MCP::Run> is an asynchronous MCP server that exposes a C<run> tool
for command execution. Built on L<IO::Async> and L<Future::AsyncAwait>.

Extends L<Net::Async::MCP::Server> with a command execution tool.

=cut

use MCP::Run::Compress;

sub _init {
    my ( $self, $params ) = @_;

    $self->SUPER::_init($params);

    $self->{allowed_commands}   //= [];
    $self->{timeout}            //= 30;
    $self->{compress}           //= 0;
    $self->{_compressor}        = MCP::Run::Compress->new;

    $self->_register_run_tool;
}

sub configure {
    my ( $self, %params ) = @_;

    for my $key (qw( allowed_commands working_directory timeout compress validator name )) {
        $self->{$key} = delete $params{$key} if exists $params{$key};
    }

    $self->SUPER::configure(%params);
}

sub allowed_commands { shift->{allowed_commands} }
sub working_directory { shift->{working_directory} }
sub timeout { shift->{timeout} }
sub compress { shift->{compress} }
sub validator { shift->{validator} }

sub _build_capabilities {
    my ( $self ) = @_;
    return { tools => {} };
}

sub _register_run_tool {
    my ( $self ) = @_;
    $self->register_tool(
        name        => 'run',
        description => 'Execute a command and return stdout, stderr, and exit code',
        inputSchema => {
            type       => 'object',
            properties => {
                command => {
                    type        => 'string',
                    description => 'The command to execute',
                },
                working_directory => {
                    type        => 'string',
                    description => 'Working directory',
                },
                timeout => {
                    type        => 'integer',
                    description => 'Timeout in seconds',
                },
                compress => {
                    type        => 'boolean',
                    description => 'Compress output',
                },
            },
            required => ['command'],
        },
        code => sub { $self->_handle_run(@_) },
    );
}

async sub call_tool {
    my ( $self, $name, $arguments ) = @_;

    if ( $name eq 'run' ) {
        return await $self->_handle_run( $name, $arguments );
    }

    die "Unknown tool: $name";
}

async sub _handle_run {
    my ( $self, $tool, $arguments ) = @_;

    my $command = $arguments->{command};
    my $dir     = $arguments->{working_directory} // $self->working_directory;
    my $to      = $arguments->{timeout}    // $self->timeout;
    my $comp    = $arguments->{compress}  // $self->compress;

    my $validation = $self->_validate_command( $command, $dir );
    if ( $validation ne '1' ) {
        return {
            content => [{ type => 'text', text => $validation // 'Command not allowed' }],
            isError => 1,
        };
    }

    my $result = await $self->_execute_command( $command, $dir, $to );

    return $self->_format_result( $result, $comp );
}

sub _validate_command {
    my ( $self, $command, $working_directory ) = @_;

    if ( @{ $self->allowed_commands } > 0 ) {
        my $program = ( split /\s+/, $command )[0];
        my $allowed = 0;
        for my $allowed_cmd ( @{ $self->allowed_commands } ) {
            if ( $program eq $allowed_cmd ) {
                $allowed = 1;
                last;
            }
        }
        unless ($allowed) {
            return "Command not allowed: $program";
        }
    }

    if ( $self->validator ) {
        my $result = $self->validator->( $command, $working_directory );
        return $result if defined $result;
        return 'Command blocked by validator';
    }

    return '1';
}

async sub _execute_command {
    my ( $self, $command, $working_directory, $timeout ) = @_;

    my $timed_out = 0;
    my $exit_code;
    my $stdout = '';
    my $done_future = $self->loop->new_future;

    my $full_command = $command;
    if ( defined $working_directory && length $working_directory ) {
        my $escaped = $working_directory;
        $escaped =~ s/'/'\\''/g;
        $full_command = "cd '$escaped' && $command";
    }

    my $process = IO::Async::Process->new(
        command => [ '/bin/sh', '-c', $full_command ],
        stdout  => {
            via => 'pipe_read',
            on_read => sub {
                my ( $stream, $buffref, $eof ) = @_;
                $stdout .= $$buffref;
                $$buffref = '';
                return 0;
            },
        },
        on_finish => sub {
            my ( $pid, $status ) = @_;
            $exit_code = $status >> 8;
            $done_future->done($exit_code) unless $done_future->is_ready;
        },
    );

    my $timer = IO::Async::Timer::Countdown->new(
        delay => $timeout,
        on_expire => sub {
            $timed_out = 1;
            $process->kill('TERM');
        },
    );

    $self->add_child( $process );
    $self->add_child( $timer );
    $timer->start;

    await $done_future;

    $timer->stop;
    $self->remove_child( $timer );
    $self->remove_child( $process );

    if ( $timed_out ) {
        return {
            exit_code => 124,
            stdout    => '',
            stderr    => '',
            error     => "Command timed out after ${timeout}s",
        };
    }

    chomp $stdout;

    return {
        exit_code => $exit_code // 0,
        stdout    => $stdout,
        stderr    => '',
        error     => undef,
    };
}

sub _format_result {
    my ( $self, $result, $compress ) = @_;

    my ( $stdout, $stderr ) = ( $result->{stdout} // '', $result->{stderr} // '' );

    if ( $compress ) {
        ( $stdout, $stderr ) = $self->{_compressor}->compress( $result->{command} // '', $stdout, $stderr );
    }

    my $output = "Exit code: $result->{exit_code}\n\n=== STDOUT ===\n$stdout";
    $output .= "\n\n=== STDERR ===\n$stderr" if length $stderr;

    if ( my $error = $result->{error} ) {
        $output .= "\n\n=== ERROR ===\n$error";
    }

    return {
        content => [{ type => 'text', text => $output }],
        isError => $result->{exit_code} != 0 ? 1 : 0,
    };
}

sub run_stdio {
    my ( $class, %params ) = @_;

    my $server = $class->new(%params);
    my $loop = IO::Async::Loop->new;
    $loop->add($server);

    Net::Async::MCP::Server::Transport::Stdio->new(
        server => $server,
    )->handle_requests;
}

1;

=head1 ATTRIBUTES

=head2 name (required)

The server name exposed via MCP protocol.

=head2 allowed_commands

ArrayRef of command names (first words) that are permitted. Commands not in
this list are rejected with an error result.

    $server->allowed_commands(['ls', 'cat', 'grep']);

=head2 working_directory

Default working directory for command execution. Can be overridden per-invocation.

=head2 timeout

Default timeout in seconds. Defaults to 30.

=head2 compress

Enable output compression via L<MCP::Run::Compress>.

=head2 validator

Coderef that validates a command before execution.

    $server->validator(sub ($cmd, $dir) {
        return 1 if $cmd =~ /^ls|^cat|^grep/;
        return "blocked by policy";
    });

=head1 METHODS

=head2 async method initialize()

Performs MCP server initialization.

=head2 async method list_tools()

Returns ArrayRef containing the 'run' tool definition.

=head2 async method call_tool($name, $arguments)

Executes the specified tool. For 'run' tool:

    my $result = await $server->call_tool('run', {
        command => 'ls -la',
        working_directory => '/tmp',
        timeout => 10,
    });

=head1 SEE ALSO

L<Net::Async::MCP::Server>, L<IO::Async::Notifier>, L<Future::AsyncAwait>.

=cut