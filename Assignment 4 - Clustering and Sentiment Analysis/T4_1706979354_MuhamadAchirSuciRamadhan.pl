#!/usr/bin/perl

use strict;
use warnings;

# PART A

# subroutine to trim string
sub trim {
	my ($line) = @_; # line reference
	$$line =~ s/^\s+//;
	$$line =~ s/\s+$//;
}

# subroutine to count jacaard distance between two string, given its ids and dictionary to text
sub get_jaccard_dis {
	my ($id_1, $id_2, $dict) = @_; # dict is reference

	my $ptr_set_1 = $dict->{$id_1};
	my $ptr_set_2 = $dict->{$id_2};
	my $sz_1 = keys(%{$ptr_set_1});
	my $sz_2 = keys(%{$ptr_set_2});

	my $card_isect = 0;
	for my $i (keys(%{$ptr_set_1})) {
		$card_isect++ if (exists($ptr_set_2->{$i}));
	}

	my $card_uni = $sz_1 + $sz_2 - $card_isect;

	return 1 - ($card_isect / $card_uni);
}

# read and parsing tweets
open(IN, "twitter_rupiah.txt");
my %id_2_words; # map id tweet -> set words in tweet
my %text; # map id tweet -> raw text in tweet

my $header = <IN>;
while (my $line = <IN>) {
	my $raw_line = $line;

	# preprocess the line to get id and list of words
	trim(\$line);
	my @words = split(/\s+/, $line);
	my $id;
	($id, @words) = @words;

	# check if duplicate ids found
	if ($text{$id}) {
		print("Duplicate ".$id."\n");
	}

	# get raw tweets to be printed in the end of this code
	$text{$id} = (split(/	/, $raw_line))[1];
	$text{$id} =~ s/\n//;

	# keep set of words to be used in counting jaccard distance
	my %set_words;
	@set_words{@words} = ();

	$id_2_words{$id} = \%set_words;
}
print("\n");
close(IN);

# prepocess before k-Medoids: get list of ids sorted
my @twit_ids = keys(%id_2_words);
@twit_ids = sort { $a cmp $b } (@twit_ids);

# read intial centroids
open(IN, "centroid_awal.txt");
my @centroids;
while (my $line = <IN>) {
	trim(\$line);
	push(@centroids, $line);
}
close(IN);

# creating 2D array to keep ids in each cluster
my @ids_in_cluster;
for (my $i = 0; $i < 4; $i++) {
	my @ids;
	push(@ids_in_cluster, \@ids); # only to init size
}

# k-Medoids part
my $iter = 0;
my $is_changed = 1;
while ($is_changed == 1) {
	print("\nIter : ".($iter++)."\n");

	# reset list of id in each cluster
	for my $i (@ids_in_cluster) {
		@$i = ();
	}

	# assign each twit id to each cluster, keeping the index in twit_ids where the twit id stored
	my $len_twit_ids = scalar(@twit_ids);
	for (my $id_idx = 0; $id_idx < scalar(@twit_ids); $id_idx++) {
		my $cluster = 0;
		my $dist = get_jaccard_dis($twit_ids[$id_idx], $centroids[0], \%id_2_words);
		for (my $i = 1; $i < 4; $i++) {
			my $cmp_dist = get_jaccard_dis($twit_ids[$id_idx], $centroids[$i], \%id_2_words);
			if ($cmp_dist < $dist) {
				$dist = $cmp_dist;
				$cluster = $i;
			}
		}

		push(@{$ids_in_cluster[$cluster]}, $id_idx);
	}

	# print centroids before and number of elements in cluster
	print("Centroids Before and Number of Elements:\n");
	for (my $i = 0; $i < 4; $i++) {
		print($centroids[$i]." ".scalar(@{$ids_in_cluster[$i]})."\n");
	}
	print("\n");

	# recopute the centroids, finding twit id that has
	# minimum of average distance to all tweets in cluster (finding medoid)
	my $tmp_is_changed = 0;
	for (my $i = 0; $i < 4; $i++) {
		my $sum_dis = -1;
		my $twit_id_cent = $centroids[$i];

		for my $j (@{$ids_in_cluster[$i]}) {
			my $tmp_sum_dis = 0;

			# finding average distance, but not need to divide by size since every checking
			# has same size
			for my $k (@{$ids_in_cluster[$i]}) {
				$tmp_sum_dis += get_jaccard_dis($twit_ids[$j], $twit_ids[$k], \%id_2_words);
			}

			# update if sum_dis has not been updated yet or tmp_sum_dis is less than sum_dis
			if ($sum_dis == -1 || $tmp_sum_dis < $sum_dis) {
				$sum_dis = $tmp_sum_dis;
				$twit_id_cent = $twit_ids[$j];
			}
		}

		# if centroid is changed, flag it
		if ($centroids[$i] != $twit_id_cent) {
			$tmp_is_changed = 1;
		}
		$centroids[$i] = $twit_id_cent;
	}

	$is_changed = $tmp_is_changed;

	# print centroid after recompute centroids
	print("Centroids After:\n");
	for (my $i = 0; $i < 4; $i++) {
		print($centroids[$i]."\n");
	}
	print("\n");
}

# print output cluster
open(OUT, ">1706979354_output_a.txt");
print(OUT "no_cluster	no_urut	tweet_id	tweet_text\n");

for (my $no_cluster = 0; $no_cluster < 4; $no_cluster++) {
	my $cnt = 0;
	for my $id (@{$ids_in_cluster[$no_cluster]}) {
		print(OUT ($no_cluster + 1)."	".(++$cnt)."	".$twit_ids[$id]."	".$text{$twit_ids[$id]}."\n");
	}
}

close(OUT);


# PART B

# subroutine to get sentiment value
sub get_sent_score {
	my ($sentence, $ptr_pos_words, $ptr_neg_words) = @_;
	trim(\$sentence);
	my @words = split(/\s+/, $sentence);

	my $score = 0;
	my $counter = 0;

	for my $word (@words) {
		if (exists($ptr_pos_words->{$word})) {
			$score++;
			$counter++;
		}

		# it is possible for a word to be classified as positive and negative at the same tmp_is_changed
		# example: "ramai" is contained in positif.txt and negatif.txt
		# thus, I don't use elsif here
		if (exists($ptr_neg_words->{$word})) {
			$score--;
			$counter++;
		}
	}

	return ($counter == 0? 0 : ($score / $counter));
}

# read positive and negative words
my %pos_words;
my %neg_words;

open(IN, "positif.txt");
my @arr_pos_words;
while (my $line = <IN>) {
	$line =~ s/\n//;
	trim(\$line);
	push(@arr_pos_words, $line);
}
close(IN);

open(IN, "negatif.txt");
my @arr_neg_words;
while (my $line = <IN>) {
	$line =~ s/\n//;
	trim(\$line);
	push(@arr_neg_words, $line);
}
close(IN);

@pos_words{@arr_pos_words} = ();
@neg_words{@arr_neg_words} = ();

# compute sentiment number of each cluster and print it
open(OUT, ">1706979354_output_b.txt");
print(OUT "no_cluster	jumlah_tweet_positif	jumlah_tweet_negatif	jumlah_tweet_netral\n");
for (my $no_cluster = 0; $no_cluster < 4; $no_cluster++) {
	my $num_pos = 0;
	my $num_neg = 0;
	my $num_net = 0;
	for my $id (@{$ids_in_cluster[$no_cluster]}) {
		my $twit_id = $twit_ids[$id];
		my $sent_score = get_sent_score($text{$twit_id}, \%pos_words, \%neg_words, 0);
		if ($sent_score > 0) {
			$num_pos++;
		} elsif ($sent_score < 0) {
			$num_neg++;
		} else {
			$num_net++;
		}
	}

	print(OUT ($no_cluster + 1)."	".$num_pos."	".$num_neg."	".$num_net."\n");
}
close(OUT);
