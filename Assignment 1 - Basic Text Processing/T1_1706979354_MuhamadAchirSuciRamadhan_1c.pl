#!usr/local/bin/perl

open(IN, "korpus-1.txt");
open(OUT, ">semua-angka.txt");

$banyak_angka = 0;

# Fungsi untuk memproses sebuah baris
sub hitung_angka {
	$baris = $_[0];
	# ganti semu karakter selain alfabet latin, '.', dan ',' sebagai ' '
	$baris =~ s/[^a-zA-z0-9\,\.]+/ /g;
	$baris =~ s/^\s*//; # hapus semua spasi di awal baris
	$baris =~ s/\s*$//; # hapus semua spasi di akhir baris
	@array_kata = split(/\s+/, $baris); # split dengan delimiter satu atau lebih spasi
	for $kata (@array_kata) {
		$kata =~ s/[\,\.]$//; # hapus '.' dan ',' yang terletak di akhir baris
		if ($kata ne "" && $kata =~ /^(((0|([1-9][0-9]*|[1-9]{1,3}(\.[0-9]{3})*))(\,[0-9]+)?)|(M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})))$/) {
			# Kasus bilangan biasa: bulat, desimal, atau romawi
			print OUT ($kata."\n");
			$banyak_angka++;
		} else {
			# Kasus bertitik atau berkoma tetapi bukan desimal dan bukan ribuan, split menggunakan ',' atau '.' nya
			@array_angka = split(/[\.\,]/, $kata);
			for $kand_angka (@array_angka) {
				if ($kand_angka ne "" && $kand_angka =~ /^[0-9]+$/) {
					print OUT $kand_angka."\n";
					$banyak_angka++;
				}
			}
		}
	}
}

$in_text = 0; # flag penanda bahwa sekarang looping sedang berada di dalam TEXT
LOOP: while ($baris = <IN>) {
	if ($baris =~ /<TEXT>/) { # Jika memuat bagian awal dari <TEXT>
		# Nyalakan flag dan buang semua karakter dari awal baris
		# sampai akhir <TEXT>. Lalu, proses sisanya.
		$in_text = 1;
		$baris =~ s/^.*<TEXT>//;
		hitung_angka($baris);
		next LOOP; # continue
	} elsif ($baris =~ /<\/TEXT>/) {# Jika memuat bagian akhir </TEXT>
		# Matikan flag dan buang semua karakter dari awal </TEXT>
		# sampai akhir. Tetapi, sisa baris tersebut tetap diproses.
		$baris =~ s/<\/TEXT>.*$//;
		hitung_angka($baris);
		$in_text = 0;
		next LOOP; # continue
	}
	if ($in_text == 1) {
		# Jika tidak memuat tag tetapi di dalam TEXT, baris tersebut tetap
		# diproses.
		hitung_angka($baris);
		next LOOP;
	}
}

print OUT "Angka ada sebanyak ".$banyak_angka."\n";
print "Angka ada sebanyak ".$banyak_angka."\n";