package HLstats_OpForIdentity;
use strict;
use warnings;

sub resolve {
    my ($server, $userid, $name, $now) = @_;
    $now = time() unless defined $now;
    my $cache = $server->{opfor_auth_roster};
    if (!defined($cache) || $now < $cache->{time} || $now - $cache->{time} >= 5) {
        my $status = $server->dorcon("status");
        my %players;
        for my $line (split(/[\r\n]+/, defined($status) ? $status : "")) {
            # Status supplies real Steam IDs and BOT, even when game logs do not.
            if ($line =~ /^#\s*\d+\s+"(.*)"\s+(\d+)\s+(BOT|STEAM_\d+:[01]:\d+)\s+/) {
                my ($player_name, $id, $auth) = ($1, $2, $3);
                next if $auth =~ /^STEAM_\d+:[01]:0$/;
                $players{$id} = { name => $player_name, auth => $auth };
            }
        }
        $cache = { time => $now, players => \%players };
        $server->{opfor_auth_roster} = $cache;
    }
    my $player = $cache->{players}{$userid};
    if (defined($player) && $player->{name} eq $name) {
        return $player->{auth};
    }
    # Never guess from the shared sentinel or nickname. UNKNOWN already follows
    # HLstatsX's untrackable-identity path until a later roster refresh resolves it.
    if (!defined($server->{opfor_auth_warning}) || $now - $server->{opfor_auth_warning} >= 30) {
        main::printEvent("AUTH", "OpFor legacy userid could not be resolved; ignoring unverified activity.", 1);
        $server->{opfor_auth_warning} = $now;
    }
    return "UNKNOWN";
}

1;
