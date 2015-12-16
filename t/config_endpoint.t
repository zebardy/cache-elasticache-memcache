use Moo;
use Test::More;
use Test::Exception;
use Test::Routini;
use Sub::Override;
use Carp;
use Test::MockObject;
use Test::Deep;

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
        my $mock = Test::MockObject->new();
        $mock->mock('autoflush', sub { return 1 });
        $mock->mock('send', sub { return 1 });
        my $text = "CONFIG cluster 0 141\r\n12\nmycluster.0001.cache.amazonaws.com|10.112.21.1|11211 mycluster.0002.cache.amazonaws.com|10.112.21.2|11211 mycluster.0003.cache.amazonaws.com|10.112.21.3|11211\n\r\nEND\r\n";
        my @lines = unpack("(A16)*", $text);
        $mock->mock('getline', sub { return shift @lines });
        $mock->mock('close', sub { return 1 });
        my $overrides = Sub::Override->new()
                                     ->replace('IO::Socket::INET::new',
            sub{
                my $object = shift;
                my @args = @_;
                return $mock if ({@args}->{'PeerAddr'} eq $self->endpoint_location);
                croak "GAAAAAAAA";
            });
        return $overrides;
    }
);

test "happy_path" => sub {
    my $self = shift;
    my $result = $self->test_class->getServersFromEndpoint($self->endpoint_location);
    cmp_deeply( $result, ['10.112.21.1:11211','10.112.21.2:11211', '10.112.21.3:11211'] );
};

run_me;
done_testing;
1;
