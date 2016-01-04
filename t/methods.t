use Moo;
use Test::More;
use Test::Exception;
use Test::Routini;
use Sub::Override;
use Carp;

use Cache::Elasticache::Memcache;

has test_class => (
    is => 'ro',
    lazy => 1,
    default => 'Cache::Elasticache::Memcache'
);

has parent_overrides => (
    is => 'ro',
    default => sub {
        my $self = shift;
        my $overrides = Sub::Override->new()
                                     ->replace('Cache::Memcached::Fast::new' , sub { my $object = shift; my @args = @_; $self->last_parent_object($object); $self->last_parent_args(\@args) })
                                     ->replace('Cache::Memcached::Fast::DESTROY' , sub { })
                                     ->replace('IO::Socket::INET::new', sub{ my $object = shift; my @args = @_; croak "config_endpoint:-".{@args}->{'PeerAddr'} });
        return $overrides;
    }
);

has last_parent_object => (
    is => 'rw',
    default => undef
);

has last_parent_args => (
    is => 'rw',
    default => undef,
);

test "get" => sub {
    my $self = shift;
    ok 1;
    #is $self->test_class->new()->get('test'), "deadbeef";
};

run_me;
done_testing;
1;
