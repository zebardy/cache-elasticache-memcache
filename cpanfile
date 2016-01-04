requires 'Cache::Memcached::Fast';
requires 'inc::Module::Install';
requires 'Module::Install::CPANfile';
requires 'Data::Dumper::Names';

on test => sub {
    requires 'Test::Routini';
    requires 'Test::More';
    requires 'Test::Exception';
    requires 'Test::MockObject';
    requires 'Test::Deep';
    requires 'Sub::Override';
};
