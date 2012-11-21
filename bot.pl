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
    chan => ['#1lobby']
);

# second server
my %opts2 = (
    name => 'alphafaggot',
    nick => 'Sharon',
    user => 'sharon',
    real => 'Sharon Herget',
    host => 'irc.alphachat.net',
    port => 6667,
    chan => ['#1lobby', '#cooper']
);

# setup IO::Async
my $loop = IO::Async::Loop->new();

my ($name1, $name2) = (
    delete $opts1{name},
    delete $opts2{name}
);

my @chan1 = @{$opts1{chan}};
my @chan2 = @{$opts2{chan}};
delete $opts1{chan}; delete $opts2{chan};

# create IRC objects
my $irc1 = Async::IRC->new(%opts1);
my $irc2 = Async::IRC->new(%opts2);

$irc1->{server_name} = $name1;
$irc2->{server_name} = $name2;

$irc1->{autojoin} = \@chan1;
$irc2->{autojoin} = \@chan2;

$loop->add($irc1);
$loop->add($irc2);

$irc1->connect;
$irc2->connect;

#$irc1->attach_event(raw => sub { say "@_" });

$irc1->attach_event(privmsg => sub {
    my ($irc, $who, $chan, $what) = @_;
    return unless defined $chan->{name};
    $irc1->send("PRIVMSG $_ :\2<$$who{nick} (\2$$chan{name}\2)>\2 $what") foreach grep { lc $_ ne lc $chan->{name} } @chan1;
    $irc2->send("PRIVMSG $_ :\2<$$who{nick} (\2$name1\2)>\2 $what") foreach @chan2;
});

$irc2->attach_event(privmsg => sub {
    my ($irc, $who, $chan, $what) = @_;
    return unless defined $chan->{name};
    $irc2->send("PRIVMSG $_ :\2<$$who{nick} (\2$$chan{name})>\2 $what") foreach grep { lc $_ ne lc $chan->{name} } @chan2;
    $irc1->send("PRIVMSG $_ :\2<$$who{nick} (\2$name2\2)>\2 $what") foreach @chan1;
});

$loop->loop_forever;

1
