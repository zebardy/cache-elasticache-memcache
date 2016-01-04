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

test "hello world" => sub {
    my $self = shift;
    ok defined $self->test_class->VERSION;
};

test "instantiation" => sub {
    my $self = shift;
    isa_ok $self->test_class->new(), $self->test_class;
};

test "accepts either config_endpoint or servers params but not both" => sub {
    my $self = shift;
    dies_ok { $self->test_class->new( config_endpoint => 'test.lwgyhw.cfg.usw2.cache.amazonaws.com:11211' ) };
    like $@, '/^config_endpoint:-test.lwgyhw.cfg.usw2.cache.amazonaws.com:11211/';
    isa_ok $self->test_class->new( servers => ['test'] ), $self->test_class;
    is $self->last_parent_args->[0]->{servers}->[0], 'test';
    dies_ok { $self->test_class->new( servers => ['test'], config_endpoint => 'test.lwgyhw.cfg.usw2.cache.amazonaws.com:11211' ) };
    like $@, '/Either config_endpoint or servers can be specifired, but not both/';
};

test "get" => sub {
    my $self = shift;
    is $self->test_class->new()->get('test'), "deadbeef";
};

run_me;
done_testing;
1;
