#!/usr/bin/perl

use strict;
use Cwd;
use IO::File;

use XML::Parser;
use JSON;

# usage:
#   run_m4.pl foo.tex book book_dir chapter_dir >outfile
# book should be something like sn, me, or lm (or can be nonexistent, dummy)
# args 3 and 4 args are optional, allow it to find book.m4 and chapter.m4 if they exist
# This is needed for solutions in the back of the book, since they don't get run through eruby by run_eruby.

#------------------------------------------------------------------------

my $file = shift @ARGV;
my $book = '';
if (@ARGV) {$book = shift @ARGV}
my $book_dir = '';
if (@ARGV) {$book_dir = shift @ARGV}
my $chapter_dir = '';
if (@ARGV) {$chapter_dir = shift @ARGV}

my @prepend_m4_files = ();

if ($book_dir) {
  push @prepend_m4_files,"$book_dir/../lm.m4";
}
if ($book eq 'sn') {push @prepend_m4_files,"$book_dir/sn.m4"}
if ($book eq 'fac') {push @prepend_m4_files,"$book_dir/fac.m4"}
if ($book eq 'me') {push @prepend_m4_files,"$book_dir/me.m4"}
if ($book eq 'lm') {push @prepend_m4_files,"$book_dir/../lmseries.m4"}
push @prepend_m4_files,"$book_dir/book.m4";
push @prepend_m4_files,"$chapter_dir/chapter.m4";

my @p = ();
foreach my $f(@prepend_m4_files) {if (-e $f) {push @p,$f}}
my $prepend_m4_files = join(' ',@p);

my $cmd = "m4 -P $prepend_m4_files $file";
#print STDERR "========in run_m4.pl, book=$book command = $cmd\n"; # qwe
do_system($cmd,$file,'m4');

sub do_system {
  my $cmd = shift;
  my $file = shift;
  system($cmd)==0 or die "died on $file, $?, cmd=$cmd";
}
