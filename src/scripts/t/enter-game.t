use strict;
use warnings;
use Test::More;
use FindBin;

open my $source, "<", $ENV{HLSTATS_EVENTS} || "$FindBin::Bin/../HLstats_EventHandlers.plib" or die $!;
my $text = do { local $/; <$source> };
my ($handler) = $text =~ /(sub doEvent_EnterGame\s*\{.*?^\})/ms;
die "Could not locate the actual enter-game handler" unless $handler;

{
    package EventHarness;
    our ($current_player, @events, @lookups);
    sub lookupPlayer { push @lookups, [@_]; return $current_player; }
    sub getPlayerInfoString { return defined($_[0]) ? "tracked player" : "($_[1])"; }
    sub resolveIp { return ""; }
    sub recordEvent { push @events, [@_]; }
}
eval "package EventHarness; no strict 'vars'; $handler\n1;" or die $@;
{
    package TestPlayer;
    sub set { $_[0]{$_[1]} = $_[2]; $_[0]{set_calls}++; }
    sub updateDB { $_[0]{updates}++; }
}

{
    no strict "vars";
    no warnings "once";
    $EventHarness::s_addr = "synthetic:27015";
    $EventHarness::g_mode = "Normal";
    $EventHarness::g_stdin = 0;
    $EventHarness::g_servers{$EventHarness::s_addr} = {
        ignore_bots => 1, min_players_rank => 0, connect_announce => 0
    };
    $EventHarness::current_player = undef;
    my $description = EventHarness::doEvent_EnterGame(999, "UNKNOWN");
    like($description, qr/^\(IGNORED\) NOPLAYERINFO:/, "unresolved OpFor entry follows existing ignored path");
    is(scalar(@EventHarness::events), 0, "unresolved entry never creates a stats event");
    ok(!defined($EventHarness::current_player), "missing player is not autovivified into a fake object");
    like(EventHarness::doEvent_EnterGame(1000, "STEAM_ID_PENDING"),
         qr/^\(IGNORED\) NOPLAYERINFO:/, "other untracked identities are also safe");

    $EventHarness::current_player = bless {
        is_bot => 0, userid => 1, playerid => 101, address => "",
        connect_time => 0, country => ""
    }, "TestPlayer";
    unlike(EventHarness::doEvent_EnterGame(1, "1:12345"), qr/IGNORED/, "verified human after unresolved entry still enters");
    is($EventHarness::current_player->{set_calls}, 1, "human connection time initialized");
    is($EventHarness::current_player->{updates}, 1, "human state saved");
    is(scalar(@EventHarness::events), 1, "human entry event recorded once");
    is($EventHarness::events[0][0], "Entries", "normal entry event type preserved");

    @EventHarness::events = ();
    $EventHarness::current_player = bless {
        is_bot => 1, userid => 2, playerid => 102, connect_time => 0
    }, "TestPlayer";
    like(EventHarness::doEvent_EnterGame(2, "BOT:synthetic"), qr/^\(IGNORED\) BOT:/, "known bot remains excluded");
    is($EventHarness::current_player->{updates}, 1, "existing hidden bot placeholder state saved");
    is(scalar(@EventHarness::events), 0, "bot entry receives no stats credit");
}
done_testing();
