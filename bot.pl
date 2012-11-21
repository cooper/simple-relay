#!/usr/bin/perl

use warnings;
use strict;
use feature qw(switch say);

use lib 'lib';
use lib 'libirc/lib';

use IO::Async;
use IO::Async::Loop;
use IRC;
use Async::IRC;

say 'hi!';

###############
### OPTIONS ###
###############

# first server
my %opts1 = (
    name => 'valleynode',
    nick => 'Sharon',
    user => 'sharon',
    real => 'Sharon Herget',
    host => 'irc.valleynode.net',
    port => 6667,
    chan => '#1lobby'
);

# second server
my %opts2 = (
    name => 'alphafaggot',
    nick => 'Sharon',
    user => 'sharon',
    real => 'Sharon Herget',
    host => 'irc.alphachat.net',
    port => 6667,
    chan => '#1lobby'
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
my $irc1 = Async::IRC->new(%opts1);
my $irc2 = Async::IRC->new(%opts2);

$irc1->{server_name} = $name1;
$irc2->{server_name} = $name2;

$irc1->{autojoin} = [$chan1];
$irc2->{autojoin} = [$chan2];

$loop->add($irc1);
$loop->add($irc2);

$irc1->connect;
$irc2->connect;

#$irc1->attach_event(raw => sub { say "@_" });

$irc1->attach_event(privmsg => sub {
    my ($irc, $who, $chan, $what) = @_;
    return unless lc $chan->{name} eq lc $chan1;
    $irc2->send("PRIVMSG $chan2 :\2<$$who{nick}>\2 $what");
});

$irc2->attach_event(privmsg => sub {
    my ($irc, $who, $chan, $what) = @_;
    return unless lc $chan->{name} eq lc $chan2;
    $irc1->send("PRIVMSG $chan1 :\2<$$who{nick}>\2 $what");
});

$loop->loop_forever;

1
