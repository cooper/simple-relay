#!/usr/bin/perl

use warnings;
use strict;
use feature qw(switch say);

use lib 'evented-object/lib';
use lib 'libirc/lib';

use IO::Async;
use IO::Async::Loop;

use Evented::IRC;
use Evented::IRC::Async;

say 'hi!';

###############
### OPTIONS ###
###############

my %servers = (
    valleynode => {
        nick => 'Sharon',
        user => 'sharon',
        real => 'Sharon Herget (Sharon Sherry Sheryl Shannon Shaniquia Shelly)',
        host => 'irc.valleynode.net',
        port => 6667,
        chan => ['#1lobby']
    },
    'mac-mini' => {
        nick => 'Sharon',
        user => 'sharon',
        real => 'Sharon Herget (Sharon Sherry Sheryl Shannon Shaniquia Shelly)',
        host => 'irc.mac-mini.org',
        port => 6667,
        chan => ['#k']
    },
    notrollplznet => {
        nick => 'Sharon',
        user => 'sharon',
        real => 'Sharon Herget (Sharon Sherry Sheryl Shannon Shaniquia Shelly)',
        host => 'irc.notroll.net',
        port => 6667,
        chan => ['#k']
    }
);

###################
### END OPTIONS ###
###################

my @ircs;

# set up IO::Async
my $loop = IO::Async::Loop->new();

# set up servers.
foreach my $name (keys %servers) {
    my $opts  = $servers{$name};
    my $chans = delete $opts->{chan};
    my $irc   = Evented::IRC::Async->new(%$opts);
    push @ircs, $irc;
    $irc->{server_name} = $name;
    $irc->{autojoin}    = $chans;
    $loop->add($irc);
    $irc->connect;
    
    $irc->on(privmsg => sub {
        my (undef, $who, $chan, $what) = @_;
        return unless defined $chan->{name};
        
        # send to all of the other channels on this server.
        $irc->send("PRIVMSG $_ :\2<$$who{nick} (\2$$chan{name}\2)>\2 $what") foreach grep { lc $_ ne lc $chan->{name} } @$chans;
        
        # send to other networks.
        foreach my $oirc (@ircs) {
            next if $oirc == $irc;
            $oirc->send("PRIVMSG $_ :\2<$$who{nick} (\2$name/$$chan{name}\2)>\2 $what") foreach @{$oirc->{autojoin}};
        }
        
    });
    
}

$loop->loop_forever;

1
