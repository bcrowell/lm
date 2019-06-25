#!/usr/bin/perl

use strict;
use File::Temp qw/ tempfile tempdir /;
use Digest::MD5;
use File::Copy;
use JSON;

my $config = from_json(get_input("temp.config")); # hash ref
my $forbid_mathml = ($config->{'forbid_mathml'}==1);

if (!@ARGV) {
  print <<USAGE;
Usage:
  latex_table_to_html.pl file.tex foo/bar/lmmath.sty html
  latex_table_to_html.pl file.tex foo/bar/lmmath.sty xhtml
USAGE
  exit;
}

my $raw_file = $ARGV[0];
my $sty = $ARGV[1];
my $fmt = $ARGV[2];

die "$raw_file doesn't exist" if !-e $raw_file;
die "$sty doesn't exist" if !-e $sty;

my $base = '';
if ($raw_file=~m/(.*)\.tex/) {
  $base = $1;
}
else {
  die "$raw_file doesn't end in .tex"
}

my  $temp_dir = File::Temp::tempdir(CLEANUP => 1);


my  $input = get_input($raw_file);
#--------------
  # Look for math . Convert an expression like
  # $x$ into 78001124576..., where the octal hash is guaranteed to be passed through htlatextex unscathed,
  # because htlatex thinks it's just a string of digits making up some big decimal number. At the end, replace
  # the octal code with the html or mathml translation of the math it represents.
  my $nemb = 0;
  my @emb;
  my @emb_octal;
  while ($input=~/(\$([^\$]+)\$)/) {
      my ($dollar,$math) = ($1,$2);
      # conceptually, the following is like $input=~s/$dollar/$octal/, but that wouldn't work, because $dollar has metacharacters in it
      my $i=index($input,$dollar);
      my $z = '';
      if ($i>0) {$z = $z . substr($input,0,$i-1)}
      my $o = octal_md5($math);
      $z = $z . $o;
      if ($i+length($dollar)<length($input)) {$z = $z . substr($input,$i+length($dollar),length($input)-($i+length($dollar)))}
      $input = $z;
      ++$nemb;
      my $m = $math;
      # prepare a fallback version in case footex doesn't work:
      $m =~ s/[^a-zA-Z0-9 ]//g;
      my $t = "$temp_dir/$o.tex";
      open(FILE,">$t") or die "error $!, opening $t for output";
      print FILE $math;
      close FILE;
      if ($fmt eq 'html' || $forbid_mathml) {
        my $mm = `footex --prepend-file $sty --html $t`;
        $m=$mm if $mm ne '';
      }
      if ($fmt eq 'xhtml' && !$forbid_mathml) {
        my $mm = `footex --prepend-file $sty --mathml $t`;
        $m='<math xmlns="http://www.w3.org/1998/Math/MathML">'.$mm.'</math>' if $mm ne '';
      }
      unlink $t;
      push @emb,$m;
      push @emb_octal,$o;
  }

#--------------


my $file = octal_md5($input).".tex";
open(FILE,">$temp_dir/$file") or die "error opening $temp_dir/$file for output";
print FILE $input;
close FILE;
system("cp $sty $temp_dir");
my $f = '';
$f='xhtml' if $fmt eq 'xhtml';
my $html = $file;
$html =~ s/\.tex$/\.html/;
my $final_html = $raw_file;
$final_html =~ s/\.tex$/\.html/;

#print STDERR "=============\nbefore htlatex, input=\n$input\n===================";

system("cd $temp_dir && htlatex $temp_dir/$file $f >/dev/null && cd -")==0 or die "error in latex_table_to_html";
File::Copy::move("$temp_dir/$html",$final_html);

open(HTML,"<$final_html") or die "error opening $final_html for input, $!";
local $/;
my $h = <HTML>;
close HTML;

#print STDERR "=============\nafter htlatex, html=\n$h\n===================";

#--------------
  for (my $i=0; $i<@emb; $i++) {
    my $o = $emb_octal[$i];
    my $m = $emb[$i];
    $h =~ s/$o/$m/;
  }

#print STDERR "=============\nafter putting math back in, html=\n$h\n===================";

#----------- print $h;

if (!($h=~/<body\s*>(.*)<\/body>/s)) {
  print "WARNING: couldn't find body of html in file $final_html; probably tex4ht isn't installed\n";
  exit(0); # allow it to run
}
my $table= $1;
$table =~ s/<div class="tabular">//;
$table =~ s/<\/div>\w*\Z//;
$table =~ s/<div [^>]*>//g;
$table =~ s/<\/div>//g;
$table =~ s/id="TBL-[^"]*"//g; # invalid markup if not unique
$table =~ s/^\s*//;
$table =~ s/\s*$//;
$table =~ s/\n{2,}/\n/gs;
$table =~ s/<td>([^<>]+)<\/t>/<td>$1<\/td>/g; # bug in htlatex?

#print STDERR "=============\nfinal html=\n$table\n===================";

open(HTML,">$final_html") or die "error opening $final_html for output, $!";
print HTML $table;
close HTML;

if (-d $temp_dir) {
  system("rm -f $temp_dir/*");
}

sub get_input {
  my $file = shift;
  local $/;
  die "latex_table_to_html.pl: file $file doesn't exist" unless -e $file;
  open(FILE,"<$file") or die "error $! opening $file for input";
  my $input = <FILE>;
  close FILE;
  return $input;
}

sub octal_md5 {
  my $x = shift;
  my $y = Digest::MD5::md5_hex($x);
  $y = '0'.$y if length($y)%2==1;
  my $z = '';
  while ($y=~m/(..)/g) {
    my $h = $1;
    $z = $z . sprintf "%o",hex($h);
  }
  return $z;
}
