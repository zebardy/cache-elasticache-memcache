requires 'Cache::Memcached::Fast';
requires 'Moo';
requires 'inc::Module::Install';
requires 'Module::Install::CPANfile';

on test => sub {
    requires 'Test::Routini';
};
