#!/usr/bin/perl

use strict;
use Cwd;
use IO::File;
use File::Temp qw(tempfile);

use BookData;
use XML::Parser;
use JSON;

# Run this script in the book's directory; it automatically runs eruby on all the chapters.
# Normally the eruby is executed with BOOK_OUTPUT_FORMAT='print', but
# with 'w' on the command line, it will produce web (html) output as well, running
# eruby a second time with BOOK_OUTPUT_FORMAT='web' and calling translate_to_html.rb.
# It also creates the table of contents (index.html), which is then filled in by
# translate_to_html.rb.
# Any command-line options in environment variable WOPT are passed on to translate_to_html.rb.
# Example:
#   WOPT='--no_write' make web
# Command-line arguments to the right of run_eruby.pl:
#   1st can be w for web (html output), absent or - otherwise
#   2nd is number of first chapter (normally set in whichbook.make as FIRST_CHAPTER=... if not 1)
#   3rd,... are directories containing chapters (normally set in whichbook.make as DIRECTORIES=... if not ch01, etc.)

unlink "eruby_complaints";

my $eruby = "../fruby"; # use my reimplementation of eruby, for better error handling and better compatibility with TeX (see comments at top of fruby)

my $web = 0;
if (@ARGV) {
  my $a = shift @ARGV;
  $web = 1 if $a=~/w/;
}
my $first_chapter = 1;
if (@ARGV) {
  my $a = shift @ARGV;
  $first_chapter = $a;
}
my @directories;
if ($web) {
  # Don't produce html output of appendices.
  if (@ARGV) {
    @directories = grep !/^end/, @ARGV;
  }
  else {
    @directories = grep !/^ch99/, <ch*>;
  }
}
else {
  if (@ARGV) {
    @directories = @ARGV;
  }
  else {
    @directories = <ch*>;
  }
}

my $wopt = '';
if (exists $ENV{WOPT}) {$wopt = $ENV{WOPT}}
my $no_write = 0;
if ($wopt=~/\-\-no_write/) {$no_write=1}
my $mathjax = 0;
if ($wopt=~/\-\-mathjax/) {$mathjax=1}
my $wiki = 0;
if ($wopt=~/\-\-wiki/) {$wiki=1}
my $xhtml = 0;
if ($wopt=~/\-\-modern/) {$xhtml=1}
my $html5 = 0;
if ($wopt=~/\-\-html5/) {$html5=1}

print "run_eruby.pl, no_write=$no_write, wiki=$wiki, xhtml=$xhtml\n";

my $config = from_json(get_input("temp.config")); # hash ref
my $html_dir = $config->{'html_dir'};
my $standalone = $config->{'standalone'}; # For handheld versions, there are no server rewrites, so filenames should all be .html.

my $banner_html = '';
if ($standalone==0) {
$banner_html = <<BANNER;
  <div class="banner">
    <div class="banner_contents">
        <div class="banner_logo" id="logo_div"><img src="http://www.lightandmatter.com/logo.png" alt="Light and Matter logo" id="logo_img"></div>
        <div class="banner_text">
          <ul>
            <li> <a href="../../">home</a> </li>
            <li> <a href="../../books.html">books</a> </li>
            <li> <a href="../../software.html">software</a> </li>
            <li> <a href="../../courses.html">courses</a> </li>
            <li> <a href="../../area4author.html">contact</a> </li>

          </ul>
        </div>
    </div>
  </div>
BANNER
}
else {
$banner_html = <<BANNER;
<p><b>$config->{'title'}</b></p>
<p><b>Benjamin Crowell</b></p>
<p>This book's web page is <a href="http://www.lightandmatter.com/">lightandmatter.com</a>. This is my attempt to make a version of the
book for handheld e-book readers, despite what is, as of 2011, their poor support for math.</p>
BANNER
}

my $cwd = getcwd();

my $book = '';
foreach my $x(@list_of_book_directories) {
  $book = $x if $cwd=~/$x$/;
}
die "what book for $cwd? see BookData.pm" if $book eq '';


#---------
#   Note:
#     The index is always html, even if we're generating xhtml.
#     Also, translate_to_html.rb generates links to chapter files named .html, not .xhtml,
#     even when we're generating xhtml output. This is because mod_rewrite is intended to
#     redirect users to the .xhtml only if they can handle it.
#---------
my $index = $html_dir . '/index.html';
if ($web==1 && !$no_write && !$wiki) {
  open(FILE,">$index") or die "error opening $index for output; perhaps you need to create the book's main directory?";
  if ($standalone==0) {
    print FILE "<html><head><title>html version of $config->{'title'}</title>    <link rel=\"stylesheet\" type=\"text/css\" href=\"http://www.lightandmatter.com/banner.css\" media=\"all\"></head><body>\n";
  }
  else {
    print FILE <<STUFF;
<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>$config->{'title'}</title>
    <link rel="stylesheet" type="text/css" href="standalone.css" media="all"/>
    <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8"/>
  </head>
  <body>
STUFF
  }
  print FILE $banner_html;
  close FILE;
}


sub find_topic {
  my ($ch,$book,$dirs) = @_;
  my $share1 = $topic_map{$book}->{$ch+0};
  if ($share1) {
    push @$dirs,"../share/$share1/figs";
    my $share2 = $topic_map2{$book}->{$ch+0};
    if ($share2) {
      push @$dirs,"../share/$share2/figs";
    }
    my $share3 = $topic_map3{$book}->{$ch+0};
    if ($share3) {
      push @$dirs,"../share/$share3/figs";
    }
  }
}

mkdir "temp" unless -d "temp";

my $ch_num = $first_chapter-1;
foreach my $d(@directories) {
foreach (<$d/*.rbtex>) {
  my $file = $_;
  ++$ch_num;
  my $ch = sprintf "%02d",$ch_num;
  my $o = $file; # e.g., 'pr/a'
  $o =~ s/\.rbtex//;
  #print STDERR "o=$o\n";
  $o =~ m@(.*)/@;
  my $own_figs = "$1/figs"; # e.g., pr/figs
  my $html_o = $o;
  if ($web==1 && ($book eq 'me' || $book eq 'lm')) {$html_o="ch$ch/ch$ch"} # books that have subdirs like n1, vw, etc.
  my $outfile_base = $o . "temp";
  #print "o=$o, outfile_base=$outfile_base\n";
  my $postm4 = "$outfile_base.postm4";
  my @shared_dirs = ("$d/figs");
  find_topic($ch,$book,\@shared_dirs);
  my @prepend_m4_files = ("../lm.m4");
  my $calc = 0;
  if ($book eq 'sn') {push @prepend_m4_files,"sn.m4"; $calc="1"}
  if ($book eq 'me') {push @prepend_m4_files,"me.m4"; $calc="1"}
  if ($book eq 'lm') {push @prepend_m4_files,"../lmseries.m4"}
  if ($book eq 'fac') {push @prepend_m4_files,"fac.m4"; $calc="1"}
  $book =~ /\d(.*)/;
  push @prepend_m4_files,"book.m4";
  push @prepend_m4_files,"$d/chapter.m4";
  my @p = ();
  foreach my $f(@prepend_m4_files) {if (-e $f) {push @p,$f}}
  my $prepend_m4_files = join(' ',@p);
  my $shared_text = "../share/" . ($topic_map{$book}->{$ch+0});
  my $web_flag = ($web==1 ? 1 : 0);
  my $cmd = "m4 -P -D __web='$web_flag' -D __share='../share/$shared_text' $prepend_m4_files $file >$postm4";
  #print STDERR "----------------cmd=$cmd\n              ---------- book=$book, ch=$ch, topic_map=",($topic_map{$book}->{$ch+0}),"\n" if $file=~/^em/;
  do_system($cmd,$file,'m4');
  my $sharing = "SHARED_FIGS='$shared_dirs[1]' SHARED_FIGS2='$shared_dirs[2]' SHARED_FIGS3='$shared_dirs[3]'";
  my $cmd = "BK='$book' DIR='$d' $sharing CALC='$calc' BOOK_OUTPUT_FORMAT='print' $eruby $postm4 >$outfile_base.tex"; # is always executed by sh, not bash or whatever
  #print "$cmd\n";
  do_system($cmd,$file,'eruby (print)');
  if ($web==1) {
    my $cmd = "BK='$book'  DIR='$d' $sharing CALC='$calc' BOOK_OUTPUT_FORMAT='web' $eruby $postm4 >$outfile_base.temp"; # is always executed by sh, not bash or whatever
    do_system($cmd,$file,'eruby (web)');
    my $html;
    if ($wiki) {
      $html = "$html_o";
    }
    else {
      #print STDERR "constructing html from html_dir=$html_dir, o=$o\n";
      $html = "$html_dir/$html_o";
    }
    my $ext;
    if ($xhtml) {
      $ext = '.xhtml';
    }
    else {
      if ($wiki) {
        $ext = '.wiki';
      }
      else {
        if ($html5) {
          $ext = '.html5';
        }
        else {
          $ext = '.html';
        }
      }
    }
    if ($standalone==1) {$ext = '.html'}
    if (($config->{'html_file_extension'})=~/\w/) { $ext=$config->{'html_file_extension'} }
    $html = $html . $ext;
    if ($no_write) {$html = ((File::Temp::tempfile())[1])}
    print STDERR "writing $html\n";
    my $dir = "$html_dir/ch$ch";
    if (!-d $dir && !$wiki) {
      $cmd = "mkdir -p $dir";
      print STDERR "run_eruby is creating directory $dir, d=$d\n";
      do_system($cmd,'','') unless $wiki;
    }
    my $cmd = "CHAPTER='$ch' OWN_FIGS='$own_figs' ../scripts/translate_to_html.rb $wopt <$outfile_base.temp >$html";
    print $cmd,"\n";
    do_system($cmd,'stdin','translation');
    if ($xhtml) {
      local $/; open(F,"<$html"); my $x=<F>; close F;
      eval {XML::Parser->new->parse($x)};
      if ($@) {
        print "fatal error ===============> file $html output by /translate_to_html.rb is not well formed xml\n";
        XML::Parser->new->parse($x); # will print error message
        die;
      }
      else {
        if ($no_write) {unlink($html)} # delete temporary file
      }
    }
  }
}
}

if ($web==1 && !$no_write) {
  open(FILE,">>$index") or die "error opening $index";
  if ($standalone==1) {
    print FILE `scripts/translate_to_html.rb --util="ebook_title_footer"`;
  }
  print FILE "</body></html>\n";
  close FILE;
}

sub do_system {
  my $cmd = shift;
  my $file = shift;
  system($cmd)==0 or die "died on $file, $?, cmd=$cmd";
}

sub get_input {
  my $file = shift;
  local $/;
  die "make_web.pl: file $file doesn't exist" unless -e $file;
  open(FILE,"<$file") or die "error $! opening $file for input";
  my $input = <FILE>;
  close FILE;
  return $input;
}
