#!/usr/bin/ruby

# See INTRERNALS and data/README.
# This script is run after a book is compiled.
# It reads the files */ch*_problems.csv, which contain data in this format:
#    lm,0,1,calculator,0
#    book,chapter,number,label,solution
# Reads book.config and looks for allow_renumbering. Default is 0.
# Merges the updated data with data/per_book/$(BOOK)_problems.csv.
# If this would have caused a problem to be renumbered, and allow_renumbering=0, it fails with an error.
# Updates data/problems.csv by replacing it with the concatenation of the per-book files.
# Updates data/problems.m4.

book = ARGV[0]
data_dir = ARGV[1]

$per_book_csv_file = "#{data_dir}/per_book/#{book}_problems.csv"
$big_csv_file = "#{data_dir}/problems.csv"
$m4_file = "#{data_dir}/problems.m4"

def fatal_error(message)
  $stderr.print "merge_problems_data.rb: #{$verb} fatal error: #{message}\n"
  exit(-1)
end

def warning(message)
  $stderr.print "merge_problems_data.rb: #{$verb} warning: #{message}\n"
end

def read_csv(problems,filename)
  File.readlines(filename).each { |line|
    if line=~/\A([^,]*),([^,]*),([^,]*),([^,]*),([^,\n]*)/ then
      book,chapter,number,label,solution = [$1,$2.to_i,$3,$4,$5]
      problems.push([book,chapter,number,label,solution]) if label!="deleted"
    end
  }
end

def compare_problem_numbers(a,b)
  if a[1]!=b[1] then return a[1]<=>b[1] end # chapter
  pa,pb = a[2],b[2] # problem numbers (1,2,3...) or alphanumeric labels (g1, g2, ...)
  if pa=~/[a-zA-Z]/ then # or could test $config['hw_block_style']
    # This book uses alphanumeric labels.
    pa =~ /([a-zA-Z])(.*)/
    la,na = [$1,$2.to_i]
    pb =~ /([a-zA-Z])(.*)/
    lb,nb = [$1,$2.to_i]
    if la!=lb then return la<=>lb end
    return na<=>nb
  else
    return pa.to_i <=> pb.to_i
  end
end

def sort_problems!(problems)
  problems.sort! { |pa,pb| compare_problem_numbers(pa,pb)  }
end

#=================================== main ==================================

# Read config file. This is similar to code in eruby_util.rb.
config_file = 'book.config'
if ! File.exist?(config_file) then fatal_error("error, file #{config_file} does not exist") end
$config = {
  'allow_renumbering'=>0,
  'hw_block_style'=>0 # 1 means hw numbered like a7, as in Fundamentals of Calculus
}
File.open(config_file,'r') { |f|
  c = f.gets(nil) # nil means read whole file
  c.scan(/(\w+),(.*)/) { |var,value|
    if {'titlecase_above'=>nil,'hw_block_style'=>nil,'allow_renumbering'=>nil}.has_key?(var) then
      value = value.to_i
    end
    $config[var] = value
  }
}
$config.keys.each { |k|
  if $config[k].nil? then fatal_error("error, variable #{k} not given in #{config_file}") end
}

#---------------------------------------------

problems = []

n_ch_files_read = 0
Dir.glob('*problems.csv').each { |filename| # for all books except problems book, these are chNN_problems.csv
  read_csv(problems,filename)
  n_ch_files_read = n_ch_files_read+1
}
if n_ch_files_read==0 then fatal_error("no files matching *problems.csv -- build the book before running me") end
sort_problems!(problems)
if problems.length==0 then warning("no problems found in *problems.csv; unless this is a new book that actually has no problems in it, this indicates a serious error") end

hash_new = {}

problems.each { |p|
  book,chapter,number,label,solution = p
  hash_new[label] = p
}

if File.exist?($per_book_csv_file) then
  old = []
  read_csv(old,$per_book_csv_file)
  sort_problems!(old)
  old.each { |p|
    book,chapter,number,label,solution = p
    if hash_new.key?(label) && compare_problem_numbers(hash_new[label],p)!=0 && label!="deleted" then
      if $config['allow_renumbering']==1 then
        warning("problem renumbered, #{p} -> #{hash_new[label]}")
      else
        fatal_error("problem renumbered, #{p} -> #{hash_new[label]}; to allow renumbering for this book, add this line to book.config: allow_renumbering,1")
      end
    end
    if !(hash_new.key?(label)) && label!="deleted" then
      warning("problem has disappeared: #{p}")
    end
  }
  bak = $per_book_csv_file.gsub(/\.csv$/,'.bak')
  File.rename($per_book_csv_file,bak)
end

File.open($per_book_csv_file,'w') { |f|
  problems.each { |p|
    f.print p.join(',')+"\n"
  }
}

#---------------- concatenate per-book files to make problems.csv --------------

if File.exist?($big_csv_file) then
  bak = $big_csv_file.gsub(/\.csv$/,'.bak')
  File.rename($big_csv_file,bak)
end
big_problems = []
Dir.glob("#{data_dir}/per_book/*_problems.csv").sort.each { |filename|
  read_csv(big_problems,filename)
}
File.open($big_csv_file,'w') { |f|
  big_problems.each { |p|
    f.print p.join(',')+"\n"
  }
}
File.open($m4_file,'w')  { |f|
  big_problems.each { |p|
    f.print "m4_define(__hw_#{p[0]}_#{p[1]}_#{p[3]},#{p[2]})m4_dnl\n"
  }
}
