use strict;
use warnings;
use Test::More;
use FindBin;

open my $source, "<", $ENV{HLSTATS_EVENTS} || "$FindBin::Bin/../HLstats_EventHandlers.plib" or die $!;
my $text = do { local $/; <$source> };
my @functions = qw(
    doEvent_Connect doEvent_EnterGame doEvent_Disconnect doEvent_Clan
    doEvent_Suicide doEvent_TeamSelection doEvent_RoleSelection doEvent_ChangeName
    doEvent_Frag doEvent_PlayerPlayerAction doEvent_PlayerAction doEvent_Chat
    doEvent_Statsme doEvent_Statsme2 doEvent_Statsme_Latency doEvent_Statsme_Time
    doEvent_ApiReqestPlayerInfo
);
my @handlers;
my $tracks_suicide_death_state = 1;
for my $function (@functions) {
    my ($handler) = $text =~ /(^sub \Q$function\E\s*\{.*?^\})/ms;
    die "Could not locate actual handler $function" unless $handler;
    push @handlers, $handler;
}

{
    package MissingPlayerHarness;
    our (%players, %g_servers, $s_addr, @events, @mutations, $bonus, $streak_resets);
    sub lookupPlayer { return $players{$_[1] . "/" . $_[2]}; }
    sub getPlayerInfoString { return defined($_[0]) ? "tracked player" : "($_[1])"; }
    sub checkBonusRound { return $bonus; }
    sub recordEvent { push @events, [@_]; }
    sub endKillStreak { $streak_resets++; $_[0]{kills_per_life} = 0; }
    sub execNonQuery { die "Unexpected SQL write"; }
    sub removePlayer { die "Unexpected player removal"; }
    sub TF { -1 } sub L4D { -2 }
}
eval "package MissingPlayerHarness; no strict 'vars'; no warnings 'uninitialized';\n"
    . join("\n", @handlers) . "\n1;" or die $@;

{
    package MissingPlayerTestEntity;
    sub set {
        my ($self, $field, $value) = @_;
        push @MissingPlayerHarness::mutations, ["set", $field, $value];
        $self->{$field} = $value;
    }
    sub increment {
        my ($self, $field, $amount) = @_;
        $amount = 1 unless defined $amount;
        push @MissingPlayerHarness::mutations, ["increment", $field, $amount];
        $self->{$field} = ($self->{$field} || 0) + $amount;
    }
    sub updateDB { $_[0]{updates}++; }
}

{
    no strict "vars";
    no warnings "once";
    $MissingPlayerHarness::s_addr = "synthetic:27015";
    $MissingPlayerHarness::g_mode = "Normal";
    $MissingPlayerHarness::ev_remotetime = 100;
    $MissingPlayerHarness::g_global_chat = 0;
    $MissingPlayerHarness::bonus = 0;
    my $server = bless {
        minplayers => 1, num_trackable_players => 2, min_players_rank => 0,
        ignore_bots => 1, play_game => 0, suicide_penalty => 5,
        broadcasting_command => "", nextkillx => "", nextkillvicx => "",
    }, "MissingPlayerTestEntity";
    $MissingPlayerHarness::g_servers{$MissingPlayerHarness::s_addr} = $server;

    for my $identity ("UNKNOWN", "STEAM_ID_PENDING", "1:12345") {
        for my $case (
            ["doEvent_Connect", [999, $identity, ""]],
            ["doEvent_EnterGame", [999, $identity]],
            ["doEvent_Disconnect", [999, $identity, ""]],
            ["doEvent_Clan", [999, $identity, "synthetic"]],
            ["doEvent_Suicide", [999, $identity, "world", 0, 0, 0]],
            ["doEvent_TeamSelection", [999, $identity, "Blue"]],
            ["doEvent_RoleSelection", [999, $identity, "soldier"]],
            ["doEvent_ChangeName", [999, $identity, "new name"]],
            ["doEvent_Frag", [999, $identity, 998, "UNKNOWN", "crowbar", (0) x 7]],
            ["doEvent_PlayerPlayerAction", [999, $identity, 998, "UNKNOWN", "assist", (0) x 6]],
            ["doEvent_PlayerAction", [999, $identity, "player_spawn", 0, 0, 0]],
            ["doEvent_Chat", ["say", 999, $identity, "synthetic"]],
            ["doEvent_Statsme", [999, $identity, "crowbar", (0) x 6]],
            ["doEvent_Statsme2", [999, $identity, "crowbar", (0) x 7]],
            ["doEvent_Statsme_Latency", [999, $identity, 20]],
            ["doEvent_Statsme_Time", [999, $identity, 60]],
            ["doEvent_ApiReqestPlayerInfo", [999, $identity, 1]],
        ) {
            my ($name, $args) = @$case;
            my $function = MissingPlayerHarness->can($name) or die $name;
            @MissingPlayerHarness::events = ();
            @MissingPlayerHarness::mutations = ();
            my $result;
            my $completed = eval { $result = $function->(@$args); 1 };
            ok($completed, "$name safely handles missing $identity") or diag($@);
            is(scalar(@MissingPlayerHarness::events), 0, "missing actor receives no event credit");
            is(scalar(@MissingPlayerHarness::mutations), 0, "missing actor causes no player/server mutations");
            is(scalar(keys %MissingPlayerHarness::players), 0, "no invented player identity or placeholder");
            if ($name eq "doEvent_Suicide") {
                like($result, qr/^\(IGNORED\) NOPLAYERINFO:/, "untracked suicide uses existing visible diagnostic");
            }
        }
    }

    for my $case (
        { min => 2, count => 1, bonus => 0, reason => "NOTMINPLAYERS" },
        { min => 1, count => 2, bonus => 1, reason => "BonusRound" },
    ) {
        $server->{minplayers} = $case->{min};
        $server->{num_trackable_players} = $case->{count};
        $MissingPlayerHarness::bonus = $case->{bonus};
        @MissingPlayerHarness::events = ();
        @MissingPlayerHarness::mutations = ();
        like(MissingPlayerHarness::doEvent_Suicide(999, "UNKNOWN", "world", 0, 0, 0),
             qr/^\(IGNORED\) \Q$case->{reason}\E:/, "missing suicide preserves filter precedence");
        is(scalar(@MissingPlayerHarness::events), 0, "filtered missing suicide records nothing");
        is(scalar(@MissingPlayerHarness::mutations), 0, "filtered missing suicide changes nothing");
    }

    for my $case (
        { label => "verified human", bot => 0, min => 1, count => 2, bonus => 0, team_change => 0, reason => undef },
        { label => "ignored bot", bot => 1, min => 1, count => 2, bonus => 0, team_change => 0, reason => "BOT" },
        { label => "below minimum players", bot => 0, min => 2, count => 1, bonus => 0, team_change => 0, reason => "NOTMINPLAYERS" },
        { label => "bonus round", bot => 0, min => 1, count => 2, bonus => 1, team_change => 0, reason => "BonusRound" },
        { label => "recent team switch", bot => 0, min => 1, count => 2, bonus => 0, team_change => 99, reason => "TEAMSWITCH" },
    ) {
        my $player = bless {
            playerid => 101, userid => 1, uniqueid => "1:12345",
            is_bot => $case->{bot}, last_team_change => $case->{team_change},
            skill => 1000, kills_per_life => 2,
        }, "MissingPlayerTestEntity";
        $MissingPlayerHarness::players{"1/1:12345"} = $player;
        $server->{minplayers} = $case->{min};
        $server->{num_trackable_players} = $case->{count};
        $server->{suicides} = 0;
        $server->{total_suicides} = 0;
        $MissingPlayerHarness::bonus = $case->{bonus};
        $MissingPlayerHarness::streak_resets = 0;
        @MissingPlayerHarness::events = ();
        @MissingPlayerHarness::mutations = ();
        my $description = MissingPlayerHarness::doEvent_Suicide(1, "1:12345", "world", 10, 20, 30);
        if ($tracks_suicide_death_state) {
            is($player->{is_dead}, "1", "$case->{label}: death state still updated before scoring filters");
        } else {
            ok(!exists($player->{is_dead}), "$case->{label}: upstream death-state behavior unchanged");
        }
        if (defined $case->{reason}) {
            like($description, qr/^\(IGNORED\) \Q$case->{reason}\E:/, "$case->{label}: exclusion preserved");
            is(scalar(@MissingPlayerHarness::events), 0, "excluded suicide receives no stats credit");
            is($player->{skill}, 1000, "excluded suicide receives no skill penalty");
            is($server->{suicides}, 0, "excluded suicide does not affect server totals");
            is($MissingPlayerHarness::streak_resets, 0, "excluded suicide does not alter kill-streak behavior");
        } else {
            unlike($description, qr/IGNORED/, "verified human following missing actors is processed");
            is_deeply($MissingPlayerHarness::events[0], ["Suicides", 0, 101, "world", 10, 20, 30],
                      "human suicide preserves event type, player, weapon and coordinates");
            is(scalar(@MissingPlayerHarness::events), 1, "human suicide recorded exactly once");
            is($player->{suicides}, 1, "human suicide counter increments");
            is($player->{skill}, 995, "existing human skill penalty preserved");
            is($player->{session_suicides}, 1, "session suicide counter preserved");
            is($player->{session_skill}, -5, "session skill penalty preserved");
            is($player->{map_suicides}, 1, "map counter preserved");
            is($server->{suicides}, 1, "server suicide count preserved");
            is($server->{total_suicides}, 1, "server total count preserved");
            is($player->{updates}, 1, "human stats flushed once");
            is($MissingPlayerHarness::streak_resets, 1, "existing kill-streak handling preserved");
        }
        %MissingPlayerHarness::players = ();
    }
}
done_testing();
