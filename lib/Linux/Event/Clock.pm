package Linux::Event::Clock;

use strict;
use warnings;

our $VERSION = '0.010';

use Carp qw(croak);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);

use constant NS_PER_S  => 1_000_000_000;
use constant NS_PER_MS => 1_000_000;
use constant NS_PER_US => 1_000;

sub new {
    my ($class, %opt) = @_;

    my $clock = $opt{clock} // 'monotonic';
    $clock eq 'monotonic'
        or croak "clock must be 'monotonic' (got '$clock')";

    my $self = bless {
        clock  => $clock,
        now_ns => 0,
        gen    => 0,
    }, $class;

    $self->tick; # prime cache
    return $self;
}

sub tick {
    my ($self) = @_;

    my $t  = clock_gettime(CLOCK_MONOTONIC);
    my $ns = int($t * NS_PER_S);

    $self->{now_ns} = $ns;
    $self->{gen}++;

    return $ns;
}

sub generation {
    my ($self) = @_;
    return $self->{gen};
}

sub now_ns {
    my ($self) = @_;
    return $self->{now_ns};
}

sub now_s {
    my ($self) = @_;
    return $self->{now_ns} / NS_PER_S;
}

sub monotonic_ns {
    my ($self) = @_;
    my $t = clock_gettime(CLOCK_MONOTONIC);
    return int($t * NS_PER_S);
}

sub deadline_after {
    my ($self, $seconds) = @_;
    defined $seconds or croak "deadline_after requires seconds";
    return $self->{now_ns} + int($seconds * NS_PER_S);
}

sub deadline_after_ms {
    my ($self, $ms) = @_;
    defined $ms or croak "deadline_after_ms requires ms";
    return $self->{now_ns} + ($ms * NS_PER_MS);
}

sub deadline_after_us {
    my ($self, $us) = @_;
    defined $us or croak "deadline_after_us requires us";
    return $self->{now_ns} + ($us * NS_PER_US);
}

sub deadline_in_ns {
    my ($self, $delta_ns) = @_;
    defined $delta_ns or croak "deadline_in_ns requires delta_ns";
    return $self->{now_ns} + $delta_ns;
}

sub expired_ns {
    my ($self, $deadline_ns) = @_;
    defined $deadline_ns or croak "expired_ns requires deadline_ns";
    return $deadline_ns <= $self->{now_ns} ? 1 : 0;
}

sub remaining_ns {
    my ($self, $deadline_ns) = @_;
    defined $deadline_ns or croak "remaining_ns requires deadline_ns";
    my $rem = $deadline_ns - $self->{now_ns};
    return $rem > 0 ? $rem : 0;
}

1;

__END__

=pod

=head1 NAME

Linux::Event::Clock - Cached monotonic time and deadline math for Linux::Event schedulers

=head1 VERSION

0.010

=head1 SYNOPSIS

  use Linux::Event::Clock;

  my $clock = Linux::Event::Clock->new;

  $clock->tick;
  my $deadline = $clock->deadline_after_ms(50);

  $clock->tick;
  my $now = $clock->now_ns;

  if ($deadline <= $now) {
      # due
  }

=head1 DESCRIPTION

Provides a cached monotonic clock with explicit refresh via C<tick>.
Intended for high-performance schedulers that perform many deadline
comparisons per loop iteration.

All deadline math is performed in integer nanoseconds.

=head1 METHODS

See source for full documentation.

=head1 AUTHOR

Joshua Day

=head1 LICENSE

Same terms as Perl itself.

=cut
