use inc::Module::Install;
use Module::Install::CPANfile;

name 'Cache-Elasticache-Memcache';
all_from 'lib/Cache/Elasticache/Memcache.pm';

perl_version '5.008_001';

cpanfile;

WriteAll;
