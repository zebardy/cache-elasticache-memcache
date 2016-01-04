package Cache::Elasticache::Memcache;

use fields qw(config_endpoint servers _parent _last_update _args update_period);
use Carp;
use IO::Socket::INET;
use Cache::Memcached::Fast;
use Data::Dumper::Names;

our $VERSION = '0.0.1';

sub new {
    my Cache::Elasticache::Memcache $class = shift;
    my ($conf) = @_;
    my $self = fields::new($class);

    my $args = (@_ == 1) ? shift : { @_ };  # hashref-ify args
#    print STDERR "args - ".Dumper($args)."\n";

    croak "Either config_endpoint or servers can be specifired, but not both" if (defined $args->{'config_endpoint'} && defined $args->{'servers'});

    $self->{'config_endpoint'} = delete @{$args}{'config_endpoint'};
#    print STDERR "config_endpoint: ".$self->{'config_endpoint'}."\n";

    $args->{servers} = $class->getServersFromEndpoint($self->{'config_endpoint'}) if(defined $self->{'config_endpoint'});
    $self->{_last_update} = time;
    
    $self->{servers} = $args->{servers};

    $self->{update_period} = $args->{update_period};

    $self->{'_args'} = $args;
#    print STDERR "args - ".Dumper($args)."\n";
    $self->{'_parent'} = Cache::Memcached::Fast->new($args);

    return $self;
}

sub get {
    my $self = shift;
    $self->checkServers;
    return $self->{'_parent'}->get(@_);
}

sub set {
    my $self = shift;
    $self->checkServers;
    return $self->{'_parent'}->set(@_);
}

sub replace {
    my $self = shift;
    $self->checkServers;
    return $self->{'_parent'}->replace(@_);
}

sub delete {
    my $self = shift;
    $self->checkServers;
    return $self->{'_parent'}->delete(@_);
}

sub checkServers {
    my $self = shift;
    if ( defined $args->{'config_endpoint'} && (time - $self->{_last_update}) > $self->{update_period} ) {
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
        $self->{_parent} = Cache::Memcached::Fast->new($self->{'_args'});
    }

#    print STDERR "AARON: updating state\n";

    $self->{servers} = $servers;
#    print STDERR "AARON: servers - ".Dumper($servers)."\n";
    $self->{_last_update} = time;
#    print STDERR "AARON: last_update - ".$self->{_last_update}."\n";
}

sub _hasServerListChanged {
    my $self = shift;
    my $server = shift;
#    print STDERR "AARON: _hasServerListChanged\n";
    
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
        $data .= $line;
        push(@$lines, $line);
        $count++;
        last if ( $count == 30 );
    }
    $socket->close();
    return $class->_parseConfigResponse($lines);
}

sub _parseConfigResponse {
    my $class = shift;
    my $data = shift;
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

sub DESTROY {
    my $self = shift;
}

__END__
=pod

=head1 NAME

Cache::Elasticache::Memcache

=head1 DESCRIPTION

=head1 AUTHOR

=cut

1;
