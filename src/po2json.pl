use strict;

use Data::Dumper;
use File::Slurp qw(read_file write_file);
use JSON qw(to_json);
use Digest::MD5::File qw(md5_hex);
use Getopt::Long;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

my ($lang, $po) = ("", "");

GetOptions ("po=s" => \$po, "lang=s" => \$lang);

my $input_file  = catfile ($Bin, 'devel', join ('', $lang, '.', $po . '.po'));
my $output_file = catfile ($Bin, 'json',  join ('', $lang, '.', $po . '.json'));

print "Input file: $input_file\n";

die "Usage: po2json.pl --lang=<LANG NAME> --po=<PO_NAME>\n\texample --lang=sr --po=engine\n" if ! -e $input_file;

my @po_strings = read_file ($input_file);

my $i = 0;

my %megalist;

my $english = "";

while (exists $po_strings[ $i ]) {

	my $input_string = $po_strings[ $i ];

	if ($input_string =~ /^msgid\s\"/) {

		if ($input_string =~ /^msgid\s\"(.+)\"$/) {

			$english = $1;
		}
		elsif ( $input_string =~ /^msgid\s\"\"$/) {

			# nothing
		}
		else {

			$english = $input_string;
		}
		foreach my $plus (1 .. 10) {

			last if ! exists $po_strings[ ($i + $plus) ];
			last if $po_strings[ ($i + $plus) ] !~ /^\"/;
			$po_strings[ ($i + $plus) ] =~ s/^\"//;
			$po_strings[ ($i + $plus) ] =~ s/\"$//;
			$po_strings[ ($i + $plus) ] =~ s/\n//;
			$english .= $po_strings[ ($i + $plus) ];
		}
	}
	elsif ($input_string =~ /^msgstr\s\"/) {

		my $translation = "";
		if ($input_string =~ /^msgstr\s\"(.+)\"$/) {

			$translation = $1;
		}
		elsif ($input_string =~ /^msgstr\s\"\"$/) {

			# nothing
		}
		else {

			$translation = $input_string;
		}
		foreach my $plus (1 .. 10) {

			last if ! exists $po_strings[ ( $i + $plus ) ];
			last if $po_strings[ ( $i + $plus ) ] !~ /^\"/;
			$translation .= $po_strings[ ($i + $plus) ];
		}

		if ($english) {

			$megalist{ md5_hex ($english) } = {english => $english, translation => $translation};
			$english = "";
		}
	}
	$i++;
}

print "Output file: $output_file\n";
write_file ($output_file, to_json (\%megalist, {pretty => 1, canonical => 1}));

