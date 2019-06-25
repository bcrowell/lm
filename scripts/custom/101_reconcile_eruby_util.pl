#!/usr/bin/perl

use strict;
use File::Compare;
use File::Copy;

my $info = <<"INFO";
  I have two separate git repos, each of which includes its own copy of the identical
  eruby_util.rb script. I want to make sure that these stay consistent.
  If I edit the master, so it's newer than the copies, this script automatically updates 
  the copies; this shouldn't cause data loss, since any overwritten version was presumably
  committed to its own project's git repo. If a copy differs from the master and is newer,
  it's an error. The script 101_reconcile_eruby_util.pl should not be in the git
  repos, because it's only useful to me.
INFO

my $master = "/home/bcrowell/Documents/programming/eruby_util_for_books/eruby_util.rb";

my @copies = (
  "/home/bcrowell/Documents/writing/books/genrel/scripts/eruby_util.rb",
  "/home/bcrowell/Documents/writing/books/sr/scripts/eruby_util.rb",
  "/home/bcrowell/Documents/writing/books/fund/scripts/eruby_util.rb",
  "/home/bcrowell/Documents/writing/books/physics/eruby_util.rb",
  "/home/bcrowell/Documents/writing/books/poets/scripts/eruby_util.rb",
);

my $master_mod = last_modification_time($master);
foreach my $copy(@copies) {
  if (compare($master,$copy) != 0) {
    my $copy_mod = last_modification_time($copy);
    if ($copy_mod>$master_mod) {
      die "error in 101_reconcile_eruby_util.pl:\nfile\n  $copy\ndiffers from, and is newer than,\n  $master\nInfo:\n  $info\n";
    }
    else {
      print "101_reconcile_eruby_util.pl: overwriting\n  $copy\nwith newer version from\n  $master\n";
      copy($master,$copy); # This causes the copy to be newer than the master, but that won't trigger future alarms, because they're identical.
    }
  }
}

sub last_modification_time {
  my $filename = shift;
  return ((stat ($filename))[9]); # in seconds, since 1970
}
