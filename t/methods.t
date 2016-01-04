use Moo;
use Test::More;
use Test::Exception;
use Test::Routini;
use Test::MockObject;
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

        my $mock_memd = Test::MockObject->new();
        $mock_memd->mock('get', sub { return 'deadbeef' if ($_[1] eq 'test') });
        $mock_memd->mock('set', sub { return 0 unless ($_[1] eq 'test' && $_[2] eq 'deadbeef') });
        $mock_memd->mock('replace', sub { return 0 unless ($_[1] eq 'hello' && $_[2] eq 'deadbeef') });
        $mock_memd->mock('delete', sub { return 0 unless ($_[1] eq 'test') });

        my $mock_inet = Test::MockObject->new();
        $mock_inet->mock('autoflush', sub { return 1 });
        $mock_inet->mock('send', sub { return 1 });
        my @lines = ("\nmycluster.0001.cache.amazonaws.com|10.112.21.4|11211\n\r\n","END\r\n");
        $mock_inet->mock('getline', sub { return shift @lines });
        $mock_inet->mock('close', sub { return 1 });

        my $overrides = Sub::Override->new()
                                     ->replace('Cache::Memcached::Fast::new' ,
            sub {
                my $object = shift;
                my @args = @_;
                $self->last_parent_object($object);
                $self->last_parent_args(\@args);
                return $mock_memd;
            })
                                     ->replace('Cache::Memcached::Fast::DESTROY' , sub { })
                                     ->replace('IO::Socket::INET::new', sub{ my $object = shift; my @args = @_; return $mock_inet; });
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
    my $memd = $self->test_class->new(
        config_endpoint => 'dave',
        update_period => 9999999,
    );
    is $memd->get('test'), "deadbeef";
};

test "set" => sub {
    my $self = shift;
    my $memd = $self->test_class->new(
        config_endpoint => 'dave',
        update_period => 9999999,
    );
    ok $memd->set('test', "deadbeef");
};

test "replace" => sub {
    my $self = shift;
    my $memd = $self->test_class->new(
        config_endpoint => 'dave',
        update_period => 9999999,
    );
    ok $memd->replace('hello', "deadbeef");
};

test "delete" => sub {
    my $self = shift;
    my $memd = $self->test_class->new(
        config_endpoint => 'dave',
        update_period => 9999999,
    );
    ok $memd->delete('test');
};

run_me;
done_testing;
1;
