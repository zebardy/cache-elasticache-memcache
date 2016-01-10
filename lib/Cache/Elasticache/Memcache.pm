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

Cache::Elasticache::Memcache - A wrapper for Cache::Memacache::Fast with support for AWS's auto reconfiguration mechanism

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

sub checkServers {
    my $self = shift;
    if ( defined $self->{'config_endpoint'} && (time - $self->{_last_update}) > $self->{update_period} ) {
        $self->updateServers();
    }
}

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

=head1 AUTHOR

Aaron Moses

=head1 COPYWRIGHT

Copyright 2015 Aaron Moses.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

