#!/usr/bin/perl

use strict;

# usage:
#   preflight_one_fig.pl foo.svg
# Checks whether there is no rendered version of foo.svg.
# Checks whether it was rendered in more than one version.
#   ... I'm no longer counting this as an error
# Checks whether it was rendered to foo.png. If so, complains if it has transparency.
# Checks whether there is also a foo.pdf. If there is, checks foo.svg and foo.pdf for problems:
#   transparency (checked for in the svg)
#   fonts embedded in pdf
#   bad pdf structure
#   pdf older than svg
#   pdf version is not 1.4
# There is a facility for running each pdf through pdftk, but I currently have it
# turned off because it's slow and doesn't seem to actually find any problems.
# If there's a problem, prints a message to stdout and exits with nonzero error code.

# requires the following tools:
#   xml_grep (part of ubuntu package xml-twig-tools)
#   qpdf (ubuntu package qpdf)
#   pdffonts (ubuntu package poppler-utils)
#   identify and mogrify (ubuntu package imagemagick)

my $svg = $ARGV[0];

my $pdf = $svg;
$pdf =~ s/\.svg$/.pdf/;

# We want it to be rendered into exactly one format.
my @formats = ();
foreach my $fmt('pdf','png','jpg') {
  my $rendered = $svg;
  $rendered =~ s/\.svg$/.$fmt/;
  push @formats,$fmt if -e $rendered;
}
if (@formats==0) {err("not rendered into pdf, png, or jpg")}
if (@formats>1) {
  # foreach my $fmt(@formats) {  my $rendered = $svg;  $rendered =~ s/\.svg$/.$fmt/; unlink($rendered)}
  #err("rendered into more than one format: ".join(',',@formats));
}

if (-e $pdf) {
  my $err = check_pdf($svg,$pdf);
  if ($err) {err($err)}
  exit(0);
}
else {
  # There's no pdf, so there'd better be a .jpg or .png
  foreach my $e('jpg','png') {
    my $bitmap = $svg;
    $bitmap =~ s/\.svg$/.$e/;
    if (-e $bitmap) {
      if ($e eq 'png') {
        my $f = `identify -format '%[channels]' $bitmap`;
        if ($f=~/rgba/) {
          my $c = "mogrify -background white -flatten -alpha off $bitmap";
          print "removing transparency from file $bitmap\n";
          system($c)==0 or err("error executing command $c");;
        }
      }
      exit(0);
    }
  }
  err("file $svg does not exist as .pdf, .jpg, or .png");
}

sub err {
  my $message = shift;
  print "preflight_one_fig.pl, svg file $svg, ",$message,"\n";
  exit(-1);
}

sub check_pdf {
  my ($svg,$pdf) = @_;
  # The following check did not seem reliable, possibly because modification dates are unreliable or change in git??
  #  my $err = check_for_stale_pdf($svg,$pdf);
  #  return $err if $err;
  my $err = check_pdf_version($svg,$pdf);
  return $err if $err;
  my $err = check_pdf_for_fonts($svg,$pdf);
  return $err if $err;
  my $err = check_pdf_for_transparency($svg,$pdf);
  return $err if $err;
  my $err = check_pdf_for_structure($svg,$pdf);
  return $err if $err;
  if (0) { # slow and doesn't seem to catch any errors
    my $err = check_pdf_in_pdftk($svg,$pdf);
    return $err if $err;
  }
  return undef;
}

# This is slow and doesn't seem to catch any errors, so I'm
# not currently using it.
sub check_pdf_in_pdftk {
  my ($svg,$pdf) = @_;
  if (system("pdftk $pdf cat output /dev/null 2>/dev/null")!=0) {
    return "pdftk error on file $pdf";
  }
  return undef;
}

sub check_pdf_version {
  my ($svg,$pdf) = @_;
  my $pdf_version = detect_pdf_version($pdf);
  $pdf_version eq '1.4' or return "pdf version='$pdf_version'; see https://bugs.launchpad.net/inkscape/+bug/1110549";
  return undef;
}

sub check_for_stale_pdf {
  my ($svg,$pdf) = @_;
  # -M is relative age of file in days, floating point
  my $diff = ((-M $svg)-(-M $pdf));
  $diff<0.000001 or return 
         "file $pdf is older than file $svg, ".(-M $svg)." > ".(-M $pdf).", diff=".$diff;
  return undef;
}

sub check_pdf_for_structure {
  my ($svg,$pdf) = @_;
  system("qpdf --check $pdf 1>/dev/null 2>/dev/null")==0 or return "bad structure for $pdf detected by qpdf --check:\n";
  return undef;
}

sub check_pdf_for_fonts {
  my ($svg,$pdf) = @_;
  my $fonts = `pdffonts $pdf`;
  $fonts =~ /\A.*\n.*\n(.*)/; # strip header lines
  my $f = $1;
  if ($f ne '') {return "embedded fonts found in file $pdf, made from $svg"}
  return undef;
}

# This actually involves checking the svg, not the pdf (because it's easier). We only
# come here if it's been rendered to a pdf. If it fails this check, it needs to be
# rendered as a bitmap.
sub check_pdf_for_transparency {
  my ($svg,$pdf) = @_;

  # for efficiency, first do a rough check:
  return undef unless `grep -e "opacity:[^1]" $svg`;

  # Now do a more reliable check.
  # There are at least four types of opacity: stop-opacity, fill-opacity, stroke-opacity, and opacity (applied to whole groups).
  my $transp = `xml_grep --cond='*[\@style]' $svg  | grep -e "opacity:[^1]"`;
  if ($transp ne '') {
    # Often we get something like this:
    #     style="fill:none;fill-opacity:0.75"
    # This is harmless because there is no fill, so the transparency of the fill is irrelevant.
    while ($transp=~/style\s*=\s*"([^"]*)"/gi) {
      my $style = $1;
      my %styles = ();
      foreach my $item(split /;/,$style) {
        if ($item=~/(.*):(.*)/) {$styles{lc($1)} = lc($2)}
      }
      if (defined $styles{'opacity'} && $styles{"opacity"}<1) {
        return report_transparency($svg,$style);
      }
      foreach my $sf('stop','stroke','fill') {
        if (   $styles{$sf} ne 'none' # works correctly if undef
            && defined $styles{"${sf}-opacity"}
            && $styles{"${sf}-opacity"}<1 ) { 
          return report_transparency($svg,$style);
        }
      }
    }
  }
  return undef;
}

sub report_transparency {
  my ($svg,$style) = @_;
  $style =~ /(.{0,22}opacity:[^1].{0,10})/;
  my $shorter = $1;
  return "transparency found in file $svg, so it should have been rendered as a bitmap, not a pdf : ...$shorter...";
}

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
