use strict;

use Data::Dumper;
use File::Slurp qw(read_file write_file);
use JSON qw(to_json);
use Digest::MD5::File qw(md5_hex);


my $input_file  = $ARGV[0];
my $output_file = $ARGV[1];

if (! -e $input_file || !$output_file) {
	die "Usage: pot2json.pl POT_FILENAME OUTPUT_JSON_FILENAME\n";
}

my @po_strings = read_file ($input_file);

my %json_strings;

my $i = 0;

my ($output_string, $translate, $context) = ("", "", "");

my ($starten, $starttrans);
my $enstr = "";

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
		foreach my $plus ( 1 .. 10 ) {
			last if ! exists $po_strings[ ( $i + $plus ) ];
			last if $po_strings[ ( $i + $plus ) ] !~ /^\"/;
			$po_strings[ ( $i + $plus ) ] =~ s/^\"//;
			$po_strings[ ( $i + $plus ) ] =~ s/\"$//;
			$po_strings[ ( $i + $plus ) ] =~ s/\n//;
			$english .= $po_strings[ ( $i + $plus ) ];
		}
	}
	elsif ($input_string =~ /^msgstr\s\"/) {

		my $translation = "";
		if ($input_string =~ /^msgstr\s\"(.+)\"$/) {
			$translation = $1;
		}
		elsif ( $input_string =~ /^msgstr\s\"\"$/) {
			# nothing
		}
		else {
			$translation = $input_string;
		}
		foreach my $plus ( 1 .. 10 ) {
			last if ! exists $po_strings[ ( $i + $plus ) ];
			last if $po_strings[ ( $i + $plus ) ] !~ /^\"/;
			$translation .= $po_strings[ ( $i + $plus ) ];
		}

		if ($english) {
			$megalist{ md5_hex ($english) } = { english => $english, translation => $translation };
			#push @megalist, [ md5_hex ($english), $english, $translation ];
			$english = "";
		}
	}
	$i++;
}

#@megalist = sort {$a->[0] cmp $b->[1]} @megalist;

write_file ($output_file, to_json(\%megalist, { pretty => 1, canonical => 1 } ));

