use strict;
use warnings;
use Test::More;
use Digest::MD5;
use FindBin;
use lib "$FindBin::Bin/..";
require "HLstats_OpForIdentity.pm";

our @warnings;
sub printEvent { push @warnings, [@_]; }

{
    package TestServer;
    sub new { bless { game => "gearbox", status => $_[1], calls => 0 }, $_[0]; }
    sub dorcon {
        my ($self, $command) = @_;
        die "Unexpected command" unless $command eq "status";
        $self->{calls}++;
        return $self->{status};
    }
}

my $roster = <<'STATUS';
hostname: synthetic-test
# 1 "bot one" 397 BOT 52 10:10:32 0 0
# 2 "human two" 410 STEAM_0:1:12345 3 00:14 61 0 127.0.0.1:27005
# 3 "bot clone" 411 BOT 4 00:10 0 0
# 4 "same name" 412 STEAM_0:0:22222 0 00:12 40 0 127.0.0.1:27006
# 5 "same name" 413 BOT 0 00:12 0 0
# 6 "pending" 414 STEAM_ID_PENDING 0 00:03 40 0 127.0.0.1:27007
# 7 "zero" 415 STEAM_0:0:0 0 00:03 40 0 127.0.0.1:27007
# 8 "human \"quoted\"" 416 STEAM_0:1:33333 0 00:03 40 0 127.0.0.1:27007
STATUS
my $server = TestServer->new($roster);
is(HLstats_OpForIdentity::resolve($server, 397, "bot one", 100), "BOT", "fake client is identified by userid");
is(HLstats_OpForIdentity::resolve($server, 410, "human two", 100), "STEAM_0:1:12345", "human keeps authenticated identity");
is($server->{calls}, 1, "roster cached per server, not queried for every kill");
is(HLstats_OpForIdentity::resolve($server, 412, "same name", 101), "STEAM_0:0:22222", "human nickname collision handled");
is(HLstats_OpForIdentity::resolve($server, 413, "same name", 101), "BOT", "bot nickname collision handled");
is(HLstats_OpForIdentity::resolve($server, 414, "pending", 101), "UNKNOWN", "pending auth never guessed");
is(HLstats_OpForIdentity::resolve($server, 415, "zero", 101), "UNKNOWN", "zero Steam identity never trusted");
is(HLstats_OpForIdentity::resolve($server, 416, 'human \"quoted\"', 101), "STEAM_0:1:33333", "quoted nickname parsed");
is(HLstats_OpForIdentity::resolve($server, 397, "renamed", 101), "UNKNOWN", "stale name cannot inherit old identity");
is(HLstats_OpForIdentity::resolve($server, 999, "human two", 101), "UNKNOWN", "unknown userid not matched by nickname");
is(scalar(@warnings), 1, "unresolved identity warnings rate limited");
is(HLstats_OpForIdentity::resolve($server, 397, "bot one", 105), "BOT", "roster refreshed after five seconds");
is($server->{calls}, 2, "bounded refresh interval");
$server->{status} = "";
is(HLstats_OpForIdentity::resolve($server, 410, "human two", 110), "UNKNOWN", "failed status query discards stale roster");
is(HLstats_OpForIdentity::resolve(TestServer->new(undef), 410, "human two", 110), "UNKNOWN", "missing RCON fails closed");
is(HLstats_OpForIdentity::resolve(TestServer->new($roster), 397, "bot one", 110), "BOT", "servers have independent caches");

# Extract real parser/filter code instead of reimplementing the bot decision.
open my $source, "<", $ENV{HLSTATS_DAEMON} || "$FindBin::Bin/../hlstats.pl" or die $!;
my $text = do { local $/; <$source> };
my ($get_player) = $text =~ /(sub getPlayerInfo\s*\{.*?)(?=\n#\s*\n# hash getProperties)/s;
my ($bot_check) = $text =~ /(sub botidcheck\s*\{.*?\n\})/s;
die "Could not locate actual parser functions" unless $get_player && $bot_check;
{
    package ParserHarness;
    no strict "vars";
    no warnings "once";
    sub L4D { -1 } sub CSGO { -2 } sub CS2 { -3 }
    sub printNotice { }
    sub doEvent_Disconnect { die "Unexpected synthetic disconnect" }
}
eval "package ParserHarness; no strict 'vars'; $get_player\n$bot_check\n1;" or die $@;
{
    no strict "vars";
    no warnings "once";
    $ParserHarness::g_mode = "Normal";
    $ParserHarness::s_addr = "test:27015";
    $ParserHarness::g_servers{$ParserHarness::s_addr} = TestServer->new($roster);
    $ParserHarness::g_servers{$ParserHarness::s_addr}{play_game} = 22;
    my $bot = ParserHarness::getPlayerInfo('bot one<397><4294967295><397>', 0, "");
    my $human = ParserHarness::getPlayerInfo('human two<410><4294967295><410>', 0, "");
    my $other_bot = ParserHarness::getPlayerInfo('bot clone<411><4294967295><411>', 0, "");
    my $other_human = ParserHarness::getPlayerInfo('same name<412><4294967295><412>', 0, "");
    ok($bot->{is_bot}, "real parser marks legacy bot");
    like($bot->{uniqueid}, qr/^BOT:/, "real parser gives bots nonhuman identity");
    is($human->{uniqueid}, "1:12345", "real parser preserves normalized human SteamID");
    ok(!$human->{is_bot}, "real parser does not exclude legitimate human");
    isnt($bot->{uniqueid}, $other_bot->{uniqueid}, "bots no longer collapse into sentinel account");
    is($other_human->{uniqueid}, "0:22222", "second real human remains distinct");
    my $unknown = ParserHarness::getPlayerInfo('new human<999><4294967295><999>', 1, "");
    is($unknown->{uniqueid}, "UNKNOWN", "unresolved actor stays untrackable even when creation requested");
    my $calls = $ParserHarness::g_servers{$ParserHarness::s_addr}{calls};
    my $native = ParserHarness::getPlayerInfo('human two<410><STEAM_0:1:12345><410>', 0, "");
    is($native->{uniqueid}, "1:12345", "native OpFor SteamID bypasses resolution");
    is($ParserHarness::g_servers{$ParserHarness::s_addr}{calls}, $calls, "native identity does not query RCON");
    for my $case ([$bot,$other_bot,1,"bot kills bot"], [$human,$bot,1,"human kills bot"],
                  [$bot,$human,1,"bot kills human"], [$human,$other_human,0,"human kills human"]) {
        my ($killer,$victim,$expected,$label) = @$case;
        is(($killer->{is_bot} || $victim->{is_bot}) ? 1 : 0, $expected, $label);
    }
    $ParserHarness::g_servers{$ParserHarness::s_addr}{game} = "valve";
    my $hldm = ParserHarness::getPlayerInfo('human two<410><STEAM_0:1:12345><410>', 0, "");
    is($hldm->{uniqueid}, "1:12345", "HLDM native IDs unchanged");
    my $hldm_bot = ParserHarness::getPlayerInfo('bot one<397><BOT><397>', 0, "");
    ok($hldm_bot->{is_bot}, "existing HLDM bot detection unchanged");
}
done_testing();
