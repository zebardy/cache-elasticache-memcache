use Moo;
use Test::More;
use Test::Exception;
use Test::Routini;
use Sub::Override;

use Cache::Elasticache::Memcache;

has test_class => (
    is => 'ro',
    lazy => 1,
    default => 'Cache::Elasticache::Memcache'
);

has parent_overrides => (
    is => 'ro',
    default => sub {
        my $overrides = Sub::Override->new()
                                     ->replace('Cache::Memcached::Fast::new' , sub { my $class = shift; my @args = @_ })
                                     ->replace('Cache::Memcached::Fast::DESTROY' , sub { });
        return $overrides;
    }
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
    isa_ok $self->test_class->new( config_endpoint => 'test.lwgyhw.cfg.usw2.cache.amazonaws.com:11211' ), $self->test_class;
    is $self->test_class->new( config_endpoint => 'test.lwgyhw.cfg.usw2.cache.amazonaws.com:11211' )->{'config_endpoint'}, 'test.lwgyhw.cfg.usw2.cache.amazonaws.com:11211';
    isa_ok $self->test_class->new( servers => ['test'] ), $self->test_class;
    dies_ok { $self->test_class->new( servers => ['test'], config_endpoint => 'test.lwgyhw.cfg.usw2.cache.amazonaws.com:11211' ) };
};

run_me;
done_testing;
1;
