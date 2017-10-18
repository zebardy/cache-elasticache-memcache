# NAME

Cache::Elasticache::Memcache - A wrapper for [Cache::Memcached::Fast](https://metacpan.org/pod/Cache::Memcached::Fast) with support for AWS's auto reconfiguration mechanism

# SYNOPSIS

    use Cache::Elasticache::Memcache;

    my $memd = new Cache::Elasticache::Memcache->new({
        config_endpoint => 'foo.bar',
        update_period => 180,
        # All other options are passed on to Cache::Memcached::Fast
        ...
    });

    # Will update the server list from the configuration endpoint
    $memd->updateServers();

    # Will update the serverlist from the configuration endpoint if the time since
    # the last time the server list was checked is greater than the update period
    # specified when the $memd object was created.
    $memd->checkServers();

    # Class method to retrieve a server list from a configuration endpoint.
    Cache::Elasticache::Memcache->getServersFromEndpoint('foo.bar');

    # All other supported methods are handled by Cache::Memcached::Fast

    # N.B. This library is currently under development

# DESCRIPTION

A wrapper for [Cache::Memcached::Fast](https://metacpan.org/pod/Cache::Memcached::Fast) with support for AWS's auto reconfiguration mechanism. It makes use of an AWS elasticache memcached cluster's configuration endpoint to discover the memcached servers in the cluster and periodically check the current server list to adapt to a changing cluster.

# UNDER DEVELOPMENT DISCLAIMER

N.B. This module is still under development. It should work, but things may change under the hood. I plan to improve the resilience with better timeout handling of communication when updating the server list. I'm toying with the idea of making the server list lookup asynchronous, however that may add a level of complexity not worth the benefits. Also I'm investigating switching to Dist::Milla. I'm open to suggestions, ideas and pull requests.

# CONSTRUCTOR

    Cache::Elasticache::Memcache->new({
        config_endpoint => 'foo.bar',
        update_period => 180,
        ...
    })

## Constructor parameters

- config\_endpoint

    AWS elasticache memcached cluster config endpoint location

- update\_period

    The minimum period (in seconds) to wait between updating the server list. Defaults to 180 seconds

# METHODS

- Supported Cache::Memcached::Fast methods

    These methods can be called on a Cache::Elasticache::Memcache object. The object will call checkServers, then the call will be passed on to the appropriate [Cache::Memcached::Fast](https://metacpan.org/pod/Cache::Memcached::Fast) code. Please see the [Cache::Memcached::Fast](https://metacpan.org/pod/Cache::Memcached::Fast) documentation for further details regarding these methods.

        $memd->enable_compress($enable)
        $memd->namespace($string)
        $memd->set($key, $value)
        $memd->set_multi([$key, $value],[$key, $value, $expiration_time])
        $memd->cas($key, $cas, $value)
        $memd->cas_multi([$key, $cas, $value],[$key, $cas, $value])
        $memd->add($key, $value)
        $memd->add_multi([$key, $value],[$key, $value])
        $memd->replace($key, $value)
        $memd->replace_multi([$key, $value],[$key, $value])
        $memd->append($key, $value)
        $memd->append_multi([$key, $value],[$key, $value])
        $memd->prepend($key, $value)
        $memd->prepend_multi([$key, $value],[$key, $value])
        $memd->get($key)
        $memd->get_multi(@keys)
        $memd->gets($key)
        $memd->gets_multi(@keys)
        $memd->incr($key)
        $memd->incr_multi(@keys)
        $memd->decr($key)
        $memd->decr_multi(@keys)
        $memd->delete($key)
        $memd->delete_multi(@keys)
        $memd->touch($key, $expiration_time)
        $memd->touch_multi([$key],[$key, $expiration_time])
        $memd->flush_all($delay)
        $memd->nowait_push()
        $memd->server_versions()
        $memd->disconnect_all()

- checkServers

        my $memd = Cache::Elasticache::Memcache->new({
            config_endpoint => 'foo.bar'
        })

        ...

        $memd->checkServers();

    Trigger the the server list to be updated if the time passed since the server list was last updated is greater than the update period (default 180 seconds).

- updateServers

        my $memd = Cache::Elasticache::Memcache->new({
            config_endpoint => 'foo.bar'
        })

        ...

        $memd->updateServers();

    This method will update the server list regardless of how much time has passed since the server list was last checked.

# CLASS METHODS

- getServersFromEndpoint

        Cache::Elasticache::Memcache->getServersFromEndpoint('foo.bar');

    This class method will retrieve the server list for a given configuration endpoint.

# BUGS

[github issues](https://github.com/zebardy/cache-elasticache-memcache/issues)

# SEE ALSO

[Cache::Memcached::Fast](https://metacpan.org/pod/Cache::Memcached::Fast) - The underlying library used to communicate with memcached servers (apart from autodiscovery)

[AWS Elasticache Memcached autodiscovery](http://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/AutoDiscovery.html) - AWS's documentation regarding elasticaches's memcached autodiscovery mechanism.

# AUTHOR

Aaron Moses

# WARRANTY

There's **NONE**, neither explicit nor implied.

# COPYRIGHT AND LICENCE

Copyright (C) 2015 Aaron Moses. All rights reserved

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.
