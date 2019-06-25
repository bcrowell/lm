#!/usr/bin/perl

use strict;

my @x;

while (my $l=<>) {
  push @x,$l;
}

@x = sort {
  my ($a_bk,$a_ch,$a_num,$a_name) = split(/,/,$a);
  my ($b_bk,$b_ch,$b_num,$b_name) = split(/,/,$b);
  my $bk_sort_order = {lm=>0,me=>1,sn=>2,cp=>3,dp=>4};
  my $a_bk_num = $bk_sort_order->{$a_bk};
  my $b_bk_num = $bk_sort_order->{$b_bk};
  die "undefined book, $a_bk or $b_bk" if !defined $a_bk_num || !defined $b_bk_num;
  return $a_bk_num <=> $b_bk_num if $a_bk_num != $b_bk_num;
  $a_ch = $a_ch+0;
  $b_ch = $b_ch+0;
  return $a_ch <=> $b_ch if $a_ch!=$b_ch;
  $a_num = $a_num+0;
  $b_num = $b_num+0;
  return $a_num <=> $b_num if $a_num!=$b_num;
  return $a_name <=> $b_name;
} @x;

foreach my $l(@x) {
  print $l;
}
