use Math::Trig;

use strict;

print <<'FOO';
\pagebreak[4]
\begin{tabular}{rrrrrrrrrrrrrr}
$\theta$ & $\sin\theta$ & $\cos\theta$ & $\tan\theta$ & &
$\theta$ & $\sin\theta$ & $\cos\theta$ & $\tan\theta$ & &
$\theta$ & $\sin\theta$ & $\cos\theta$ & $\tan\theta$ \\
FOO
print <<'FOO';
\cline{1-4}  \cline{6-9}  \cline{11-14}
FOO
for (my $i=0; $i<=30; $i++) {
  for (my $j=0; $j<=60; $j+=30) {
    if ($i<=29 || $j==60) {
      my $deg = $i+$j;
      my $x= $deg/180.*pi;
      print '$'.$deg;
      print '\degunit' if ($i==0 || 1);
      print '$';
      my $s = f(sin($x));
      my $c = f(cos($x));
      my $t;
      if ($deg<90) {
        $t = f(tan($x));
      }
      else {
        $t = '$\infty$';
      }
      print ' & '.$s.' '.' & '.$c.' '.' & '.$t;
      print " & & "if ($j<=30);
    }
    else {
      print '&&&&& ';
    }
  } # end for j
  print '\\\\',"\n";
}
print '\end{tabular}',"\n";

sub f {
  my $x = shift;
  return sprintf "%6.3f",$x;
}
