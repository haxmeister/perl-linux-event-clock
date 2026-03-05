[![CI](https://github.com/haxmeister/perl-linux-event-clock/actions/workflows/ci.yml/badge.svg)](https://github.com/haxmeister/perl-linux-event-clock/actions/workflows/ci.yml)

# Linux-Event-Clock

Cached monotonic time and deadline math for Linux::Event schedulers.

## Linux::Event Ecosystem

The Linux::Event modules are designed as a composable stack of small,
explicit components rather than a framework.

Each module has a narrow responsibility and can be combined with the others
to build event-driven applications.

Core layers:

Linux::Event
    The event loop. Linux-native readiness engine using epoll and related
    kernel facilities. Provides watchers and the dispatch loop.

Linux::Event::Listen
    Server-side socket acquisition (bind + listen + accept). Produces accepted
    nonblocking filehandles.

Linux::Event::Connect
    Client-side socket acquisition (nonblocking connect). Produces connected
    nonblocking filehandles.

Linux::Event::Stream
    Buffered I/O and backpressure management for an established filehandle.

Linux::Event::Fork
    Asynchronous child process management integrated with the event loop.

Linux::Event::Clock
    High resolution monotonic time utilities used for scheduling and deadlines.

Canonical network composition:

Listen / Connect
        ↓
      Stream
        ↓
  Application protocol

Example stack:

Linux::Event::Listen → Linux::Event::Stream → your protocol

or

Linux::Event::Connect → Linux::Event::Stream → your protocol

The core loop intentionally remains a primitive layer and does not grow
into a framework. Higher-level behavior is composed from small modules.

## Install

```sh
perl Makefile.PL
make
make test
make install
```

## Repository

https://github.com/haxmeister/perl-linux-event-clock

## License

Same terms as Perl itself.
