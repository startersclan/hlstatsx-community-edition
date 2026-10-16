use strict;
use warnings;
use Test::More;
use Time::Local;
use FindBin;

open my $source, "<", $ENV{HLSTATS_DAEMON} || "$FindBin::Bin/../hlstats.pl" or die $!;
my $text = do { local $/; <$source> };
my ($parser) = $text =~ /(\t\tif \(\$s_output =~ s\/\^\(\?:\.\*\?\)\?L .*?)(?=\n\t\tif \(\$g_debug >= 4\))/s;
die "Could not locate the real timestamp parser" unless $parser;
our @notices;
our $test_date_format;
sub printEvent { push @notices, [@_]; }

my $run = eval(q~
    sub {
        my ($use_timestamp, $stdin, @packets) = @_;
        my @accepted;
        my ($ev_month, $ev_day, $ev_year, $ev_hour, $ev_min, $ev_sec, $ev_time);
        my $ev_remotetime = 123;
        my $ev_unixtime = 456;
        my $ev_daemontime = 789;
        my $ev_timestamp = "unchanged";
        my $g_timestamp = $use_timestamp;
        my $g_stdin = $stdin;
        my $s_addr = "synthetic";
        my %g_config_servers = (
            synthetic => { LogDateFormat => $main::test_date_format }
        );
        for my $s_output (@packets) {
    ~ . $parser . q~
            push @accepted, {
                body => $s_output, remote => $ev_remotetime,
                timestamp => $ev_timestamp, unix => $ev_unixtime,
                daemon => $ev_daemontime
            };
        }
        return \@accepted;
    }
~);
die $@ unless $run;

my $valid = 'L 10/16/2026 - 06:26:30: World triggered "Round_Start"';
my $body = 'World triggered "Round_Start"';
my $expected = timelocal(30, 26, 6, 16, 9, 2026);
my $ordinary = $run->(0, 0, $valid);
is(scalar(@$ordinary), 1, "valid line accepted");
is($ordinary->[0]{body}, $body, "timestamp removed without changing event");
is($ordinary->[0]{remote}, $expected, "valid local-time conversion unchanged");
is($ordinary->[0]{unix}, 456, "server time does not override receipt-time mode");
is($ordinary->[0]{timestamp}, "unchanged", "formatted timestamp behavior preserved");
my $replay = $run->(1, 1, $valid);
is($replay->[0]{unix}, $expected, "timestamp mode preserves event time");
is($replay->[0]{daemon}, $expected, "stdin replay preserves event time");
is($replay->[0]{timestamp}, "2026-10-16 06:26:30", "timestamp formatting preserved");

for my $invalid (
    "15/10/2026 - 06:26:30", # Observed Month '14' after zero-based conversion.
    "00/16/2026 - 06:26:30",
    "13/16/2026 - 06:26:30",
    "10/00/2026 - 06:26:30",
    "10/32/2026 - 06:26:30",
    "02/29/2025 - 06:26:30",
    "02/30/2024 - 06:26:30",
    "04/31/2026 - 06:26:30",
    "10/16/2026 - 24:26:30",
    "10/16/2026 - 06:60:30",
    "10/16/2026 - 06:26:60",
) {
    @notices = ();
    my $result = $run->(1, 0, $valid, "L $invalid: ignored-invalid-payload", $valid);
    is(scalar(@$result), 2, "$invalid skipped without killing the loop");
    is($result->[1]{remote}, $expected, "next valid event still parsed");
    is(scalar(@notices), 1, "invalid timestamp reported once");
    is($notices[0][0], 998, "existing malformed-data code used");
    unlike($notices[0][1], qr/ignored-invalid-payload/, "diagnostic omits private event body");
}
my $leap = $run->(0, 0, 'L 02/29/2024 - 00:00:00: leap');
is(scalar(@$leap), 1, "valid leap day accepted");
my $epoch = $run->(0, 0, 'L 01/01/1970 - 00:00:00: epoch');
is(scalar(@$epoch), 1, "zero-valued epoch accepted");
SKIP: {
    skip "This source branch does not accept fractional log timestamps", 1
        if index($parser, '\.?(\d\d\d)?') < 0;
    my $fraction = $run->(0, 0, 'L 10/16/2026 - 06:26:30.123 - fractional');
    is($fraction->[0]{body}, "fractional", "existing millisecond log support preserved");
}
my $prefixed = $run->(0, 0, "\xff\xff\xff\xfflog ".$valid);
is($prefixed->[0]{body}, $body, "existing UDP log framing supported");
@notices = ();
is(scalar(@{$run->(0, 0, "no timestamp", $valid)}), 1, "ordinary malformed line skipped");
is($notices[0][0], 998, "ordinary malformed data reporting retained");

$test_date_format = "DD/MM/YYYY";
my $european = $run->(1, 0, 'L 16/10/2026 - 06:26:30: european');
is($european->[0]{remote}, $expected, "explicit day-first date accepted");
is($european->[0]{timestamp}, "2026-10-16 06:26:30", "day-first date normalized for storage");
my $ambiguous = $run->(1, 0, 'L 03/04/2026 - 06:26:30: ambiguous');
is($ambiguous->[0]{timestamp}, "2026-04-03 06:26:30", "explicit format resolves ambiguous date without guessing");
is(scalar(@{$run->(0, 0, 'L 29/02/2024 - 00:00:00: leap')}), 1, "valid day-first leap day accepted");
@notices = ();
is(scalar(@{$run->(0, 0, 'L 31/04/2026 - 00:00:00: invalid', 'L 16/10/2026 - 06:26:30: valid')}), 1,
   "invalid day-first date skipped and following event processed");
is($notices[0][0], 998, "invalid day-first calendar field reported");
$test_date_format = "MM/DD/YYYY";
is($run->(1, 0, 'L 03/04/2026 - 06:26:30: month-first')->[0]{timestamp},
   "2026-03-04 06:26:30", "explicit month-first format remains unchanged");
for my $invalid_format ("YYYY/MM/DD", "") {
    $test_date_format = $invalid_format;
    @notices = ();
    is(scalar(@{$run->(0, 0, $valid)}), 0, "invalid format configuration never silently guesses");
    like($notices[0][1], qr/INVALID LogDateFormat/, "invalid format configuration is visible");
}
done_testing();
