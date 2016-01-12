package Cache::Elasticache::Memcache;

use strict;
use warnings;

=pod

=begin html

<p>
    <a href="https://travis-ci.org/zebardy/cache-memcache-elasticache"><img src="https://travis-ci.org/zebardy/cache-memcache-elasticache.svg"></a>
</p>

=end html

=head1 NAME

Cache::Elasticache::Memcache - A wrapper for Cache::Memacached::Fast with support for AWS's auto reconfiguration mechanism

=head1 VERSION

0.0.2

=head1 SYNOPSIS

    use Cache::Memcache::Elasticache;

    my $memd = new Cache::Memcache::Elasticache->new({
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
    Cache::Memcache::Elasticache->getServersFromEndpoint('foo.bar');

    # All other supported methods are handled by Cache::Memcached::Fast

    This library is currently under development at best it will not do anything harmful
    DO NOT USE

=head1 DESCRIPTION

My attempt to have a perl memcache client able to make use of AWS elasticache reconfiguration. I may abandon this project, it might never work. However I'm going to see where I get to. Perhaps it might end up in something useful for others, atleast that is my hope!

=cut

use Carp;
use IO::Socket::INET;
use Cache::Memcached::Fast;

our $VERSION = '0.0.2';

=pod

=head1 CONSTRUCTOR

    Cache::Elasticache::Memcache->new({
        config_endpoint => 'foo.bar',
        update_period => 180,
        ...
    })

=head2 Constructor parameters

=head3 config_endpoint

AWS elasticache memcached cluster config endpoint locatio

=head3 update_period

The minimum period to wait between updating the server list

=cut

sub new {
    my Cache::Elasticache::Memcache $class = shift;
    my ($conf) = @_;
    my $self = bless {}, $class;

    my $args = (@_ == 1) ? shift : { @_ };  # hashref-ify args

    croak "Either config_endpoint or servers can be specifired, but not both" if (defined $args->{'config_endpoint'} && defined $args->{'servers'});

    $self->{'config_endpoint'} = delete @{$args}{'config_endpoint'};

    $args->{servers} = $class->getServersFromEndpoint($self->{'config_endpoint'}) if(defined $self->{'config_endpoint'});
    $self->{_last_update} = time;

    $self->{update_period} = $args->{update_period};

    $self->{'_args'} = $args;
    $self->{_memd} = Cache::Memcached::Fast->new($args);
    $self->{servers} = $args->{servers};

    return $self;
}

=pod

=head1 METHODS

=cut

=pod

=head2 Supported Cache::Memcached::Fast methods

These methods can be called on a Cache::Elasticache::Memcache object. The object will call checkServers, then the call will be passed on to the appropriate Cache::Memcached::Fast code. Please see the Cache::Memcached::Fast documentation for further details regarding these methods.

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

=cut

my @methods = qw(
enable_compress
namespace
set
set_multi
cas
cas_multi
add
add_multi
replace
replace_multi
append
append_multi
prepend
prepend_multi
get
get_multi
gets
gets_multi
incr
incr_multi
decr
decr_multi
delete
delete_multi
touch
touch_multi
flush_all
nowait_push
server_versions
disconnect_all
);

foreach my $method (@methods) {
    my $method_name = "Cache::Elasticache::Memcache::$method";
    no strict 'refs';
    *$method_name = sub {
        my $self = shift;
        $self->checkServers;
        return $self->{'_memd'}->$method(@_);
    };
}

=pod

=head2 checkServers

    my $memd = Cache::Elasticache::Memcache->new({
        config_endpoint => 'foo.bar'
    })

    ...

    $memd->checkServers();

Trigger the the server list to be updated if the time passed since the server list was last updated is greater than the update period (default 180 seconds).

TODO: set default value.

=cut

sub checkServers {
    my $self = shift;
    if ( defined $self->{'config_endpoint'} && (time - $self->{_last_update}) > $self->{update_period} ) {
        $self->updateServers();
    }
}

=pod

=head2 updateServers

    my $memd = Cache::Elasticache::Memcache->new({
        config_endpoint => 'foo.bar'
    })

    ...

    $memd->updateServers();

This method will update the server list regardles of how much time has passed since the server list was last checked.

=cut

sub updateServers {
    my $self = shift;

    my $servers = $self->getServersFromEndpoint($self->{'config_endpoint'});

    ## Cache::Memcached::Fast does not support updating the server list after creation
    ## Therefore we must create a new object.

    if ( $self->_hasServerListChanged($servers) ) {
        $self->{_args}->{servers} = $servers;
        $self->{_memd} = Cache::Memcached::Fast->new($self->{'_args'});
    }

    $self->{servers} = $servers;
    $self->{_last_update} = time;
}

sub _hasServerListChanged {
    my $self = shift;
    my $servers = shift;

    return 1 unless(scalar(@$servers) == scalar(@{$self->{'servers'}}));

    foreach my $server (@$servers) {
        return 1 unless ( grep { $server eq $_ } @{$self->{'servers'}} );
    }

    return 0;
}

=pod

=head1 CLASS METHODS

=head2 getServersFromEndpoint

    Cache::Elasticache::Memcache->getserversFromEndpoint('foo.bar');

This class method will retrieve the server list for a given configuration endpoint.

=cut

sub getServersFromEndpoint {
    my $class = shift;
    my $config_endpoint = shift;
    my $socket = IO::Socket::INET->new(PeerAddr => $config_endpoint, Timeout => 10, Proto => 'tcp');
    croak "Unable to connect to server: ".$config_endpoint." - $!" unless $socket;

    $socket->autoflush(1);
    $socket->send("config get cluster\r\n");
    my $data = "";
    my $count = 0;
    until ($data =~ m/END/) {
        my $line = $socket->getline();
        if (defined $line) {
            $data .= $line;
        }
        $count++;
        last if ( $count == 30 );
    }
    $socket->close();
    return $class->_parseConfigResponse($data);
}

sub _parseConfigResponse {
    my $class = shift;
    my $data = shift;
    return [] unless (defined $data && $data ne '');
    my @response_lines = split(/[\r\n]+/,$data);
    my @servers = ();
    my $node_regex = '([-.a-zA-Z0-9]+)\|(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\|(\d+)';
    foreach my $line (@response_lines) {
        if ($line =~ m/$node_regex/) {
            foreach my $node (split(' ', $line)) {
                my ($host, $ip, $port) = split('\|',$node);
                push(@servers,$ip.':'.$port);
            }
        }
    }
    return \@servers;
}

1;
__END__

=pod

=head1 BUGS

probably best if this is githubs issue system

=head1 SEE ALSO

Cache::Memcached::Fast -

AWS Elasticache Memcached autodiscovery -

=head1 AUTHOR

Aaron Moses

=head1 WARRANTY

There's b<NONE>, neither explicit nor implied.

=head1 COPYWRIGHT

Copyright (C) 2015 Aaron Moses. All rights reserved

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

