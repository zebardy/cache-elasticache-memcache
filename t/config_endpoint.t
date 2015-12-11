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

has endpoint_location => (
    is => 'ro',
    lazy => 1,
    default => 'test.lwgyhw.cfg.usw2.cache.amazonaws.com:11211',
);

has parent_overrides => (
    is => 'ro',
    default => sub {
        my $self = shift;
        my $overrides = Sub::Override->new()
                                     ->replace('IO::Socket::INET::new', sub{ my $object = shift; my @args = @_; croak "config_endpoint:-".{@args}->{'PeerAddr'} });
        return $overrides;
    }
);

test "happy_path" => sub {
    my $self = shift;
    TODO: {
        local $TODO = "Under development - need to mock IO::Socket::INET";
        ok 1;
        #my $result = $self->test_class->getServersFromEndpoint($self->endpoint_location);
    }
};

run_me;
done_testing;
1;
