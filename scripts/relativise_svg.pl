#!/usr/bin/perl

use strict;

# usage:
#   relativise_svg.pl foo.svg
# Looks for absolute links in svg file and makes them relative.
# Also checks whether files linked to exist.

# http://superuser.com/questions/742356/how-to-enforce-relative-file-paths

use File::Spec; 
use File::Basename;
use Cwd 'abs_path';
my $svg = $ARGV[0];

-e $svg or err("file $svg doesn't exist");
-w $svg or err("file $svg not writeable");

local $/; # slurp whole file

open(F,"<$svg");
my $xml = <F>;
close F;

# Absolute links look like this:
#   xlink:href="file:///home/bcrowell/Documents/writing/books/physics/share/..."
# After we relativise them, they look like this:
#   xlink:href="foo/bar.jpg"

my $cwd = Cwd::getcwd();
my $svg_dir = File::Basename::dirname(abs_path($svg));
my $original_xml = $xml;

my @changes = ();
while ($xml=~m@(file://(/[^'"]*))@g) {
  my $whole = $1;
  my $path = $2;
  my $rel = relativise($path,$svg_dir,$cwd);
  print "changing absolute path in $svg to $rel\n";
  push @changes,[$whole,$rel];
}
foreach my $change(@changes) {
  my $from = quotemeta($change->[0]);
  my $to = $change->[1];
  $xml =~ s/$from/$to/g;
}

while ($xml=~m@xlink:href\s*=\s*"([^'"]*)@g) {
  my $rel = $1;
  if ($rel=~/\.(png|jpg)$/ && !($rel=~/\A#/ || $rel=~/\Adata:;/)) {
    my $abs = File::Spec->rel2abs($rel,$svg_dir);
    -e $abs or err("file $rel doesn't exist, resolved to absolute path $abs");
  }
}

if ($xml ne $original_xml) {
  open(F,">$svg");
  print F $xml;
  close F;
}

sub err {
  my $message = shift;
  print "relativise_svg.pl, working on $svg, ",$message,"\n";
  exit(-1);
}

sub relativise {
  my ($abs,$rel_to,$within) = @_;
  my $rel = File::Spec->abs2rel($abs,$rel_to);
  if (File::Spec->abs2rel($rel,$within)=~/\.\./) {
    err("result, $rel, would have been outside $within");
  }
  return $rel;
}
