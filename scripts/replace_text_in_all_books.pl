#!/usr/bin/perl

use strict;

my $really_do_it = 1;

# for trial run
#   set $really_do_it to zero
#   afterward, rm */ch*/*temp_new

die "I'm broken, I assume directories like 1np";

foreach my $book('0sn','1np','2cl','3vw','4em','5op','6mr') {
  #do_file($book.'/'.({'0sn'=>'simple.tex','1np'=>'bk1.tex','2cl'=>'bk2.tex','3vw'=>'bk3.tex','4em'=>'bk4.tex','5op'=>'bk5.tex','6mr'=>'bk6.tex'}->{$book}));
  foreach my $dir(<$book/ch*>) {
    $dir =~ m/\/ch(\d\d)/;
    my $ch = $1;
    if (-d $dir and ($ch>=1 && $ch<=20 or $book eq '1np' && $ch==0)) {
      foreach my $file(<$dir/ch*.rbtex>) {
        print "************************************************doing file $file\n";
        do_file($file);
      }
    }
  }
}


sub do_file {
      	my $file = shift;
        die "file $file doesn't exist" if (!-e $file);
        print "$file\n";
        local $/; # slurp
        open(FILE,"<$file") or die "error opening file $file for input";
        my $tex = <FILE>;
        close FILE;

        my $wedgie = "(?:\<\%[^>]+\%\>)";
        my $curly = "(?:{[^}]*})";
        my $stuff_with_wedgies = "(?:(?:[^<>{}]+|$wedgie|$curly)+)";
        my $stuff_with_curlies = "(?:(?:[^{}]+|$curly)+)";

        $tex=~s/{'opener'=>'([^']*)','mychapter'}/{'opener'=>'$1'}/;
        $tex=~s/{'opener'=>'([^']*)','mychapterwithopener'}/{'opener'=>'$1'}/;
        $tex=~s/{'opener'=>'([^']*)','mychapterwithopenernocaption'}/{'opener'=>'$1'}/;
        $tex=~s/{'opener'=>'([^']*)','mychapterwithopenersidecaption'}/{'opener'=>'$1','sidecaption'=>true}/;
        $tex=~s/{'opener'=>'([^']*)','mychapterwithopenersidecaptionanon'}/{'opener'=>'$1','sidecaption'=>true,'anonymous'=>true}/;
        $tex=~s/{'opener'=>'([^']*)','mychapterwithfullpagewidthopener'}/{'opener'=>'$1','width'=>'fullpage'}/;
        $tex=~s/{'opener'=>'([^']*)','mychapterwithfullpagewidthopenernocaption'}/{'opener'=>'$1','width'=>'fullpage'}/;

        # ALWAYS DO THIS:
        $tex =~ s/^(\%[^>]([^\n]*))$/ $1/gm;

        do_system("cp $file $file~");
        my $new_file = "$file.temp_new";
        if ($really_do_it) { # not just a trial run
          $new_file = $file;
        }
        open(FILE,">$new_file") or die "error opening file $new_file for output";
        print FILE $tex;
        close FILE;
        do_system("diff $file~ $new_file");
        #die "done";
}

sub do_system {
  my $cmd = shift;
  system($cmd)==0 || $cmd=~m/^diff/ or die "error $? executing command $cmd"
}
