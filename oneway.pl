#!/usr/bin/perl

use warnings;
use strict;
use feature qw(switch say);

use lib 'lib';
use lib 'evented-object';
use lib 'libirc/lib';

use IO::Async;
use IO::Async::Loop;
use IRC;
use IRC::Async;

say 'hi!';

###############
### OPTIONS ###
###############

# first server - the one the messages will be relayed TO.
my %opts1 = (
    name => 'valleynode',
    nick => 'relay-to',
    user => 'sharon',
    real => 'Sharon Herget',
    host => 'irc.valleynode.net',
    port => 6667,
    chan => '#test2'
);

# second server - messages will be relayed FROM here.
my %opts2 = (
    name => 'valleynode2',
    pass => 'p@55w0rd',
    nick => 'relay-from',
    user => 'sharon',
    real => 'Sharon Herget',
    host => 'irc.valleynode.net',
    port => 6667,
    chan => '#test1'
);

# setup IO::Async
my $loop = IO::Async::Loop->new();

my ($name1, $name2, $chan1, $chan2) = (
    delete $opts1{name},
    delete $opts2{name},
    delete $opts1{chan},
    delete $opts2{chan}
);

# create IRC objects
my $irc1 = IRC::Async->new(%opts1);
my $irc2 = IRC::Async->new(%opts2);

$irc1->{server_name} = $name1;
$irc2->{server_name} = $name2;

$irc1->{autojoin} = [$chan1];
$irc2->{autojoin} = [$chan2];

$loop->add($irc1);
$loop->add($irc2);

$irc1->connect;
$irc2->connect;


# add PRIVMSG event handler.
$irc2->attach_event(privmsg => sub {
    my ($irc, $who, $chan, $what) = @_;
    return if !$chan || ref $chan ne 'IRC::Channel';
    my $channel = $irc1->new_channel_from_name($chan1);
    $channel->send_privmsg("\2<$$who{nick}>\2 $what");
});

$loop->loop_forever;

1
