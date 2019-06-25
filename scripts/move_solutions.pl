#!/usr/bin/perl

use strict;
use Cwd;

use BookData;

my $solns_dir = "/home/bcrowell/Documents/teaching/solns";

my %move;

foreach my $book(@list_of_book_names) {
  my $bookd = $book_name_to_directory{$book}; # e.g., 2cl
  for (my $ch=0; $ch<=13; $ch++) {
    my $ch2 = sprintf "%02d",$ch;
    my $d = "$solns_dir/$book/$ch2";
    if (-d $d) {
      # print "$book $ch\n";
      foreach my $f(<$d/*.tex>) {
        $f =~ m@/([^/]+)\.tex@;
        my $name = $1;
        my $topic = $topic_map{$bookd}->{$ch};
        die "undefined topic" if !defined $topic;
        my $key = "$topic/$name";
        if (!exists $move{$key}) {$move{$key}=[]}
        my $r = $move{$key};
        push @$r,$f;
      }
    }
  }
}

foreach my $key(sort keys %move) {
  my $r = $move{$key};
  my @r = @$r;
  print "$key ".join(' ',@r)."\n  ";
  my $what;
  if (@r>1) {
    my $differs = 0;
    for (my $i=1; $i<@r; $i++) {
      $differs = $differs || `diff $r[0] $r[$i]`=~/[^\s]/;
    }
    if ($differs) {$what='d'; print "differs"} else {$what='i'; print "identical"}
  }
  else {
    $what='u';
    print "unique";
  }
  print "\n";
  my $c;
  if (0 && $what eq 'u') {
    $c = "mv $r[0] $solns_dir/$key.tex";
  }
  if (0 && $what eq 'i') {
    $c = "mv $r[0] $solns_dir/$key.tex";
    for (my $i=1; $i<@r; $i++) {
      $c = $c . " && rm $r[$i]";
    }    
  }
  if ($what eq 'd') {
    my $t = "\\begin{soln}";
    for (my $i=0; $i<@r; $i++) {
      my $z = 'lm_series';
      if ($r[$i]=~m/cp/) {$z='cp'}
      if ($r[$i]=~m/sn/) {$z='sn'}
      my $s = `cat $r[$i]`;
      $s =~ s/\\(begin|end){soln}\n?//g;
      $t = $t . "%\n%------------------- $z ------------------------\nm4_ifelse(__$z,1,[:%\n" . $s . ":])m4_dnl\n%-----------------------------------------------------\n";
    }
    $t = $t . "\\end{soln}\n";
    open(F,">$solns_dir/$key.tex") or die "error opening file for output, $!";
    print F $t;
    close F;
    for (my $i=0; $i<@r; $i++) {
      system "rm $r[$i]";
    }    
    #die "did  one, $key, $r[0], $r[1]";
  }
  if ($c) {
    print "  $c\n";
    #system $c;
  }
  print "\n\n\n\n\n\n";
}
