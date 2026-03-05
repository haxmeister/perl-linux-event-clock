package Linux::Event::Clock;

use strict;
use warnings;

our $VERSION = '0.011';

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

=head1 NAME

Linux::Event::Clock - Monotonic and realtime clocks for Linux::Event (nanoseconds)

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Clock;

  my $clock = Linux::Event::Clock->new;

  my $t0 = $clock->now_ns;
  # ... do work ...
  my $dt = $clock->now_ns - $t0;

  say "elapsed ns: $dt";

=head1 DESCRIPTION

B<Linux::Event::Clock> provides explicit access to clock time with nanosecond
precision.

It is intended as a small, dependency-light helper for:

=over 4

=item * deadline calculations (absolute times)

=item * interval measurements (durations)

=item * converting between seconds and nanoseconds without repeating constants

=back

It does not schedule timers by itself. Scheduling belongs in the loop/timer
layer (for example, C<< $loop->after(...) >>).

=head1 LAYERING

This module is a utility used by higher layers.

=over 4

=item * B<Linux::Event::Clock>

Time source + conversions.

=item * B<Linux::Event::Loop>

Scheduling and dispatch (timers, I/O readiness, signals, wakeups, pid).

=back

Clock provides time; the loop decides when to wake and dispatch.

=head1 CONSTRUCTOR

=head2 new

  my $clock = Linux::Event::Clock->new(%opt);

Creates a clock helper.

If options are supported by your version, they control which clock is used
(monotonic vs realtime). Monotonic time is preferred for durations and deadlines
because it does not jump with wall-clock changes.

=head1 METHODS

=head2 now_ns

  my $ns = $clock->now_ns;

Return the current time of the selected clock as a signed integer nanoseconds
value.

=head2 now_s

  my $s = $clock->now_s;

Return the current time as seconds (floating point). This is convenient for
human-facing code, but nanoseconds are preferred for internal scheduling and
exact arithmetic.

=head2 s_to_ns / ns_to_s

  my $ns = $clock->s_to_ns($seconds);
  my $s  = $clock->ns_to_s($nanoseconds);

Convert between seconds (float allowed) and integer nanoseconds.

=head2 sleep_until_ns (if supported)

  $clock->sleep_until_ns($deadline_ns);

Block the current thread until the specified deadline. This is not used by the
event loop (which uses timerfd); it is a utility for simple scripts/tests.

=head1 NOTES

=head2 Clock choice

Use monotonic time for measuring elapsed time and scheduling deadlines inside an
event loop. Use realtime only for wall-clock timestamps intended for humans.

=head1 SEE ALSO

L<Linux::Event> - core event loop

L<Linux::Event::Listen> - server-side socket acquisition

L<Linux::Event::Connect> - client-side socket acquisition

L<Linux::Event::Fork> - asynchronous child processes

L<Linux::Event::Clock> - high resolution monotonic clock utilities

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.

=cut
