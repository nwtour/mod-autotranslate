
$|=1;

use strict;

use Data::Dumper;
use File::Slurp qw(read_file write_file);
use JSON qw(from_json to_json);
use Getopt::Long;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);
use Storable qw(dclone);

my ($lang, $po, $translate_exe, $silent) = ("", "", "", 0);

GetOptions ("po=s" => \$po, "lang=s" => \$lang, "translate-shell=s" => \$translate_exe, "silent" => \$silent);

my $release = catfile ($Bin, 'json', join ('', $po . '.json'));
my $devel   = catfile ($Bin, 'json', join ('', $lang, '.', $po . '.json'));
my $output  = catfile ($Bin, 'json', join ('', $lang, '.', $po . '.translations.json'));


print "Input files: $release $devel\n";
print "Output file: $output\n";

if (! -e $release || ! -e $devel || ! -f $translate_exe) {

	die "Usage: translate.pl --lang=<LANG NAME> --po=<PO_NAME> --translate-shell=<PATH TO TRANSLATE SHELL> [--silent]\n\texample --lang=sr --po=engine --translate-shell=/usr/local/bin/trans\n";
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
	if ($string =~ /\\\\n/) {

		print "\tSpecial symbols in $string\n";
		$string =~ s/(\\\\n)/_LALALA_/;
		return ("\\\\n", $string);
	}
	if ($string =~ /\\n/) {

		print "\tSpecial symbols in $string\n";
		$string =~ s/(\\n)/_LALALA_/;
		return ("\\n", $string);
	}
	if ($string =~ /\[color=\\\\\\"([a-zA-Z]+)\\\\\\"\]/) {

		my $color = $1;
		print "\tSpecial symbols in $string\n";
		$string =~ s/(\[color=\\\\\\"[a-zA-Z]+\\\\\\"\])/_LALALA_/;
		return ("[color=\\\\\\\"$color\\\\\\\"]", $string);
	}
	if ($string =~ /\[font=\\"([-a-z0-9]+)\\"\]/) {

		my $font = $1;
		print "\tSpecial symbols in $string\n";
		$string =~ s/(\[font=\\"[-a-z0-9]+\\"\])/_LALALA_/;
		return ("[font=\\\"$font\\\"]", $string);
	}
	if ($string =~ /\[\/font\]/) {

		print "\tSpecial symbols in $string\n";
		$string =~ s/(\[\/font\])/_LALALA_/;
		return ("[\/font]", $string);
	}
	if ($string =~ /%\(([a-zA-Z0-9_]+)\)s/) {

		my $varname = $1;
		print "\tSpecial symbols in $string\n";
		$string =~ s/(%\([a-zA-Z0-9_]+\)s)/_LALALA_/;
		return (" %($varname)s ", $string);
	}
	if ($string =~ /\\\\\[/) {

		print "\tSpecial symbols in $string\n";
		$string =~ s/(\\\\\[)/_LALALA_/;
		return ("\\\\[", $string);
	}
	if ($string =~ /hotkey\.([\.a-z0-9]+)/) {

		my $hotkey = $1;
		print "\tSpecial symbols in $string\n";
		$string =~ s/hotkey\.([\.a-z0-9]+)/_LALALA_/;
		return (" hotkey.$hotkey ", $string);
	}
	return ('', $string);
}

foreach my $md5 (keys %{$release}) {

	my $ingame = (exists $devel->{$md5} && $devel->{$md5}{translation} ? $devel->{$md5}{translation} : "");

	if ($ingame) {

		print "$md5 = $ingame (translation already in game)\n" if ! $silent;
		next;
	}

	my $queue = (exists $result->{$md5} && $result->{$md5}{translation} ? $result->{$md5}{translation} : "");

	if ($queue) {

		print "$md5 = $queue (already translated)\n" if ! $silent;
		next;
	}

	my $english = ${ dclone (\$devel->{$md5}{english}) };

	if (! $english) {

		print "$md5 is null english\n";
		next;
	}

	my @change;
	my ($substring, $english) = special_symbols ($english);

	while ($substring) {

		push @change, $substring;
		($substring, $english) = special_symbols ($english);
	}

	my $translation = "";

	if ($english =~ /_LALALA_/) {

		my @substrings = split ('_LALALA_', $english);
		my @translated_substrings;
		foreach my $substring (@substrings) {

			my $translated_substring = $substring;

			if ($substring && $substring =~ /[a-zA-Z]+/) {

				print "\tAlphabet string '$substring'\n";
				$translated_substring = run_translate ($substring);
				sleep (10);
			}

			push @translated_substrings, $translated_substring;
			print "\tTranslate substring: $english = '$translated_substring'\n";
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

