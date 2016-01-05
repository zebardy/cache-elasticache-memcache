package Cache::Elasticache::Memcache;

use strict;
use warnings;

=pod

=head1 NAME

Cache::Elasticache::Memcache

=head1 DESCRIPTION

=head1 AUTHOR

=cut

use Carp;
use IO::Socket::INET;
use Cache::Memcached::Fast;
#use Data::Dumper::Names;

our $VERSION = '0.0.2';

sub new {
    my Cache::Elasticache::Memcache $class = shift;
    my ($conf) = @_;
    my $self = bless {}, $class;

    my $args = (@_ == 1) ? shift : { @_ };  # hashref-ify args
#    print STDERR "args - ".Dumper($args)."\n";

    croak "Either config_endpoint or servers can be specifired, but not both" if (defined $args->{'config_endpoint'} && defined $args->{'servers'});

    $self->{'config_endpoint'} = delete @{$args}{'config_endpoint'};
#    print STDERR "config_endpoint: ".$self->{'config_endpoint'}."\n";

    $args->{servers} = $class->getServersFromEndpoint($self->{'config_endpoint'}) if(defined $self->{'config_endpoint'});
    $self->{_last_update} = time;

    $self->{update_period} = $args->{update_period};

    $self->{'_args'} = $args;
#    print STDERR "args - ".Dumper($args)."\n";
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
#        print STDERR "AARON: $method\n";
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

#    print STDERR "AARON: servers - ".Dumper($servers)."\n";
#    return;


    if ( $self->_hasServerListChanged($servers) ) {
#        print STDERR "AARON: server list has changed\n";
        $self->{_args}->{servers} = $servers;
        $self->{_memd} = Cache::Memcached::Fast->new($self->{'_args'});
    }

#    print STDERR "AARON: updating state\n";

    $self->{servers} = $servers;
#    print STDERR "AARON: servers - ".Dumper($servers)."\n";
    $self->{_last_update} = time;
#    print STDERR "AARON: last_update - ".$self->{_last_update}."\n";
}

sub _hasServerListChanged {
    my $self = shift;
    my $servers = shift;
#    print STDERR "AARON: _hasServerListChanged\n";

#    print STDERR "AARON: ".scalar(@$servers)." - ".scalar(@{$self->{'servers'}})."\n";
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
    my $lines = [''];
    my $data = "";
    my $count = 0;
    until ($data =~ m/END/) {
        my $line = $socket->getline();
        if (defined $line) {
            $data .= $line;
            push(@$lines, $line);
        }
        $count++;
        last if ( $count == 30 );
    }
    $socket->close();
    return $class->_parseConfigResponse($lines);
}

sub _parseConfigResponse {
    my $class = shift;
    my $data = shift;
    return [] unless (defined $data && scalar @$data);
    my $text = join('',@$data);
    my @response_lines = split(/[\r\n]+/,$text);
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

