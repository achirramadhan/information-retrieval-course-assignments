#!usr/local/bin/perl

open(IN, "korpus-1.txt");
open(OUT, ">semua-tanggal.txt");

@array_hari = ("Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Jum\'at", "Sabtu", "Minggu");
@array_bulan = ("Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember");
@array_tanggal = (1..31);
@array_bulan_angka = (1..12);

$banyak_tanggal = 0;
sub deteksi_tanggal {
	$baris = $_[0];
	$baris =~ s/^\s*//; # hapus semua spasi di awal baris
	$baris =~ s/\s*$//; # hapus semua spasi di akhir

	# bruteforce semua pasangan hari tanggal bulan dengan bulan angka
	foreach my $hari (@array_hari) {
		foreach my $tanggal (@array_tanggal) {
			foreach my $bulan (@array_bulan_angka) {
				if ($baris =~ (/($hari\ \($tanggal\/$bulan\/[0-9]{4}\))/i)) {
					print OUT $1."\n";
					$banyak_tanggal++;
				}
			}
		}
	}

	# bruteforce semua pasangan tanggal bulan dengan bulan kata
	foreach my $tanggal (@array_tanggal) {
		foreach my $bulan (@array_bulan) {
			my $ada_hari = 0;
			# coba cek apakah memuat hari
			foreach my $hari (@array_hari) {
				if ($baris =~ (/($hari\ $tanggal\ $bulan(\ [0-9]{4})?)/)) {
					print OUT $1."\n";
					$banyak_tanggal++;
					$ada_hari = 1;
				}
			}
			# kasus jika tidak ada hari
			if ($ada_hari == 0) {
				if ($baris =~ (/([^0-9]$tanggal\ $bulan(\ [0-9]{4})?)/)) {
					print OUT $1."\n";
					$banyak_tanggal++;
				}
			}
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
		deteksi_tanggal($baris);
		next LOOP; # continue
	} elsif ($baris =~ /<\/TEXT>/) {# Jika memuat bagian akhir </TEXT>
		# Matikan flag dan buang semua karakter dari awal </TEXT>
		# sampai akhir. Tetapi, sisa baris tersebut tetap diproses.
		$baris =~ s/<\/TEXT>.*$//;
		deteksi_tanggal($baris);
		$in_text = 0;
		next LOOP; # continue
	}
	if ($in_text == 1) {
		# Jika tidak memuat tag tetapi di dalam TEXT, baris tersebut tetap
		# diproses.
		deteksi_tanggal($baris);
		next LOOP;
	}
}

print OUT "Banyak tanggal sebanyak ".$banyak_tanggal."\n";