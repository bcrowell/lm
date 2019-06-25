#!/usr/bin/perl

use strict;
use File::Compare;
use File::Copy;

my $info = <<"INFO";
  I have three separate git repos, each of which includes its own copy of the identical
  translate_to_html.rb script. I want to make sure that these all stay consistent.
  If I edit the master, so it's newer than the copies, this script automatically updates 
  the copies; this shouldn't cause data loss, since any overwritten version was presumably
  committed to its own project's git repo. If a copy differs from the master and is newer,
  it's an error. The script 100_reconcile_translate_to_html.pl should not be in the git
  repos, because it's only useful to me.
INFO

my $master = "/home/bcrowell/Documents/programming/translate_to_html/translate_to_html.rb";

my @copies = (
  "/home/bcrowell/Documents/writing/books/calc/scripts/translate_to_html.rb",
  "/home/bcrowell/Documents/writing/books/genrel/scripts/translate_to_html.rb",
  "/home/bcrowell/Documents/writing/books/physics/scripts/translate_to_html.rb",
);

my $master_mod = last_modification_time($master);
foreach my $copy(@copies) {
  if (compare($master,$copy) != 0) {
    my $copy_mod = last_modification_time($copy);
    if ($copy_mod>$master_mod) {
      die "error in 100_reconcile_translate_to_html.pl:\nfile\n  $copy\ndiffers from, and is newer than,\n  $master\nInfo:\n  $info\n";
    }
    else {
      print "100_reconcile_translate_to_html.pl: overwriting\n  $copy\nwith newer version from\n  $master\n";
      copy($master,$copy); # This causes the copy to be newer than the master, but that won't trigger future alarms, because they're identical.
    }
  }
}

sub last_modification_time {
  my $filename = shift;
  return ((stat ($filename))[9]); # in seconds, since 1970
}
