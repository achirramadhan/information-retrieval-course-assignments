#!usr/local/bin/perl

open(IN, "korpus-1.txt");
open(OUT, ">hasil-1b.txt");

my %num_kata;

$banyak_kalimat = 0;
sub hitung_kalimat {
	$baris = $_[0];
	$baris =~ s/^\s*//;
	$baris =~ s/\s*$//;
	@array_kalimat = split(/(?<=[\.\!\?])\"?\s+/, $baris);
	foreach $kalimat (@array_kalimat) {
		$banyak_kalimat++;
		print OUT ($banyak_kalimat." : ".$kalimat."\n");
	}
}
$in_text = 0;
LOOP: while ($baris = <IN>) {
	if ($baris =~ /<TEXT>/) {
		$in_text = 1;
		$baris =~ s/^.*<TEXT>//;
		hitung_kalimat($baris);
		next LOOP;
	} elsif ($baris =~ /<\/TEXT>/) {
		$baris =~ s/<\/TEXT>.*$//;
		hitung_kalimat($baris);
		$in_text = 0;
		next LOOP;
	}
	if ($in_text == 1) {
		hitung_kalimat($baris);
		next LOOP;
	}
}

print OUT ("Banyak kalimat adalah ".$banyak_kalimat."\n");