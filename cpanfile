requires 'Future::AsyncAwait';
requires 'IO::Async';
requires 'JSON::MaybeXS';
requires 'MCP::Run';
requires 'Net::Async::MCP::Server';

on test => sub {
  requires 'Test2::V0';
  requires 'Test::Exception';
};

on develop => sub {
  requires 'Dist::Zilla';
};
