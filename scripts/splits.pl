#!/usr/bin/perl

use strict;
use FindBin qw($Bin); 

my $input_file = $ARGV[0];
my $vol = $ARGV[1];
my $output_file = $ARGV[2];


# reads save.ref and splits.config
#
# format of splits.config:
#    v1,v2,label1,offset1,label2,offset2,mod8
#    (v1,v2)=(1,1) means only include these pages in volume 1
#    (v1,v2)=(2,2) means only include these pages in volume 2
#    (v1,v2)=(1,2) means include these pages in both volumes
#    label1=latex label of beginning of range, or null
#    offset1=offset from label1; if label1 is null string and offset is +, then take offset1 as page number; if label1 is 'end' and offset is '', take last page
#    label2,offset2=similar for end of range
#    mod8=if not null, force it to start on a page of the output pdf that equals this, modulo 8
#      You typically want the output pdf to have a number of pages that is a multiple of 8. So, e.g., if LM has three pages of data, etc., at the end,
#      set mod8 to 5, so that the third page will equal 7 mod 8.

my %refs = ();
open(F,"<save.ref") or die "error opening save.ref for input";
while (my $line = <F>) {
  chomp $line;
  if ($line =~ /([^,]*),([^,]*),([^,]*)/) {
    my ($label,$name,$page) = ($1,$2,$3);
    $refs{$label} = $page;
  }
}
close(F);

open(F,"<splits.config") or die "error opening splits.config for input";
my @pages = ();
my $n = 0;
while (my $line = <F>) {
  chomp $line;
  if ($line =~ /([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)/) {
    my ($v1,$v2,$l1,$o1,$l2,$o2,$m) = ($1,$2,$3,$4,$5,$6,$7);
    #print "$v1,$v2,$l1,$o1,$l2,$o2,$m\n";
    my $p1 = find_page($l1,$o1);
    my $p2 = find_page($l2,$o2);
    #print "pages $p1-$p2\n";
    my $chunk = 0;
    if ($vol>=$v1 && $vol<=$v2) {
      if ($p1%2 != 1) {push @pages,"B1"; ++$chunk}
      if ($m ne '') {
        while (($n+$chunk)%8!=$m) {push @pages,"B1"; ++$chunk}
      }
      push @pages,"$p1-$p2";
      if ($p2 ne 'end') {
        $chunk += (($p2-$p1)+1);
        if ($chunk%2!=0) {push @pages,"B1"; ++$chunk}
      }
      print "input $p1-$p2 -> output ",($n+1),"-",($p2 eq 'end' ? 'end' : $n+$chunk),"\n";
      $n += $chunk;
    }
  }
}
close(F);

my $blank_page_pdf = "../share/misc/blank_page.pdf";
if (0) { # use pdftk
  # pdftk lm.pdf B=../share/misc/blank_page.pdf  cat 3-14 B1 554-1012 1013-1022 B1 B1 B1 1023-end output lulu_lm_v2.pdf
  my $c = "pdftk $input_file B=$blank_page_pdf  cat ".join(' ',@pages)." output $output_file";
  print "$c\n";
  system $c;
}
if (1) { # use qpdf
  my $k = 0;
  my @pieces = ();
  foreach my $p(@pages) {
    my $partial = "splits_temp_$k.pdf";
    ++$k;
    if ($p eq 'B1') { # pdftk idiom for 1st page of file B
      system("cp $blank_page_pdf $partial")==0 or die("splits.pl: error copying $blank_page_pdf to $partial");
    }
    else {
      $p =~ s/end/z/; # translate pdftk idiom to qpdf
      my $c = "$Bin/pdf_extract_pages.rb $input_file $p $partial";
      system($c)==0 or die("splits.pl: error in command $c");
    }
    push @pieces,$partial;
  }
  my $c = "qpdf $input_file --pages ".join(' ',@pieces)." -- $output_file";
  system($c)==0 or die("splits.pl: error in command $c");
  foreach my $partial(@pieces) {system("rm $partial")}
}

sub find_page {
  my $l = shift;
  my $o = shift;
  if ($l eq '') {return $o}
  if ($l eq 'end') {return 'end'}
  if (!exists $refs{$l}) {die "label $l doesn't exist in save.ref"}
  return $refs{$l}+$o;
}

sub barf {
  my $message = shift;
  print STDERR "splits.pl: $message\n";
  print STDERR "You will need to edit splits.config.\n";
  exit(-1);
}
