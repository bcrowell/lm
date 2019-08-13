#!/usr/bin/perl

use strict;

# This script's job is to check for inconsistencies in the labeling of problems
# between spotter xml and problems.csv.

use XML::Simple;
use File::Basename;
use Data::Dumper;
use Cwd 'abs_path';

my $book = $ARGV[0];
my $csv_file = $ARGV[1];
my $xml_fragment_file = "spotter_labels"; # created in cwd, which is the main dir, not scripts/custom
my $book_name_for_xml_file = $book;
my $book_name_for_csv_file = $book;
if ($book eq 'simple') {$book_name_for_csv_file='sn'}
my $xml_file = "/home/bcrowell/Documents/programming/spotter/answers/$book_name_for_xml_file.xml";

my $whoami = basename($0); # http://stackoverflow.com/questions/4600192/how-to-get-the-name-of-perl-script-that-is-running

if (! -e $xml_file) {
  print STDERR "warning in $whoami, file $xml_file doesn't exist; this is normal for sr\n";
  exit(0);
}

sub barf {
  my $message = shift;
  print STDERR "error in $whoami\n";
  print STDERR $message,"\n";
  exit(-1);
}

my @errors = ();

# -------- read problems.csv --------------------------------------------

if (!-e $csv_file) {
  # This script gets run by preflight, so if the book has never been compiled before in this
  # directory, problems.csv won't exist. That's OK, just exit silently.
  exit(0);
}

#   fields:
#     book = mnemonic such as lm, fund, ...
#     ch = chapter (without any leading zero)
#     num
#     name = (see note below)
#     soln = 0 or 1, boolean indicating whether the problem has a solution in the back of the book

my %csv_info = ();
my $xml_fragment = "<!-- labels output by $whoami to file $xml_fragment_file -->\n";
open(F,"<$csv_file") or barf("error opening $csv_file for input, $!");
while(my $line=<F>) {
  if ($line =~ /(.*),(.*),(.*),(.*),(.*)/) { 
    my ($csv_book,$ch,$num,$label,$solution) = ($1,$2,$3,$4,$5);
    if ($csv_book eq $book_name_for_csv_file && $label ne 'deleted') {
      if (exists $csv_info{$label}) {
        push @errors,"label $label is defined more than once in $csv_file ; this means that the xml fragment in $xml_fragment_file will not work";
      }
      $xml_fragment = $xml_fragment . "<num id=\"$label\" label=\"$num\"/>\n";
      $csv_info{$label} = [$csv_book,$ch,$num,$solution];
    }
  }
}
close F;
open(F,">$xml_fragment_file") or barf("error opening $xml_fragment_file for output, $!");
print F $xml_fragment;
close F;

# -------- read existing spotter xml --------------------------------------------

# The following dies with an error in the case where the xml file doesn't exist.
my $xml = eval{
  XML::Simple::XMLin($xml_file,ForceArray =>['toc_level','toc','problem','find','ans','var'])
};
if ($@) {
  barf("error parsing $xml_file, $@");
}

# num elements look like <num id="foo" label="17"/>

my $nums = $xml->{'num'}; # ref to an array of all the top-level nums in the file
if (! defined $nums) {
  barf("file $xml_file contains no num elements??");
}

foreach my $label(keys %$nums) {
  my $foo = $nums->{$label};
  my $id;
  # XML::Simple behaves differently depending on whether there's only 1 or more than one <num> in the file.
  if (ref $foo) {
    $id = $foo->{'label'};
  }
  else {
    barf("There only seems to be one <num> in $xml_file, which I can't handle due to an idiosyncrasy in XML::Simple.");
  }
  if (!exists $csv_info{$label}) {
    push @errors,"label $label exists in $xml_file , but not in $csv_file ; if the problem is new, do a make update_problems (?) to fix this";
  } 
  else {
    my $x = $csv_info{$label};
    my $csv_id = $x->[2];
    if ($csv_id ne $id) {
      push @errors,"label $label is defined as $id in $xml_file , but as $csv_id in $csv_file";
    }
  }
}

if (@errors>0) {
  print STDERR (scalar @errors) . " errors in $whoami :\n";
  print STDERR "  Some of these may be fixable simply by cutting and pasting the xml fragment in $xml_fragment_file into $xml_file\n";
  foreach my $error(@errors) {
    print STDERR "  $error\n";
  }
  print STDERR "$whoami dying with errors\n";
  exit(-1);
}
