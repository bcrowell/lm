#!/usr/bin/perl

use strict;

# requires the following tools:
#   xml_grep (part of ubuntu package xml-twig-tools)
#   qpdf (ubuntu package qpdf)
#   pdffonts (ubuntu package poppler-utils)

my $expected_files = 1100;
my @files = <*/*/figs/*.svg>;

my $count_svg = 0;
my $count_err = 0;

-x "scripts/preflight_one_fig.pl" or die "couldn't find scripts/preflight_one_fig.pl -- are you running me from home dir?";
-x "scripts/relativise_svg.pl" or die "couldn't find scripts/relativise_svg.pl -- are you running me from home dir?";

foreach my $svg(@files) {
  ++$count_svg;
  system("scripts/relativise_svg.pl $svg");
  my $err = `scripts/preflight_one_fig.pl $svg`;
  if ($err) {
    print "$err\n";
    ++$count_err;
  }
}

die "only found $count_svg files, expected at least $expected_files; did you not run me from the root directory?" if $count_svg<$expected_files;

print "$count_svg svg files checked\n";

die "$count_err errors found" if $count_err>0;
