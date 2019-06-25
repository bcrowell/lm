#!/usr/bin/perl

use strict;

# usage:
#   pdf_to_bitmap.pl foo.pdf
#   pdf_to_bitmap.pl foo.pdf jpg
#   pdf_to_bitmap.pl foo.pdf png
#   pdf_to_bitmap.pl foo.pdf png 1
# default format is png
# quality for jpg is set to imagemagick's default of 92
# If the file foo.jpg or foo.png exists and is newer than foo.pdf, then nothing is done, and this is not an error.
#   [currently I have the date checking commented out...why?]
# If the file foo.jpg or foo.png exists and foo.pdf doesn't exist, then nothing is done, and this is not an error.
# Adding the 1 as the third command-line arg forces rendering even if it seems up to date.

my $pdf = $ARGV[0];
my $dest_fmt = $ARGV[1];
if ($dest_fmt=='') {$dest_fmt='png'}
my $force = ($ARGV[2] eq '1');

my @temp_files = ();

unless ($pdf =~ /\.pdf$/) {finit("Error in pdf_to_bitmap.pl, input file doesn't have extension .pdf")}

my $rendered = $pdf;
$rendered =~ s/\.pdf$/.$dest_fmt/;


if ((!$force) && -e $rendered && (! (-e $pdf))) {exit(0)}
###if (-e $rendered && -M $pdf > -M $rendered) {exit(0)} # -M finds age in days

print "rendering $pdf to $rendered\n";

# Don't use inkscape --export-png, because as of april 2013, it messes up on transparency.
# Can convert pdf directly to bitmap of the desired resolution using imagemagick, but it messes up on some files (e.g., huygens-1.pdf), so
# go through pdftoppm first.
my $ppm = 'z-1.ppm'; # only 1 page in pdf
push @temp_files,$ppm;
if (system("pdftoppm -r 300 $pdf z")!=0) {finit("Error in pdf_to_bitmap.pl, pdftoppm")}

# Work around misfeature in ImageMagick's convert. See notes in computer/apps. It's possible that ca. 2015
# ImageMagick's color handling will change, and I will need to get rid of this code.
# Detect whether or not it's color:
my $stats = `identify -colorspace HSL -verbose $ppm`;
$stats =~ s/\n//g; # strip newlines
my $is_color = !($stats=~quotemeta("Green:      min: 0 (0)      max: 0 (0)"));
  # when ImageMagick's identify utility is given the -colorspace HSL, saturation is in the green channel
my $gamma_correction = 1.0;
if (!$is_color) {$gamma_correction=0.44} # grayscale images are much too dark otherwise

if (system("convert $ppm -density 300 -evaluate Pow $gamma_correction -units PixelsPerInch $rendered")!=0) {finit("Error in pdf_to_bitmap.pl, ImageMagick's convert")}
# ... uses default quality of 92

# It seems that some tool on my toolchain has had inconsistencies/regressions in its behavior with respect to
# how it handles gamma. I think this was probably inkscape, although imagemagick has also had some flaky changes
# in how it handles color management.
# Currently I have this:
#   $ inkscape --version
#   Inkscape 0.48.4 r9939 (Jan 22 2014)
#   $ convert --version
#   Version: ImageMagick 6.7.7-10 2014-03-06 Q16 http://www.imagemagick.org
#   $ pdftoppm -v
#   pdftoppm version 0.24.5
# With these versions, it seems OK if I set gamma_correction to 1.0. With some other versions, previously,
# I needed 0.44.

print "\n";
finit();

sub finit {
  my $message = shift;
  tidy();
  if ($message eq '') {
    exit(0);
  }
  else {
    die $message;
  }
}

sub tidy {
  foreach my $f(@temp_files) {
    unlink($f) or die "error deleting $f, $!";
  }
}
