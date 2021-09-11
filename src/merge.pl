
use strict;

use Data::Dumper;
use File::Slurp qw(read_file write_file);
use JSON qw(from_json to_json);
use Digest::MD5::File qw(md5_hex);

my $input = $ARGV[0];
my $output = 'sr.public-gui-campaigns.po';

my @strings = read_file ($input);

my $translations = from_json(read_file("translations.json"));

my $i = 0;
while (exists $strings[$i]) {

	if ($strings[$i] =~ /^msgstr\s""/) {

		my $found = 0;
		foreach my $minus (1, 2, 3) {

			if ($strings[($i - $minus)] =~ /^msgid\s"(.+)"/) {

				my $md5 = md5_hex($1);
				if (exists $translations->{$md5} && $translations->{$md5}{translation} ) {
					print "msgstr \"" . $translations->{$md5}{translation} . "\"\n";
					$found = 1;
				}
				else {

					print STDERR "$md5 $minus NOT FOUND\n";
				}
				last;
			}
			else {
				print STDERR "NOTMSGID " . $strings[($i - $minus)] . "\n";
			}
		}
		print $strings[$i] unless $found;
	}
	else {
		print $strings[$i];
	}
	$i++;
}

