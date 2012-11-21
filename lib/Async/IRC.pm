#---------------------------------------------------
# simple-relay: a very basic IRC relay bot.        |
#                                                  |
# ntirc: an insanely flexible IRC client.          |
# foxy: an insanely flexible IRC bot.              |
# Copyright (c) 2011, the NoTrollPlzNet developers |
# Copyright (c) 2012, Mitchell Cooper              |
# IRC.pm: IO::Async::Protocol for ntirc's libirc.  |
#---------------------------------------------------

# clarity-----
# | IRC.pm and Core/Async/IRC.pm are a bit confusing.
# | IRC.pm is the base of the actual IRC class/instance.
# | Core::Async::IRC is based on IRC.pm for asynchronous connections.
# | all IRC objects in ntirc should be objects of Core::Async::IRC,
# | which inherits the methods of IRC.pm.
# ------------

# events------
# | libirc (IRC.pm) is all about events.
# | IO::Async::Notifier (a base of this class) is all about events too.
# | libirc events fired with fire_event; Notifier events are fired with invoke_event.
# | the only Notifier event that ntirc visibly uses here is the on_error event,
# | which may be passed to new().
# ------------
package Async::IRC;

use strict;
use warnings;
use parent qw(IO::Async::Protocol::LineStream IRC);

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    $self->IRC::configure($opts{nick});
    $self->IRC::Handlers::apply_handlers();
    #$self->Handlers::apply_handlers();
    return $self
}

*on_read_line = *IRC::parse_data;

sub configure {
    my ($self, %args) = @_;
    foreach my $key (qw|host port nick user real|) {
        my $val = delete $args{$key} or next;
        $self->{"temp_$key"} = $val;
    }
    $self->SUPER::configure(%args);
}

sub connect {
    my ($self, %args) = @_;
    my $on_error   = delete $args{on_error} || sub { exit 1 }; # lazy

    $self->SUPER::connect(
        host             => delete $self->{temp_host},
        service          => delete $self->{temp_port} || 6667,
        on_resolve_error => $on_error,
        on_connect_error => $on_error,
        on_connected     => sub { $self->login }
    );
}

sub login {
    my $self = shift;

    # enable UTF-8
    $self->transport->configure(encoding => 'UTF-8');

    my ($nick, $user, $real) = ( delete $self->{temp_nick}, 
                                 delete $self->{temp_user},
                                 delete $self->{temp_real}  );
    $self->send("NICK $nick");
    $self->send("USER $user * * :$real");
}

sub send {
    # IRC.pm's send() isn't actually called, but we can fake it by using this IRC event.
    my $self = shift;
    $self->fire_event(send => @_);
    $self->write_line(@_);
}

1
