package Cache::Elasticache::Memcache;

use fields qw(config_endpoint servers _parent);
use Carp;
use IO::Socket::INET;
use base 'Cache::Memcached::Fast';

our $VERSION = '0.0.1';

sub new {
    my Cache::Elasticache::Memcache $class = shift;
    my ($conf) = @_;
    my $self = fields::new($class);

    my $args = (@_ == 1) ? shift : { @_ };  # hashref-ify args

    croak "Either config_endpoint or servers can be specifired, but not both" if (defined $args->{'config_endpoint'} && defined $args->{'servers'});

    $self->{'config_endpoint'} = $args->{'config_endpoint'};

    $args->{servers} = $class->getServersFromEndpoint($self->{'config_endpoint'}) if(defined $args->{'config_endpoint'});

    $self->{'_parent'} = Cache::Memcached::Fast->new($args);

    return $self;
}

sub get {
    my $self = shift;
    return $self->{'_parent'}->get(@_);
}

sub set {
    my $self = shift;
    return $self->{'_parent'}->set(@_);
}

sub replace {
    my $self = shift;
    return $self->{'_parent'}->replace(@_);
}

sub delete {
    my $self = shift;
    return $self->{'_parent'}->delete(@_);
}

sub getServersFromEndpoint {
    my $class = shift;
    my $config_endpoint = shift;
    my $socket = IO::Socket::INET->new(PeerAddr => $config_endpoint, Timeout => 10, Proto => 'tcp');
    croak "Unable to connect to server: ".$config_endpoint." - $!" unless $socket;

    $socket->autoflush(1);
    $socket->send("config get cluster\r\n");
    my $data = [''];
    until ($data->[-1] =~ m/END/) {
        my $line = $socket->getline();
        push(@$data, $line);
    }
    $socket->close();
    return $class->_parseConfigResponse($data);
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
