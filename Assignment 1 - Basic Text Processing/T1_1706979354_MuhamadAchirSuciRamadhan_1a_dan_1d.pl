#!usr/local/bin/perl

open(IN, "korpus-1.txt");
open(OUT, ">distribusi-kata.csv");

my %kemunculan_kata;

# Fungsi untuk memproses sebuah baris
sub hitung_kata {
	$baris = $_[0]; # parameter yang dibawa di dalam fungsi
	$baris =~ s/[^a-zA-Z0-9]+/ /g; # ubah semua karakter selain a-zA-Z0-9 menjadi spasi
	$baris =~ s/^\s*//; # hapus semua spasi di awal baris
	$baris =~ s/\s*$//; # hapus semua spasi di akhir baris
	@array_kata = split(/\s+/, $baris); # split dengan dilimiter satu atau lebih spaso
	foreach $kata (@array_kata) {
		$kemunculan_kata{$kata}++; # update frekuensi kemunculan
	}
}

$in_text = 0; # flag penanda bahwa sekarang looping sedang berada di dalam TEXT
LOOP: while ($baris = <IN>) {
	if ($baris =~ /<TEXT>/) { # Jika memuat bagian awal dari <TEXT>
		# Nyalakan flag dan buang semua karakter dari awal baris
		# sampai akhir <TEXT>. Lalu, proses sisanya.
		$in_text = 1;
		$baris =~ s/^.*<TEXT>//;
		hitung_kata($baris);
		next LOOP; # continue;
	} elsif ($baris =~ /<\/TEXT>/) { # Jika memuat bagian akhir </TEXT>
		# Matikan flag dan buang semua karakter dari awal </TEXT>
		# sampai akhir. Tetapi, sisa baris tersebut tetap diproses.
		$baris =~ s/<\/TEXT>.*$//;
		hitung_kata($baris);
		$in_text = 0;
		next LOOP; # continue;
	}
	if ($in_text == 1) {
		# Jika tidak memuat tag tetapi di dalam TEXT, baris tersebut tetap
		# diproses.
		hitung_kata($baris);
		next LOOP;
	}
}

# Nomor 1a
# $banyak_kata_unik = scalar(keys(%kemunculan_kata)); # ukuran dari hash_map kemunculan_kata
# print("Kata unik ada sebanyak ".$banyak_kata_unik." buah\n");

# Nomor 1d
# sort kata berdasarkan kemunculannya
@sorted_keys = sort{$kemunculan_kata{$b} <=> $kemunculan_kata{$a}}(keys(%kemunculan_kata));
$rank = 1;
print OUT ("rank, kata, kemunculan, kata * kemunculan\n");
foreach $kata (@sorted_keys) {
	print OUT ($rank.",".$kata.",".$kemunculan_kata{$kata}.",".($rank * $kemunculan_kata{$kata})."\n");
	$rank++;
}