use inc::Module::Install;
#include 'Module::AutoInstall';

name 'Cache-Elasticache-Memcache';
all_from 'lib/Cache/Elasticache/Memcache.pm';
readme_pod_from 'lib/Cache/Elasticache/Memcache.pm';
auto_manifest;

perl_version '5.008_001';

cpanfile;

WriteAll;
