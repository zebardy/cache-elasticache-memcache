package Cache::Elasticache::Memcache;

use fields qw(config_endpoint servers);
use Carp;
use IO::Socket::INET;
use base 'Cache::Memcached::Fast';

our $VERSION = '0.0.1';

sub new {
    my Cache::Elasticache::Memcache $class = shift;
    my ($conf) = @_;
    my $self = fields::new($class);

    my $args = (@_ == 1) ? shift : { @_ };  # hashref-ify args

    croak "Either config_endpoint ot servers can be specifired, but not both" if (defined $args->{'config_endpoint'} && defined $args->{'servers'});

    $self->{'config_endpoint'} = $args->{'config_endpoint'};

    $args->{servers} = $class->getServersFromEndpoint($self->{'config_endpoint'}) if(defined $args->{'config_endpoint'});

    $self->SUPER::new(%$args);

    return $self;
}

sub getServersFromEndpoint {
    my $class = shift;
    my $config_endpoint = shift;
    print STDERR "config_endpoint:-"+$config_endpoint+"\n";
    print STDERR "config_endpoint:\n";
    my $socket = IO::Socket::INET->new(PeerAddr => $config_endpoint, Timeout => 10, Proto => 'tcp');
    croak "Unable to connect to server: ".$config_endpoint." - $!" unless $socket;

    $socket->autoflush(1);
    $socket->send("config get cluster\r\n");
    my $data = [''];
    unless ($data->[-1] =~ m/END/) {
        my $line = $socket->getline();
        push(@$data, $line);
    }
    $socket->close();
    return $class->_parseConfigResponse($data);
}

sub _parseConfigResponse {
    my $class = shift;
    my $response_lines = shift;
    my @servers = ();
    foreach my $line (@$response_lines) {
        if ($line =~ m/(([-.a-zA-Z0-9]+)\|(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)\|(\d+))/) {
            my $host = $1;
            my $ip = $2;
            my $port = $3;
            push(@servers,$ip+':'+$port);
        }
    }
    return \@servers;
}

__END__
=pod

=head1 NAME

Cache::Elasticache::Memcache

=head1 DESCRIPTION

=head1 AUTHOR

=cut

1;
