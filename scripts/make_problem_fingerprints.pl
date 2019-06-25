#!/usr/bin/perl

use Digest::SHA1;

use strict;

local $/;

my @k;
my %f;
my %file;

foreach my $f(<*/ch*/*.rbtex>) {
  $f =~ m@(.*)/ch(.*)/ch.*.rbtex@;
  my ($book,$ch) = ($1,$2);
  $ch = $ch+0;
  open(F,"<$f") or die "error opening $f, $!";
  my $t = <F>;
  close F;
  my $in = 0;
  foreach my $p(split(/<%\s*(?:begin|end)_hw/,$t)) {
    if ($in) {
      $p =~ /'([^']+)'/;
      my $name = $1;
      $p =~ s/^([^%]*)%>//g;
      $p =~ s/\s+//g;
      $p =~ s/\\(hwendpart|answercheck)//g;
      $p =~ s/\\\\//g;
      die "empty problem, $book,$ch,$name" if $p eq '';
      my $fingerprint = Digest::SHA1::sha1_base64($p);
      my $k = "$book,$ch,$name";
      push @k,$k;
      $f{$k} = $fingerprint;
      my $ff = $f;
      $file{$k} = $ff;
    }
    $in = !$in;
  }
}

foreach my $k(@k) {
  $k =~ /([^,]+)$/;
  my $name_k = $1;
  my $kf = $file{$k};
  foreach my $j(@k) {
    $j =~ /([^,]+)$/;
    my $name_j = $1;
    my $jf = $file{$j};
    if ($j>$k) {
      if ($f{$k} eq $f{$j}) {
        my $flag = '';
        if ($name_k ne $name_j) {$flag="******** names differ *********"}
        print "$k and $j , $kf $jf are identical $flag\n";
      }
      if ($f{$k} ne $f{$j} && $name_k eq $name_j) {
        print "$k and $j , $kf $jf are not identical, but have the same name ===============\n";
      }
    }
  }
}
