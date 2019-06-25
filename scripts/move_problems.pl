#!/usr/bin/perl

use strict;

use BookData;

local $/;

my @k;
my %file;
my %canonical;
my %topic_name;
my %text;
my @tn;

foreach my $f(<../*/ch*/*.rbtex>) {
  $f =~ m@\.\./(.*)/ch(.*)/ch.*.rbtex@;
  my ($book,$ch) = ($1,$2);
  $ch = $ch+0;
  my $topic = $topic_map{$book}->{$ch};
  die "undefined topic, $book, $ch" if !defined $topic;
  open(F,"<$f") or die "error opening $f, $!";
  my $t = <F>;
  close F;
  my $in = 0;
  foreach my $p(split(/<%\s*(?:begin|end)_hw/,$t)) {
    if ($in) {
      $p =~ /'([^']+)'/;
      my $name = $1;
      my $k = "$book,$ch,$name";
      push @k,$k;
      $file{$k} = $f;
      $topic_name{$k} = "$topic/$name";
      push @tn,$topic_name{$k};
      #print "$k, $topic_name{$k}\n" if $name=~/craps/;
      $p =~ s/^([^%]*)%>//g;
      $text{$k} = $p;
      $p =~ s/\s+//g;
      $p =~ s/\\(hwendpart|answercheck)//g;
      $p =~ s/\\\\//g;
      $canonical{$k} = $p;
    }
    $in = !$in;
  }
}

@tn = sort @tn;

foreach my $tn(@tn) {
  $tn =~ m@(.*)/(.*)@;
  my $topic = $1;
  my $name = $2;
  my @keys;
  foreach my $k(@k) {
    if ($topic_name{$k} eq $tn) {
      push @keys,$k;
    }
  }
  my $differ = 0;
  for (my $i=0; $i<@keys; $i++) {
    for (my $j=0; $j<@keys; $j++) {
      if ($canonical{$keys[$i]} ne $canonical{$keys[$j]}) {$differ=1}
    }
  }
  if (!$differ) {
    print "-----------------identical ,  topic=$topic, name=$name , " . join(' ',@keys) . "\n";
    my $k = $keys[0];
    print $text{$k}."\n";
    my $d = "../9share/$topic/hw";
    die "not a dir, $d" if ! -d $d;
    my $f = "$d/$name.tex";
    print ">>> put text in $f\n";
    print $text{$k}."\n";
    my $d = "../9share/$topic/hw";
    die "not a dir, $d" if ! -d $d;
    my $f = "$d/$name.tex";
    print ">>> put text in $f\n";
    my $tt = $text{$k};
    $tt =~ s/^\n+//; # trim leading newlines
    if (0) {
      open(F,">$f") or die "error opening $f for output, $!";
      print F "%%%%%\n%%%%% This problem is used by: ".join(' ',@keys)."\n%%%%%\n";
      print F $tt;
      close F;
    }
    for (my $i=0; $i<@keys; $i++) {
      my $k = $keys[$i];
      open(F,"<$file{$k}") or die "error opening input file, $!";
      my $t = <F>;
      close F;
      my $q = quotemeta ($text{$k});
      $t =~ s@$q@__incl(hw/$name)@;
      print "changing file $file{$k}\n";
      open(F,">$file{$k}") or die "error opening input file, $!";
      print F $t;
      close F;
    }
  }
}
