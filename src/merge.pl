
use strict;

use Data::Dumper;
use File::Slurp qw(read_file write_file);
use JSON qw(from_json to_json);
use Digest::MD5::File qw(md5_hex);
use Getopt::Long;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

my ($lang, $po) = ("", "");

GetOptions ("lang=s" => \$lang, "po=s" => \$po);

die "Usage: merge.pl --lang=<LANG NAME> --po=<PO_FILENAME>\n\texample: --lang=sr --po=public-gui-campaigns\n" if ! $lang || ! $po;

my $input  = catfile ($Bin, 'A25B', join('', $lang, '.', $po, '.po'));
my $output = catfile ($Bin, '..', 'l10n', join('', $lang, '.', $po, '.po'));

print "Input file: $input\n";

my @strings = read_file ($input);
my @output_strings;

my $translations = from_json (read_file (catfile ($Bin, 'json', $lang . '.' . $po . '.translations.json')));

my $i = 0;
while (exists $strings[$i]) {

	if ($strings[$i] !~ /^msgstr\s""/) {

		push @output_strings, $strings[$i];
		$i++;
		next;
	}

	my $found = 0;
	foreach my $minus (1, 2, 3, 4) {

		if ($strings[($i - $minus)] =~ /^msgid\s"(.+)"/) {

			my $md5 = md5_hex ($1);
			if (exists $translations->{$md5} && $translations->{$md5}{translation} ) {

				push @output_strings, "msgstr \"(*) " . $translations->{$md5}{translation} . "\"\n";
				$found = 1;
			}
			else {

				print "$md5 $minus NOT FOUND\n";
			}
			last;
		}
		elsif ($strings[($i - $minus)] =~ /^msgid\s""/) {

			my $reverse = $minus;
			my $content = "";
			while ($reverse) {

				if ($strings[($i - $reverse)] =~ /^"(.+)"$/) {

					my $cur_cntnt = $1;
					$cur_cntnt =~ s/\n$//;
					$content .= $cur_cntnt;
				}
				$reverse--;
			}
			my $md5 = md5_hex ($content);
			if (exists $translations->{$md5} && $translations->{$md5}{translation} ) {

				push @output_strings, "msgstr \"(*) " . $translations->{$md5}{translation} . "\"\n";
				$found = 1;
			}
			else {

				print "Multiline not found '''$content'''\n";
			}
		}
		else {
			print "NOTMSGID " . $strings[($i - $minus)] . "\n";
		}
	}
	push @output_strings, $strings[$i] unless $found;
	$i++;
}

write_file ($output, @output_strings);
print "Successfull write to $output\n";
