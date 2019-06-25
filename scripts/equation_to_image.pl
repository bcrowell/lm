#!/usr/bin/perl

if (!@ARGV) {
  print "Usage:  equation_to_image file.tex foo/bar/lmmath.sty\n";
  exit;
}

my $file = $ARGV[0];
my $sty = $ARGV[1];

die "$file doesn't exist" if !-e $file;
die "$sty doesn't exist" if !-e $sty;

my $base = '';
if ($file=~m/(.*)\.tex/) {
  $base = $1;
}
else {
  die "$file doesn't end in .tex"
}
my $image = "$base.png";


my $temp_dir = "temp_directory";

if (-d $temp_dir) {
  system("rm $temp_dir/*");
  system("rmdir $temp_dir")
}
system("mkdir $temp_dir");

system("cp $file $temp_dir && cp $sty $temp_dir");
# workaround for apparent bug in dvipng, if you use -D110, it does something goofy
my $x = 2;
my $res = 110*$x;
my $reduce = int(100/$x);
system("cd $temp_dir && htlatex $file && dvipng -q -D $res -o temp.png -T tight -pp 1 $base.idv -bg Transparent && convert temp.png -resize $reduce% $image && mv $image ..");
# dvipng options:
#   -q   quiet
#   -D   resolution
#   -o   output file
#   -T   image size
#   -pp  page range
#   -bg  background color

if (!-e $image) {
  print "WARNING: image file $image not created, in equation_to_image.pl; this is probably because tex4ht isn't installed." 
}

if (-d $temp_dir) {
  system("rm $temp_dir/*");
  system("rmdir $temp_dir")
}
