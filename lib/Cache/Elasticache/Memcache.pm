package Cache::Elasticache::Memcache;

use fields qw(config_endpoint servers);
use Carp;
use base 'Cache::Memcached::Fast';

our $VERSION = '0.0.1';

sub new {
    my Cache::Elasticache::Memcache $class = shift;
    my ($conf) = @_;
    my $self = fields::new($class);

    my $args = (@_ == 1) ? shift : { @_ };  # hashref-ify args

    croak "Either config_endpoint ot servers can be specifired, but not both" if (defined $args->{'config_endpoint'} && defined $args->{'servers'});

    $self->{'config_endpoint'} = $args->{'config_endpoint'};

    $self->SUPER::new;

    return $self;
}

__END__
=pod

=head1 NAME

Cache::Elasticache::Memcache

=head1 DESCRIPTION

=head1 AUTHOR

=cut

1;
