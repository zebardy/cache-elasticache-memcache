package Cache::Elasticache::Memcache;

use fields;

our $VERSION = '0.0.1';

sub new {
    my $class = shift;
    my ($conf) = @_;
    my $self = fields::new($class);

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
