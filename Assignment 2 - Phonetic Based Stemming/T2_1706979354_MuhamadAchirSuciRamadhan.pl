#!/usr/local/bin/perl

use List::Util qw(min max);

open(IN, "korpus-tugas2.txt");

### Nomor 1
### Bagian ini akan mendaftar semua kata unik ke dalam array @vocab_list
my %unique_vocab;
sub update_unique_vocab {
	my $line = $_[0];
	$line =~ s/[^a-zA-Z0-9]+/ /g;
	$line =~ s/^\s*//;
	$line =~ s/\s*$//;
	my @word_list = split(/\s+/, $line);
	foreach my $word (@word_list) {
		# diasumsikan kata tidak sensitive case
		$unique_vocab{lc($word)}++;
	}
}

my $in_text = 0;
LOOP: while(my $line = <IN>) {
	if ($line =~ /<TEXT>/) {
		$in_text = 1;
		$line =~ s/^.*<TEXT>//;
		update_unique_vocab($line);
		next LOOP;
	} elsif ($line =~ /<\/TEXT>/) {
		$line =~ s/<\/TEXT>.*$//;
		update_unique_vocab($line);
		$in_text = 0;
		next LOOP;
	}
	if ($in_text == 1) {
		update_unique_vocab($line);
	}
}

my @vocab_list = sort {$a cmp $b} keys(%unique_vocab);

open(OUT, ">vocabulary_list.txt");
for $vocab (@vocab_list) {
	print OUT $vocab."\n";
}
close(OUT);


### Nomor 2
### Bagian ini akan menjalankan phonetic based stemming algorithm

##### Nomor 2b, perolehan kode fonetik masing-masing kata

# Subroutine ini akan mengembalikan phonetic code dari suatu kata menggunakan
# Soundex algorithm
sub get_phonetic_code { # param : kata
	my $word = $_[0];

	# pertahankan huruf pertama kata
	my $front_char = substr $word, 0, 1;
	my $rem_word = substr $word, 1;

	# ubah karakter sisanya berdasarkan aturan soundex
	$rem_word =~ s/[aeiouyhw]/0/g;
	$rem_word =~ s/[bfpv]/1/g;
	$rem_word =~ s/[cgjkqsxz]/2/g;
	$rem_word =~ s/[dt]/3/g;
	$rem_word =~ s/[l]/4/g;
	$rem_word =~ s/[mn]/5/g;
	$rem_word =~ s/[r]/6/g;

	# buang semua pasangan angka yang berurutan menjadi satu karakter saja
	$rem_word =~ s/(.)\1+/$1/g;

	# buang semua 0 dari string yang dihasilkan
	$rem_word =~ s/0//g;

	# gabungkan kembali dengan huruf pertama yang telah dikonversi ke huruf kapital
	$front_char = uc $front_char;
	$word = $front_char.$rem_word;

	# potong atau tambahkan karakter 0 sehingga hasil akhir terdiri dari 4 karakter
	my $len = length($word);
	if ($len >= 4) {
		$word = substr $word, 0, 4;
	} else {
		$word = $word.('0' x (4 - $len));
	}

	return $word;
}

# phonetic_code akan menyimpan kode fonetik setiap kata
my %phonetic_code;
for $word (@vocab_list) {
	$phonetic_code{$word} = get_phonetic_code($word);
}


##### Nomor 2c, pemecahan kata yang memiliki kode fonetik sama

# mengurutkan setiap kata berdasarkan phonetic code-nya
# untuk memudahkan perolehan kata yang memiliki phonetic code sama
my @word_sorted_by_pcode = sort {
	$phonetic_code{$a} cmp $phonetic_code{$b}
		or
	length($a) < length($b)
} (keys(%phonetic_code));

# simpan ke dalam file untuk menjawab soal nomor 3
open(OUT, ">soundex_result.txt");
for my $i (0..scalar(@word_sorted_by_pcode)) {
	my $word = $word_sorted_by_pcode[$i];
	print OUT $word." ".$phonetic_code{$word}."\n";
}
close(OUT);


##### Nomor 2d - 2g, edit distance dan lcs
# Bagian ini akan menentukan range kata yang memiliki phonetic code sama
# lalu memrosesnya dengan memperoleh Edit Distance dan Longest Common
# Subsequnce-nya. Selanjutnya, akan dipilih stem perwakilan dari range
# tersebut.

# Subroutine untuk DP Levenshtein Distance
sub lev_distance_dp { # param: word1, word2, i (pos w1), j (pos w2), dp_table
	my $word1 = $_[0]; # reference
	my $word2 = $_[1]; # reference
	my $i = $_[2];
	my $j = $_[3];
	my $dp_table = $_[4]; # reference

	# state have been visited
	if ($dp_table->[$i][$j] != -1) {
		return $dp_table->[$i][$j];
	}

	# base case
	if (min($i, $j) == 0) {
		$dp_table->[$i][$j] = max($i, $j);
		return $dp_table->[$i][$j];
	}

	# recursion case
	my $case1 = lev_distance_dp($word1, $word2, $i - 1, $j, $dp_table) + 1;
	my $case2 = lev_distance_dp($word1, $word2, $i, $j - 1, $dp_table) + 1;
	my $case3 = lev_distance_dp($word1, $word2, $i - 1, $j - 1, $dp_table);
	if (substr($$word1, $i - 1, 1) ne substr($$word2, $j - 1, 1)) {
		$case3++;
	}

	$dp_table->[$i][$j] = min(min($case1, $case2), $case3);
	return $dp_table->[$i][$j];
}

# Subroutine untuk interface Levenshtein Distance yang langsung pakai
sub lev_distance { # param: word1, word2
	my $word1 = $_[0]; # reference
	my $word2 = $_[1]; # reference
	my $len1 = length($$word1);
	my $len2 = length($$word2);

	# initialize dp_table
	my @dp_table;
	for my $i (0..$len1 + 1) {
		for my $j (0..$len2 + 1) {
			$dp_table[$i][$j] = -1;
		}
	}

	return lev_distance_dp($word1, $word2, $len1, $len2, \@dp_table);
}

# Subroutine untuk DP Longest Common Subsequce Unigram Overlap
sub lcs_dp { # param: word1, word2, i (pos w1), j (pos w2), dp_table
	my $word1 = $_[0]; # reference
	my $word2 = $_[1]; # reference
	my $i = $_[2];
	my $j = $_[3];
	my $dp_table = $_[4]; # reference

	# state have been visited
	if ($dp_table->[$i][$j] != -1) {
		return $dp_table->[$i][$j];
	}

	# base case
	if (min($i, $j) == 0) {
		$dp_table->[$i][$j] = 0;
		return $dp_table->[$i][$j];
	}

	# recursion case
	if (substr($$word1, $i - 1, 1) ne substr($$word2, $j - 1, 1)) {
		my $case1 = lcs_dp($word1, $word2, $i - 1, $j, $dp_table);
		my $case2 = lcs_dp($word1, $word2, $i, $j - 1, $dp_table);
		$dp_table->[$i][$j] = max($case1, $case2);
	} else {
		my $case3 = lcs_dp($word1, $word2, $i - 1, $j - 1, $dp_table) + 1;
		$dp_table->[$i][$j] = $case3;
	}

	return $dp_table->[$i][$j];
}

# Subroutine untuk interface LCS Unigram Overlap yang langsung pakai
sub lcs { # param: word1, word2
	my $word1 = $_[0]; # reference
	my $word2 = $_[1]; # reference
	my $len1 = length($$word1);
	my $len2 = length($$word2);

	# initialize dp_table
	my @dp_table;
	for my $i (0..$len1 + 1) {
		for my $j (0..$len2 + 1) {
			$dp_table[$i][$j] = -1;
		}
	}

	return lcs_dp($word1, $word2, $len1, $len2, \@dp_table);
}

# Subroutine untuk memroses range kata yang memiliki phonetic code sama
sub process_stem { # param: idx_left, idx_right, word_sorted_by_pcode, array len_word, stemmed_idx
	my $l = $_[0]; # left of range (inclusive)
	my $i = $_[1]; # right of range (exclusive)
	my $word_sorted_by_pcode = $_[2]; # reference
	my $len_word = $_[3]; # reference, array of len of word
	my $stemmed_idx = $_[4]; # reference

	for (my $j = $l; $j < $i; $j++) { # Cari semua stem dari setiap kata di range ini
		# input: kata $j
		my @ed_array; # edit distance terhadap input
		my @lcs_array; # lcs terhadap input
		for (my $k = $l; $k < $i; $k++) { # semua kata dengan phonetic code sama dengan kata $j
			$ed_array[$k - $l] = lev_distance( # idx relatif terhadap $l
				\$$word_sorted_by_pcode[$j],
				\$$word_sorted_by_pcode[$k]);
			$lcs_array[$k - $l] = lcs(
				\$$word_sorted_by_pcode[$j],
				\$$word_sorted_by_pcode[$k]);

			if (!($ed_array[$k - $l] + $lcs_array[$k - $l] == $$len_word[$j]
				&& $ed_array[$k - $l] < $lcs_array[$k - $l])) {
				# jika 1.e.I dan 1.e.II tidak keduanya terpenuhi sekaligus
				$ed_array[$k - $l] = -1; # nilai -1 akan menjamin $k tidak akan terpilih
				$lcs_array[$k - $l] = -1;
			}
		}

		my $idx_stem = $j; # secara default, stem dari suatu kata adalah kata itu sendiri
		for (my $k = $l; $k < $i; $k++) { # mencari stem yang lebih baik
			# prioritas: ED maksimum -> LCS minimum -> panjang stem minimum
			if ($ed_array[$k - $l] > $ed_array[$idx_stem - $l]) { # idx relatif terhadap $l
				$idx_stem = $k;
			} elsif ($ed_array[$k - $l] == $ed_array[$idx_stem - $l]) {
				if ($lcs_array[$k - $l] < $lcs_array[$idx_stem - $l]) {
					$idx_stem = $k;
				} elsif ($lcs_array[$k - $l] == $lcs_array[$idx_stem - $l]
					&& $$len_word[$k] < $$len_word[$idx_stem]) { # idx asli
					$idx_stem = $k;
				}
			}
		}
		$stemmed_idx->[$j] = $idx_stem;
	}
}

# simpan panjang setiap kata di dalam array len_word agar
# akses ke depannya bisa O(1)
my $len = scalar(@word_sorted_by_pcode);
my @len_word;
for (my $i = 0; $i < $len; $i++) {
	$len_word[$i] = length($word_sorted_by_pcode[$i]);
}

# penyimpanan index yang menjadi stem
my @stemmed_idx;
my $l = 0; # batas kiri range yang memiliki phonetic_code sama
for (my $i = 1; $i < $len; $i++) {
	if ($phonetic_code{$word_sorted_by_pcode[$i]} ne $phonetic_code{$word_sorted_by_pcode[$i - 1]}) {
		# jika ditemukan phonetic_code berbeda, maka range $l sampai $i - 1 memiliki phonetic_code yang sama
		print "Processing ".($l + 1)." to ".$i." out of ". $len."\n";
		process_stem($l, $i, \@word_sorted_by_pcode, \@len_word, \@stemmed_idx); # proses range tersebut
		$l = $i; # update batas kiri range baru menjadi $l
	}
}
print "Processing ".($l + 1)." to ".$len." out of ". $len."\n";
process_stem($l, $len, \@word_sorted_by_pcode, \@len_word, \@stemmed_idx); # range terakhir yang belum diproses

# simpan ke dalam file sebagai hasil akhir nomor 2
open(OUT, ">stemmer_result.txt");
for (my $i = 0; $i < $len; $i++) {
	my $idx_stem = $stemmed_idx[$i];
	printf OUT "%-18s %s\n", $word_sorted_by_pcode[$i], $word_sorted_by_pcode[$idx_stem];
}
close(OUT);


### Nomor 5
### Bagian ini akan melakukan tes terhadap fungsi edit distance dan
### unigram overlap yang dibuat
### Kata-kata yang dipilih merupakan kata-kata di dalam soundex_result
### yang memiliki phonetic code yang sama
open(OUT, ">edit_distance_unigram_overlap.txt");
my $word1, $word2;

print OUT "Edit Distance\n";

$word1 = "bukunya";
$word2 = "bahasan";
print OUT $word1." ".$word2." ".(lev_distance(\$word1, \$word2))."\n";

$word1 = "dukungannya";
$word2 = "dikonsumsi";
print OUT $word1." ".$word2." ".(lev_distance(\$word1, \$word2))."\n";

$word1 = "pertama";
$word2 = "pratama";
print OUT $word1." ".$word2." ".(lev_distance(\$word1, \$word2))."\n";

$word1 = "apartemen";
$word2 = "apartemennya";
print OUT $word1." ".$word2." ".(lev_distance(\$word1, \$word2))."\n";

$word1 = "sutradara";
$word2 = "saudaranya";
print OUT $word1." ".$word2." ".(lev_distance(\$word1, \$word2))."\n";

print OUT "---------------------------------\n";
print OUT "Unigram Overlap\n";

$word1 = "bukunya";
$word2 = "bahasan";
print OUT $word1." ".$word2." ".(lcs(\$word1, \$word2))."\n";

$word1 = "dukungannya";
$word2 = "dikonsumsi";
print OUT $word1." ".$word2." ".(lcs(\$word1, \$word2))."\n";

$word1 = "pertama";
$word2 = "pratama";
print OUT $word1." ".$word2." ".(lcs(\$word1, \$word2))."\n";

$word1 = "apartemen";
$word2 = "apartemennya";
print OUT $word1." ".$word2." ".(lcs(\$word1, \$word2))."\n";

$word1 = "sutradara";
$word2 = "saudaranya";
print OUT $word1." ".$word2." ".(lcs(\$word1, \$word2))."\n";

close(OUT);
