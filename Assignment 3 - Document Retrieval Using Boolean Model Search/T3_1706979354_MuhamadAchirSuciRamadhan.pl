#!/usr/local/bin/perl

use strict;
use warnings;
# STEMMING PART
# Reference: https://github.com/apache/lucene-solr/blob/master/lucene/analysis/common/src/java/org/apache/lucene/analysis/id/IndonesianStemmer.java 

our $numSyllables = 0;
our $flags = 0;
use constant {
	REMOVED_KE => 1,
	REMOVED_PENG => 2,
	REMOVED_DI => 4,
	REMOVED_MENG => 8,
	REMOVED_TER => 16,
	REMOVED_BER => 32,
	REMOVED_PE => 64,
};

sub isVowel {
	my $ch = $_[0];
	return $ch eq "a" || $ch eq "e" || $ch eq "i" || $ch eq "o" || $ch eq "u";
}

sub endsWith {
	my $text = $_[0]; #reference
	my $length = $_[1];
	my $sufiks = $_[2]; #string

	my $len_suf = length($sufiks);
	
	if ($len_suf > $length) {
		return 0;
	}
	return substr($$text, $length - $len_suf, $len_suf) eq $sufiks;
}

sub startsWith {
	my $text = $_[0]; # reference
	my $length = $_[1];
	my $prefiks = $_[2]; # string

	my $len_pref = length($prefiks);

	if ($len_pref > $length) {
		return 0;
	}
	return substr($$text, 0, $len_pref) eq $prefiks;
}

sub removeParticle {
	my $text = $_[0]; # reference
	my $length = $_[1];

	if (endsWith($text, $length, "kah") ||
		endsWith($text, $length, "lah") ||
		endsWith($text, $length, "pun")) {
		$numSyllables--;
		return $length - 3;
	}

	return $length;
}

sub removePossessivePronoun {
	my $text = $_[0]; # reference
	my $length = $_[1];

	if (endsWith($text, $length, "ku") ||
		endsWith($text, $length, "mu")) {
		$numSyllables--;
		return $length - 2;
	}
	if (endsWith($text, $length, "nya")) {
		$numSyllables--;
		return $length - 3;
	}

	return $length;
}


# Bagian dari Stem Derivational

sub deletePref {
	my $text = $_[0]; # reference
	my $length = $_[1];
	my $len_pref = $_[2];

	$$text = substr($$text, $len_pref, $length - $len_pref);
	return $length - $len_pref;
}

sub removeFirstOrderPrefix {
	my $text = $_[0]; # reference
	my $length = $_[1];

	if (startsWith($text, $length, "meng")) {
		$flags |= REMOVED_MENG;
		$numSyllables--;
		return deletePref($text, $length, 4);
	}

	if (startsWith($text, $length, "meny")) {
		$flags |= REMOVED_MENG;
		$numSyllables--;
		substr($$text, 3, 1) = "s";
		return deletePref($text, $length, 3);
	}

	if (startsWith($text, $length, "men")) {
		$flags |= REMOVED_MENG;
		$numSyllables--;
		return deletePref($text, $length, 3);
	}

	if (startsWith($text, $length, "mem")) {
		$flags |= REMOVED_MENG;
		$numSyllables--;
		return deletePref($text, $length, 3);
	}

	if (startsWith($text, $length, "me")) {
		$flags |= REMOVED_MENG;
		$numSyllables--;
		return deletePref($text, $length, 2);
	}

	if (startsWith($text, $length, "peng")) {
		$flags |= REMOVED_PENG;
		$numSyllables--;
		return deletePref($text, $length, 4);
	}

	if (startsWith($text, $length, "peny") && $length > 4 && isVowel(substr($$text, 4, 1))) {
		$flags |= REMOVED_PENG;
		substr($$text, 3, 1) = "s";
		$numSyllables--;
		return deletePref($text, $length, 3);
	}

	if (startsWith($text, $length, "peny")) {
		$flags |= REMOVED_PENG;
		$numSyllables--;
		return deletePref($text, $length, 4);
	}

	if (startsWith($text, $length, "pen") && $length > 3 && isVowel(substr($$text, 3, 1))) {
		$flags |= REMOVED_PENG;
		substr($$text, 2, 1) = "t";
		$numSyllables--;
		return deletePref($text, $length, 2);
	}

	if (startsWith($text, $length, "pen")) {
		$flags |= REMOVED_PENG;
		$numSyllables--;
		return deletePref($text, $length, 3);
	}

	if (startsWith($text, $length, "pem")) {
		$flags |= REMOVED_PENG;
		$numSyllables--;
		return deletePref($text, $length, 3);
	}

	if (startsWith($text, $length, "di")) {
		$flags |= REMOVED_DI;
		$numSyllables--;
		return deletePref($text, $length, 2);
	}

	if (startsWith($text, $length, "ter")) {
		$flags |= REMOVED_TER;
		$numSyllables--;
		return deletePref($text, $length, 3);
	}
	

	if (startsWith($text, $length, "ke")) {
		$flags |= REMOVED_KE;
		$numSyllables--;
		return deletePref($text, $length, 2);
	}

	return $length;
}

sub removeSecondOrderPrefix {
	my $text = $_[0]; # reference
	my $length = $_[1];

	if (startsWith($text, $length, "ber")) {
		$flags |= REMOVED_BER;
		$numSyllables--;
		return deletePref($text, $length, 3);
	}

	if ($length == 7 && startsWith($text, $length, "belajar")) {
		$flags |= REMOVED_BER;
		$numSyllables--;
		return deletePref($text, $length, 3);
	}

	if (startsWith($text, $length, "be") && $length > 4
		&& !isVowel(substr($$text, 2, 1)) && substr($$text, 3, 1) eq "e"
		&& substr($$text, 4, 1) eq "r") {
		$flags |= REMOVED_BER;
		$numSyllables--;
		return deletePref($text, $length, 2);
	}

	if (startsWith($text, $length, "per")) {
		$numSyllables--;
		return deletePref($text, $length, 3);
	}

	if ($length == 7 && startsWith($text, $length, "pelajar")) {
		$numSyllables--;
		return deletePref($text, $length, 3);
	}

	if (startsWith($text, $length, "pe")) {
		$flags = REMOVED_PE;
		$numSyllables--;
		return deletePref($text, $length, 2);
	}

	return $length;
}

sub removeSuffixHelper {
	my $text = $_[0]; # reference
	my $length = $_[1];

	if (endsWith($text, $length, "kan")
		&& ($flags & REMOVED_KE) == 0
		&& ($flags & REMOVED_PENG) == 0
		&& ($flags & REMOVED_PE) == 0) {
		$numSyllables--;
		return $length - 3;
	}

	if (endsWith($text, $length, "an")
		&& ($flags & REMOVED_DI) == 0
		&& ($flags & REMOVED_MENG) == 0
		&& ($flags & REMOVED_TER) == 0) {
		$numSyllables--;
		return $length - 2;
	}

	if (endsWith($text, $length, "i")
		&& !endsWith($text, $length, "si")
		&& ($flags & REMOVED_BER) == 0
		&& ($flags & REMOVED_KE) == 0
		&& ($flags & REMOVED_PENG) == 0) {
		$numSyllables--;
		return $length - 1;
	}

	return $length;
}

sub removeSuffix {
	my $text = $_[0]; # reference
	my $length = $_[1];

	my $new_len = removeSuffixHelper($text, $length);
	$$text = substr($$text, 0, $new_len);
	return $new_len;
}

sub stemDerivational {
	my $text = $_[0]; # reference
	my $length = $_[1];

	my $oldLength = $length;
	if ($numSyllables > 2) {
		$length = removeFirstOrderPrefix($text, $length);
	}

	if ($oldLength != $length) {
		$oldLength = $length;
		if ($numSyllables > 2) {
			$length = removeSuffix($text, $length);
		}
		if ($oldLength != $length) {
			if ($numSyllables > 2) {
				$length = removeSecondOrderPrefix($text, $length);
			}
		}
	} else {
		if ($numSyllables > 2) {
			$length = removeSecondOrderPrefix($text, $length);
		}
		if ($numSyllables > 2) {
			$length = removeSuffix($text, $length);
		}
	}

	return $length;
}

sub stem {
	my $text = $_[0]; # reference
	my $length = $_[1];
	my $stemDerivational = $_[2];

	$flags = 0;
	$numSyllables = 0;
	my @text_arr = split("", $$text);
	for (my $i = 0; $i < $length; $i++) {
		if (isVowel($text_arr[$i])) {
			$numSyllables++;
		}
	}

	if ($numSyllables > 2) {
		$length = removeParticle($text, $length);
	}

	if ($numSyllables > 2) {
		$length = removePossessivePronoun($text, $length);
	}

	$$text = substr($$text, 0, $length);

	if ($stemDerivational) {
		$length = stemDerivational($text, $length);
	}
	return $length;
}

# END OF STEMMING PART

# MAIN PART

use Plucene;
use Plucene::Document;
use Plucene::Document::Field;
use Plucene::Analysis::SimpleAnalyzer;
use Plucene::Index::Writer;
use Plucene::QueryParser;
use Plucene::Search::IndexSearcher;

# subroutine for tokenizing sentence
sub tokenize {
	my $line = $_[0]; # string
	$line =~ s/[^a-zA-Z0-9]+/ /g;
	$line =~ s/^\s*//;
	$line =~ s/\s*$//;
	$line = lc($line);
	my @word_list = split(/\s+/, $line);
	my $result = "";
	for my $word (@word_list) {
		my $new_len = stem(\$word, length($word), 1);
		if ($new_len != length($word)) {
			my $msg = "Stemming Failed";
			die "Assertion failed: $msg";
		}

		$result = $result." ".$word;
	}

	$result =~ s/^\s*//;
	$result =~ s/\s*$//;
	return $result;
}

# main
open(IN, "korpus-tugas2.txt");
print("Masukkan Query: ");

my $analyzer = Plucene::Analysis::SimpleAnalyzer->new();
my $writer = Plucene::Index::Writer->new("my_index", $analyzer, 1);

my $in_text = 0;
my $in_doc = 0;
my $doc_id = "";
my $title = "";
my $text = "";
my $cnt = 0;

# parsing korpus
LOOP: while (my $line = <IN>) {
	if ($in_doc) {
		if ($line =~ /<\/DOC>/) {
			$text =~ s/^\s*//;
			$text =~ s/\s*$//;

			my $doc = Plucene::Document->new();
			$doc->add(Plucene::Document::Field->Text(doc_id => $doc_id));
			$doc->add(Plucene::Document::Field->Text(title => $title));
			$doc->add(Plucene::Document::Field->Text(text => $text));

			$writer->add_document($doc);

			$in_doc = 0;
			$title = "";
			$text = "";
			$doc_id = "";
			next LOOP;
		}
		if ($line =~ /<DOCID>(.*)<\/DOCID>/) {
			$doc_id = $1;
			$doc_id =~ s/^\s+//;
			$doc_id =~ s/\s+$//;
			next LOOP;
		}
		if ($line =~ /<TITLE>(.*)<\/TITLE>/) {
			$title = $1;
			$title =~ s/^\s+//;
			$title =~ s/\s+$//;
			$title = tokenize($title);
			next LOOP;
		}

		if ($line =~ /<\/TEXT>/) {
			$in_text = 0;
			next LOOP;
		}
		if ($in_text) {
			my $tokenized_text = tokenize($line);
			if (length($tokenized_text) == 0) {
				next LOOP;
			}
			$text = $text." ".$tokenized_text;
			next LOOP;
		}
		if ($line =~ /<TEXT>/) {
			$in_text = 1;
			next LOOP;
		}
	} else {
		if ($line =~ /<DOC>/) {
			$in_doc = 1;
			next LOOP;
		}
	}
}

undef $writer;

my $searcher = Plucene::Search::IndexSearcher->new("my_index");

my @docs;
my %score; # doc_id -> score
my $hc = Plucene::Search::HitCollector->new(collect => sub {
	my ($self, $doc, $score) = @_;
	my $cur_doc = $searcher->doc($doc);
	my $doc_id = $cur_doc->get("doc_id")->string;
	push(@docs, $cur_doc);
	$score{$doc_id} = $score;
});

my $parser = Plucene::QueryParser->new({
	analyzer => Plucene::Analysis::SimpleAnalyzer->new(),
	default => "text"
});

# input query and tokenizing
my $query_str = <STDIN>;
$query_str = tokenize($query_str);
print("Tokenized Query: ".$query_str."\n");

# generate boolean query for text and title
my @query_str_arr = split(/\s+/, $query_str);
my $query_str_title = "";
my $query_str_text = "";
if (scalar(@query_str_arr) > 0) {
	$query_str_title = "title:".$query_str_arr[0];
	$query_str_text = "text:".$query_str_arr[0];
}

for (my $i = 1; $i < scalar(@query_str_arr); $i++) {
	$query_str_title = $query_str_title." AND title:".$query_str_arr[$i];
	$query_str_text = $query_str_text." AND text:".$query_str_arr[$i];
}

print("Generated Query for Plucene: ".sprintf('(%s) OR (%s)', $query_str_text, $query_str_title)."\n");

my $query = $parser->parse(sprintf('(%s) OR (%s)', $query_str_text, $query_str_title));
$searcher->search_hc($query => $hc);

# sort by score
@docs = sort {$score{$b->get("doc_id")->string} <=> $score{$a->get("doc_id")->string}} (@docs);

for my $i (@docs) {
	my $doc_id = $i->get("doc_id")->string;
	print(($doc_id)." ".($score{$doc_id})."\n");
}

print(scalar(@docs)."\n");

$cnt = 1;
print("\nResult:\n");
for my $i (@docs) {
	my $doc_id = $i->get("doc_id")->string;
	print(($cnt++)." : ".$doc_id."\n");
}
