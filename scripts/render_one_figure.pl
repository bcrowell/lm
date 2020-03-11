#!/usr/bin/perl

use strict;

# usage:
#   render_one_figure.pl foo.svg
#   render_one_figure.pl foo.svg 1
# Renders it unless rendering already exists and is newer than svg. Attempts to render it to pdf first. If that
# fails preflight, or if $always_make_png is set, redoes it as a bitmap.
# I currently have $always_make_png=1, because certain figures, such as hw-cliff-pond, pass preflight
# but don't RIP correctly on lulu.
# Adding the 1 as the second command-line arg forces rendering even if it seems up to date.

use FindBin;
use File::Glob;
use File::Copy;
use File::Temp qw(tempdir);

my $always_make_png = 1;

my $not_for_real = 0;

my $svg = $ARGV[0];
my $force = ($ARGV[1] eq '1');

my @temp_files = ();

my $exists = 0;
foreach my $e('pdf','jpg','png') {
  next if $always_make_png && $e eq 'pdf';
  my $rendered = $svg;
  $rendered =~ s/\.svg$/.$e/;
  $exists = $exists || -e $rendered;
  if ((!$force) && -e $rendered && -M $svg > -M $rendered) {exit(0)} # -M finds age in days
}

if ($exists) {
  print "rendering figure $svg , which has a rendering older than the svg\n";
}
else {
  print "rendering figure $svg\n";
}

my $pdf=$svg;
$pdf=~s/\.svg$/.pdf/;
unless (-e $pdf && -M $svg > -M $pdf) { # 
  # Inkscape normally expects preferences file to be in ~/.config/inkscape/preferences.xml .
  # We need to override this, because otherwise it could contain inappropriate options for this purpose.
  # There is an undocumented mechanism for overriding it using an environment variable:
  #   https://bugs.launchpad.net/inkscape/+bug/382394
  # Create dir for temporary prefs file. Other files will be created there.
  my $temp_dir = tempdir( CLEANUP => 1 );
  my $c="INKSCAPE_PROFILE_DIR=$temp_dir inkscape  --g-fatal-warnings --export-text-to-path --export-pdf=$pdf $svg  --export-area-drawing 1>/dev/null"; 
  print "  $c\n"; 
  unless ($not_for_real) {
    my $good_prefs = "$FindBin::RealBin/inkscape_rendering_preferences.xml";
    -r $good_prefs or die "file $good_prefs not found or not readable";
    copy($good_prefs,"$temp_dir/preferences.xml") or die "error copying $good_prefs to $temp_dir, $!";
    -e "$temp_dir/preferences.xml" or die "copied $good_prefs to $temp_dir, but it's not there?";
    system($c)==0 or die "error in render_one_figure.pl, rendering figure using command $c";
  }
  # Check that inkscape output pdf 1.4, since pdftk has buggy support for 1.5.
  # See https://bugs.launchpad.net/inkscape/+bug/1110549
  # Don't just depend on preflight_one_fig.pl to do this, because that would result in it being rendered to bitmap.
  # The following should actually never fail, because code above temporarily overwrites users prefs.
  my $pdf_version = detect_pdf_version($pdf);
  $pdf_version eq '1.4' or die "error in render_one_figure.pl, inkscape output pdf version='$pdf_version'; see https://bugs.launchpad.net/inkscape/+bug/1110549";
}

-x "scripts/preflight_one_fig.pl" or die "couldn't find scripts/preflight_one_fig.pl -- are you running me from home dir?";

my $failed_preflight = (system("scripts/preflight_one_fig.pl $svg")!=0);

if ($failed_preflight) {
  print "  preflight failed on pdf rendering of $svg , probably due to transparency; rendering to bitmap instead\n";
}

if (!$always_make_png && !$failed_preflight) {finit('')}

push @temp_files,$pdf;
my $png = $svg;
$png=~s/\.svg$/.png/;

# Don't use inkscape --export-png, because as of april 2013, it messes up on transparency.
# Can convert pdf directly to bitmap of the desired resolution using imagemagick, but it messes up on some files (e.g., huygens-1.pdf), so
# go through pdftoppm first.
my $ppm = 'z-1.ppm'; # only 1 page in pdf
push @temp_files,$ppm;
if (system("pdftoppm -r 300 $pdf z")!=0) {finit("Error in render_one_figure.pl, pdftoppm")}
if (system("convert $ppm $png")!=0) {finit("Error in render_one_figure.pl, ImageMagick's convert")}
if (system("mogrify -density 300x300 -units PixelsPerInch $png")!=0) {finit("Error in render_one_figure.pl, ImageMagick's mogrify")}

print "\n";
finit();

# code duplicated in preflight_one_fig.pl
sub detect_pdf_version {
  my $pdf = shift;
  open (my $F,"<$pdf") or return undef;
  my $version_line = <$F>; # should be %PDF-1.4
  close $F;
  $version_line =~ /^\%PDF\-(\d+\.\d+)/i or return undef;
  my $version = $1;
  return $version;
}

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
