requires 'perl', '5.008008';
requires 'Cache::Memcached::Fast';
requires 'IO::Socket::IP';
requires 'Carp';

#on develop => sub {
#    requires 'Dist::Milla';
#};

on test => sub {
    requires 'Test::Routini';
    requires 'Test::More';
    requires 'Test::Exception';
    requires 'Test::MockObject';
    requires 'Test::Deep';
    requires 'Sub::Override';
    requires 'Moo';
};
