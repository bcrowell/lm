#!/usr/bin/perl

use strict;

while (my $line=<>) {
chomp $line;

while ($line=~m/([\d\.\-\+]+)pt/g) {
  my $value = $1;
  $value = $value*25.4/72.27;
  print (sprintf "%7.2f",$value).' ';
}

print "\n";
}


