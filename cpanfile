requires 'MCP::Run';
requires 'Net::Async::MCP::Server';
requires 'IO::Async';
requires 'Future::AsyncAwait';
requires 'JSON::MaybeXS';

on test => sub {
  requires 'Test2::V0';
};

on develop => sub {
  requires 'Dist::Zilla';
  requires 'Dist::Zilla::PluginBundle::Author::GETTY';
};