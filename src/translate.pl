
$|=1;

use strict;

use Data::Dumper;
use File::Slurp qw(read_file write_file);
use JSON qw(from_json to_json);
use Getopt::Long;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

my ($lang, $po, $translate_exe) = ("", "", "");

GetOptions ("po=s" => \$po, "lang=s" => \$lang, "translate-shell=s" => \$translate_exe);

my $release = catfile ($Bin, 'json', join ('', $po . '.json'));
my $devel   = catfile ($Bin, 'json', join ('', $lang, '.', $po . '.json'));
my $output  = catfile ($Bin, 'json', join ('', $lang, '.', $po . '.translations.json'));


print "Input files: $release $devel\n";
print "Output file: $output\n";

if (! -e $release || ! -e $devel || ! -f $translate_exe) {

	die "Usage: translate.pl --lang=<LANG NAME> --po=<PO_NAME> --translate-shell=<PATH TO TRANSLATE SHELL>\n\texample --lang=sr --po=engine --translate-shell=/usr/local/bin/trans\n";
}

$release = from_json (read_file ($release));
$devel   = from_json (read_file ($devel));


my $result;
$result = from_json (read_file ($output)) if -e $output;

sub run_translate {
	my $string = shift;

	if ($string =~ /'/) {

		system ($translate_exe . ' -o tmp_trans.txt -b en:sr "' . $string . '"');
	}
	else {

		system ("$translate_exe -o tmp_trans.txt -b en:sr '$string'");
	}
	my $translation = read_file ("tmp_trans.txt");
	$translation =~ s/\n$//;
	return $translation;
}

foreach my $md5 (keys %{$release}) {

	my $ingame = (exists $devel->{$md5} && $devel->{$md5}{translation} ? $devel->{$md5}{translation} : "");

	if ($ingame) {

		print "$md5 = $ingame (translation already in game)\n";
		next;
	}

	my $queue = (exists $result->{$md5} && $result->{$md5}{translation} ? $result->{$md5}{translation} : "");

	if ($queue) {

		print "$md5 = $queue (already translated)\n";
		next;
	}

	my $english = $devel->{$md5}{english};

	my @list;
	my @regexp = ('%s', '%.1f', '%.3f');
	my $translation = "";
	foreach my $regex (@regexp) {

		next if $english !~ /$regex/;
		my @list = split ($regex, $english);
		my @ll;
		foreach my $substring (@list) {

			my $temp = ($substring =~ /^(\W[0-9]+)$/ ? $substring : run_translate ($substring));
			push @ll, $temp;
			print "TEMP $english $temp\n";
			sleep (30);
		}
		if (scalar (@list) == 1) {

		}
		$translation = join ($regex, @ll);
		if (scalar (@ll) == 1) {

			$translation = ($english =~ /^$regex/ ? $regex . $translation : $translation . $regex);
		}
	}

	$translation = run_translate ($english) if ! $translation;
	$result->{$md5} = {english => $english, translation => $translation};
	write_file ($output, to_json ($result, {pretty => 1, canonical => 1}));
	print "$md5 = $translation (translation result)\n";
	exit;
}

