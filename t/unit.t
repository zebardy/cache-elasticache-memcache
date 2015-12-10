use Moo;
use Test::More;
use Test::Routini;

use Cache::Elasticache::Memcache;

has test_class => (
    is => 'rw',
    default => 'Cache::Elasticache::Memcache'
);

test "hello world" => sub {
    my $self = shift;
    ok defined $self->test_class->VERSION;
};

run_me;
done_testing;
1;
