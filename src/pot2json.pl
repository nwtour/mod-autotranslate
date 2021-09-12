use strict;

use Data::Dumper;
use File::Slurp qw(read_file write_file);
use JSON qw(to_json);
use Digest::MD5::File qw(md5_hex);
use Getopt::Long;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

my $pot = "";

GetOptions ("pot=s" => \$pot);

my $input_file  = catfile ($Bin, 'A25B', $pot . '.pot');
my $output_file = catfile ($Bin, 'json', $pot . '.json');

die "Usage: pot2json.pl --pot=<POT_NAME>\n\texample --pot=engine\n" if ! -e $input_file;

print "Input file: $input_file\n";

my @po_strings = read_file ($input_file);

my %json_strings;
my $i = 0;
my $output_string = "";

while (exists $po_strings[ $i ]) {

	my $input_string = $po_strings[ $i ];

	if ($input_string =~ /^msgid\s\"(.+)\"$/) {

		$output_string .= $1;
	}
	elsif ($input_string =~ /^\"(.+)\"$/) {

		my $s = $1;
		if ($input_string !~ /^\"(Project-Id-Version|POT-Creation-Date|PO-Revision-Date|Plural-Forms|MIME-Version|Content-Type|Content-Transfer-Encoding)/ ) {

			$output_string .= $s;
		}
	}
	elsif ($output_string) {

		$json_strings{ md5_hex ($output_string) } = $output_string;
		$output_string = "";
	}
	$i++;
}

print "Output file: $output_file\n";
write_file ($output_file, to_json (\%json_strings, {pretty => 1, canonical => 1}));

