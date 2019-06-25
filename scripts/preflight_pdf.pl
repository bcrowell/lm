#!/usr/bin/perl

use strict;

# usage:
#   preflight_pdf.pl book.pdf
# The main useful thing this does right now is to check for subsetted fonts.
# Also runs it through qpdf --check, but in my experience that's never helpful.

my $pdf = $ARGV[0];

-e $pdf or err("file $pdf doesn't exist");
-r $pdf or err("file $pdf is not readable");
is_in_path("pdffonts") or err("pdffonts doesn't seem to be installed");
is_in_path("qpdf") or err("qpdf doesn't seem to be installed");

my $err;

$err = check_using_qpdf($pdf);
if ($err) {err($err)}
$err = check_fonts($pdf);
if ($err) {err($err)}

sub check_using_qpdf {
  my $pdf = shift;
  unless (system("qpdf --check $pdf 1>/dev/null")==0) { # prints crap to stdout when there's no error
    return "error in qpdf"; # the error went to stdout, so user will see it above this
  }
  return undef;
}

sub check_fonts {
  my $pdf = shift;
  my $fonts = `pdffonts $pdf`;
  $fonts =~ s/\A[^\n]*\n[^\n]*\n//; # strip two header lines
  my @errors = ();
  while ($fonts=~/([^\n]+)/g) {
    my $line = $1;
    # print "line=$line=\n"; # qwe
    $line =~ /^([^\s]+).*\s+(yes|no)\s+(yes|no)\s+(yes|no)\s+/i or return "malformed line in pdffonts output, =$line=";
    my ($font,$emb,$sub,$uni) = ($1,yesno($2),yesno($3),yesno($4));
    $font =~ s/^[^\+]+\+//; # e.g., XELXZK+EURM7 -> EURM7
    $emb or push @errors,"font $font is not embedded";
    $sub and push @errors,"font $font is subsetted";
  }
  if (@errors>0) {
    my $result = "errors in fonts:\n".join("\n",@errors)."\n";
    $result = $result . "If this font is OK to use:\n  Save a copy of fullembed.map and then do\n  ../scripts/create_fullembed_file <mybook.log >../fullembed.map\n  and merge.\n";
    $result = $result . "If this font is not OK to use, then use page_where_font_is_used.rb to locate the page where it occurs.\n";
    return $result;
  }
  return undef;
}

sub is_in_path {
  my $exe = shift;
  my $x=`which $exe`;
  chomp $x; 
  return -x $x;
}

sub yesno {
  my $string = shift;
  return 1 if $string=~/^yes$/i;
  return 0 if $string=~/^no$/i;
  err("yesno got invalid input, $string");
}

sub err {
  my $message = shift;
  print "preflight_pdf.pl, checking file $pdf: ",$message,"\n";
  exit(-1);
}
