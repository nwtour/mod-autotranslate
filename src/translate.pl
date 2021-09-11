
$|=1;

use strict;

use Data::Dumper;
use File::Slurp qw(read_file write_file);
use JSON qw(from_json to_json);

my $result;

my $release = from_json(read_file("public-gui-campaigns.json"));
my $devel   = from_json(read_file("sr.public-gui-campaigns.json"));

$result = from_json(read_file("translations.json")) if -e "translations.json";

sub run_translate {
	my $string = shift;

	system('./trans -o tmp_trans.txt -b en:sr "' . $string . '"');
	my $translation = read_file("tmp_trans.txt");
	$translation =~ s/\n$//;
	return $translation;
}


foreach my $md5 (keys %{$release}) {

	my $ingame = ( exists $devel->{$md5} && $devel->{$md5}{translation} ? $devel->{$md5}{translation} : "" );

	if ( $ingame ) {
		print "$md5 = $ingame (translation already in game)\n";
		next;
	}

	my $queue = ( exists $result->{$md5} && $result->{$md5}{translation} ? $result->{$md5}{translation} : "" );

	if ( $queue ) {

		print "$md5 = $queue (already translated)\n";
		next;
	}

	my $english = $devel->{$md5}{english};
	my @list = split (/\s%s/, $english);
	my $translation = "";
	if (scalar (@list) > 1) {
		print Dumper(\@list);
		my @ll;
		foreach my $substring ( @list ) {
			my $temp = ( $substring =~ /^\W+$/ ? $substring : run_translate($substring));
			push @ll, $temp;
			print "TEMP $english $temp\n";
			sleep(60);
		}
		$translation = join (' %s', @ll);

	}


	$translation = run_translate ( $english ) if ! $translation;
	$result->{$md5} = { english => $english, translation => $translation };
	write_file ("translations.json", to_json($result, { pretty => 1, canonical => 1 } ));
	print "$md5 = $translation (translation result)\n";
	exit;
}

