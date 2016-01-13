use inc::Module::Install;

name 'Cache-Elasticache-Memcache';
all_from 'lib/Cache/Elasticache/Memcache.pm';
auto_manifest;
readme_pod_from 'lib/Cache/Elasticache/Memcache.pm';

perl_version '5.008_001';

cpanfile;

WriteAll;
