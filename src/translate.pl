
$|=1;

use strict;

use Data::Dumper;
use File::Slurp qw(read_file write_file);
use JSON qw(from_json to_json);
use Getopt::Long;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);
use Storable qw(dclone);

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

sub special_symbols {
	my $string = shift;
	if ($string =~ /\\n/) {

		print "FOUND SUBSTRING in $string\n";
		$string =~ s/(\\n)/_LALALA_/;
		return ("\\n", $string);
	}
	if ($string =~ /\[color=\\\\\\"([a-zA-Z]+)\\\\\\"\]/) {

		my $color = $1;
		print "FOUND SUBSTRING in $string\n";
		$string =~ s/(\[color=\\\\\\"[a-zA-Z]+\\\\\\"\])/_LALALA_/;
		return ("[color=\\\\\\\"$color\\\\\\\"]", $string);
	}
	if ($string =~ /%\(([a-z_]+)\)s/) {

		my $varname = $1;
		print "FOUND SUBSTRING in $string\n";
		$string =~ s/(%\([a-z_]+\)s)/_LALALA_/;
		return (" %($varname)s ", $string);
	}
	return ('', $string);
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

	my $english = ${ dclone (\$devel->{$md5}{english}) };

	if (! $english) {

		die "$md5 is null english\n";
	}

	my @change;
	my ($substring, $english) = special_symbols ($english);

	while ($substring) {

		push @change, $substring;
		($substring, $english) = special_symbols ($english);
	}

	my $translation = "";

	my @substrings = split ('_LALALA_', $english);
	if (scalar (@substrings) > 1) {
		my @translated_substrings;
		foreach my $substring (@substrings) {

			my $translated_substring = $substring;

			if ($substring && $substring !~ /^(\W[0-9]+)$/) {

				$translated_substring = run_translate ($substring);
				sleep (30);
			}

			push @translated_substrings, $translated_substring;
			print "Translate substring: $english = '$translated_substring'\n";
		}
		my $k = 0;
		while (exists $translated_substrings[$k]) {

			$translation .= $translated_substrings[$k] . $change[$k];
			$k++;
		}
	}

	$translation = run_translate ($english) if ! $translation;
	$result->{$md5} = {english => $devel->{$md5}{english}, translation => $translation};
	write_file ($output, to_json ($result, {pretty => 1, canonical => 1}));
	print join ('', $md5, " : ", $devel->{$md5}{english}, " = ", $translation, " (translation result)\n");
	exit;
}

