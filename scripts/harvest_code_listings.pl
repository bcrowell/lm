#!/usr/bin/perl

# Find files like code_listing_ch02_4_brachistochrone.py

use strict;

my $found_any = 0;

my $dir = "code_listings";
if (! -d $dir) {system("mkdir $dir")}
if (! -d $dir) {die "error creating subdirectory $dir"}

foreach my $f(<code_listing_*>) {
  $f =~ /code_listing_(.*)/;
  my $g = $1;
  system("mv $f $dir/$g");
  $found_any = 1;
}

if ($found_any) {system("zip -qr code_listings.zip $dir")==0 or die "error zipping up directory $dir"}
system("rm -f $dir/* && rmdir $dir");
