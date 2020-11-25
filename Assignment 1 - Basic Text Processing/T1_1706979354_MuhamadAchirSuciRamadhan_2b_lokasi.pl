#!usr/local/bin/perl

open(IN, "korpus-1.txt");
open(OUT, ">hasil-lokasi.txt");

my %num_kata;
$banyak_lokasi = 0;
sub deteksi_lokasi {
	$baris = $_[0];
	$baris =~ s/^\s*//;
	$baris =~ s/\s*$//;
	# pecah terlebih dahulu baris menjadi beberapa kalimat
	@array_kalimat = split(/(?<=[\.\!\?])\"?\s+/, $baris);
	foreach my $kalimat (@array_kalimat) {
		# definisi lokasi yang dibuat, yaitu rangkaian 2 atau lebih kata yang
		# setiap katanya diawali huruf kapital
		if ($kalimat =~ /([A-Z][a-z]+( [A-Z][a-z]+)+)/) {
			print OUT $1."\n";
			$banyak_lokasi++;
		}
	}
}

$in_text = 0; # flag penanda bahwa sekarang looping sedang berada di dalam TEXT
$banyak_doc = 0;
LOOP: while ($baris = <IN>) {
	if ($baris =~ /<DOCID>/) {
		# print $baris . "\n";
		$banyak_doc++;
		last if ($banyak_doc > 30);
	}
	if ($baris =~ /<TEXT>/) { # Jika memuat bagian awal dari <TEXT>
		# Nyalakan flag dan buang semua karakter dari awal baris
		# sampai akhir <TEXT>. Lalu, proses sisanya.
		$in_text = 1;
		$baris =~ s/^.*<TEXT>//;
		deteksi_lokasi($baris);
		next LOOP; # continue
	} elsif ($baris =~ /<\/TEXT>/) {# Jika memuat bagian akhir </TEXT>
		# Matikan flag dan buang semua karakter dari awal </TEXT>
		# sampai akhir. Tetapi, sisa baris tersebut tetap diproses.
		$baris =~ s/<\/TEXT>.*$//;
		deteksi_lokasi($baris);
		$in_text = 0;
		next LOOP; # continue
	}
	if ($in_text == 1) {
		# Jika tidak memuat tag tetapi di dalam TEXT, baris tersebut tetap
		# diproses.
		deteksi_lokasi($baris);
		next LOOP;
	}
}


print OUT ("Banyak lokasi adalah ".$banyak_lokasi."\n");
