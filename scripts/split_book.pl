#!/usr/bin/perl

# This script has two algorithms in it, a n^2 and an n log n. I haven't
# benchmarked it, but I think they should perform the same on n=2,
# while the n log n one should do worse on n=4 by a factor of 12/10,
# but better on n=15 (Simple Nature's current size) by
# about a factor of 2. I should be able to improve
# the performance of the n log n algorithm by making it into a base-4
# algorithm instead of base-2, but the improvement would only be 20%.

use strict;
use POSIX;
use FindBin qw($Bin); 

our ($input_pdf,$nchunks,$kmax,$label);

my $debug = 0;

my $input_pdf = shift @ARGV; # first command-line argument
die "input file $input_pdf not found" unless  -e $input_pdf;
my $chunk_size = 50;
if (@ARGV) {
 $chunk_size = shift @ARGV; # optional second arg, pages per chunk
}
die "illegal chunk size=$chunk_size" unless $chunk_size>=1;

my $npages = `$Bin/pdf_page_count.rb $input_pdf`;
die if $npages eq '';
unless ($npages>=1 && $npages<=10000) {die "split_book.pl: npages=$npages fails sanity check for input file $input_pdf"}

# The following works, but takes n^2 time, where n is the number of pages.
if (0) {

$label = 'a';

for (my $p=1; $p<=$npages; $p+=$chunk_size) {
  my $output_pdf = $input_pdf;
  $output_pdf =~ s/\.pdf/${label}.pdf/;
  my $q = $p+$chunk_size-1;
  if ($q>$npages) {$q=$npages}
  my $cmd = "$Bin/pdf_extract_pages.rb $input_pdf $p-$q $output_pdf";
  #print "cmd=$cmd\n";
  system($cmd)==0 or die "error executing command $cmd, $!";
  $label = chr(ord($label)+1);
}

}

# This version takes n log n time.
if (1) {
  system("rm -f split_temp_*.pdf"); # otherwise any such files left over (e.g., from an aborted run) are assumed to be good
  $nchunks = int($npages/$chunk_size);
  ++$nchunks if ($nchunks*$chunk_size<$npages);
  $kmax = log2ceiling($nchunks); # number of binary digits needed to represent nchunks
  $label = 'a';
  for (my $n=0; $n<$nchunks; $n++) {
    my $t = get_chunk($n,$kmax);
    my $output_pdf = $input_pdf;
    $output_pdf =~ s/\.pdf/${label}.pdf/;
    my $cmd = "mv $t $output_pdf";
    print "$cmd\n";
    system($cmd)==0 or die "error executing command $cmd, $!";
    $label = chr(ord($label)+1);
  }
  system("rm split_temp_*.pdf");
}

sub get_chunk {
    my $n = shift;
    my $k = shift; # recursion depth
    return $input_pdf if $k==0;
    my $t = temp_file_name($n,$k);
    print "entering get_chunk, n=$n, k=$k, t=$t\n" if $debug;
    if (! -e $t) {
      my $mommy_n = int($n/2);
      my $mommy = get_chunk($mommy_n,$k-1);
      my $my_chunk_size = $chunk_size*pow2($kmax-$k);
      my $mommy_first_page = first_page($mommy_n,$k-1);
      my $mommy_last_page = $mommy_first_page+2*$my_chunk_size-1;
      $mommy_last_page = $npages if $mommy_last_page>$npages;
      my $mommy_n_pages = $mommy_last_page-$mommy_first_page+1;
      my $p = first_page($n,$k)-$mommy_first_page+1;
      my $q = $p+$my_chunk_size-1;
      $q = $mommy_last_page-$mommy_first_page+1 if $q>$mommy_last_page-$mommy_first_page+1;
      #print "mommy_first=$mommy_first_page mommy_last=$mommy_last_page q=$q\n";
      my $cmd = "$Bin/pdf_extract_pages.rb $mommy $p-$q $t";
      print "$cmd\n";
      system($cmd)==0 or die "error executing command $cmd, $!";
      #system("echo \"\" >$t");
    }
    else {
      print "          file $t already existed\n" if $debug;
    }
    if ($debug) {
      print "          counting pages in file $t...\n";
      my $npages = `$Bin/pdf_page_count.rb $t`;
      print "          leaving get_chunk, n=$n, k=$k, t=$t, npages=$npages\n";
    }
    return $t;
}

sub first_page {
  my $n = shift;
  my $k = shift;
  my $my_chunk_size = $chunk_size*pow2($kmax-$k);
  return $n*$my_chunk_size+1;
}

sub pow2 {
  my $x = shift;
  die "negative power in pow2" if $x<0;
  return 1 if $x==0;
  return 2*pow2($x-1);
}

sub temp_file_name {
  my $n = shift;
  my $k = shift;
  my $e = to_binary_string($n);
  while (length($e)<$k) {$e='0'.$e}
  return "split_temp_$e.pdf";
}

sub to_binary_string {
  my $x = shift;
  return '0' if $x==0;
  return '1' if $x==1;
  return to_binary_string(int($x/2)).to_binary_string($x%2);
}

sub log2ceiling {
  my $x = shift;
  return 1 if $x<2;
  return 1+log2ceiling($x/2);
}
