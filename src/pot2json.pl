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

my $output_string = "";

while (exists $po_strings[ $i ]) {

	my $input_string = $po_strings[ $i ];

#msgctxt "Campaign Template"
#msgid ""
#"Discover the new maps in Alpha XXVI with a demo campaign, taking you through all of "
#"them."
#msgstr ""

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

write_file ( $output_file, to_json(\%json_strings, { pretty => 1} ));

