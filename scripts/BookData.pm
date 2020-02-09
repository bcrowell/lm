# DP is omitted from all this because it doesn't use the new build system.

package BookData;

use Exporter;
use JSON;

@ISA = ('Exporter');
@EXPORT = qw( @list_of_book_directories @list_of_book_names %book_name_to_directory %topic_map %topic_map2 %topic_map3);

@list_of_book_directories = ('cp','lm','sn','me','fac','mod'); 
@list_of_book_names = ('cp','lm','sn','me','fac','mod'); 

%book_name_to_directory = ('cp'=>'cp','lm'=>'lm','sn'=>'sn','me'=>'me','fac'=>'fac','mod'=>'mod');

# Topic maps are also used in translate_to_html.rb.
%topic_map = ();
%topic_map2 = ();
my $get_json = sub {
  local $/; # slurp whole input file;
  my $json_file = "../scripts/topic_map.json";
  open(F,"<$json_file") or die "file $json_file not found, $!, cwd=",`pwd`;
  $topic_maps_json = <F>;
  close F;
  my $topic_maps = from_json($topic_maps_json);
  my $t1 = $topic_maps->{'1'};
  %topic_map = %$t1;
  my $t2 = $topic_maps->{'2'};
  %topic_map2 = %$t2;
  my $t3 = $topic_maps->{'3'};
  %topic_map3 = %$t3;
};
&$get_json;

1;
