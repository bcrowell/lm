#!/usr/bin/ruby

# usage: timetravel.rb foo.tex
# usage: timetravel.rb foo.tex pass

require 'fileutils'
require 'digest'
require 'json'

$freeze_at_pass = 3
  # Recompiling more than this many times should not change what pages floats land on.
  # This is normally 3, must be at least 2.

def main()
  debug = false
  in_file = ARGV[0]
  if in_file.nil? then fatal_error("no input file specified") end
  if !(File.exist?(in_file)) then fatal_error("input file #{in_file} does not exist") end
  aux_file = File.basename(in_file, ".tex") + ".aux"
  $temp_dir = "timetravel" # subdirectory of current working directory

  $pass_file = "#{$temp_dir}/pass.tex" # This filename is also set in timetravel.sty.
    # ...Keep track of which pass we're on.
    # This file consists of a single line that looks like this: \newcommand{\timetravelpass}{7}
    # The ruby code reads it and extracts the integer. The latex package also inputs this file.
  $count_file = "#{$temp_dir}/count"
    # ...Keep track of how many timetravel environments we've done, even if there are multiple input files.
  pass = 1
  old_pass = 0
  if File.exist?(aux_file) then
    if !(File.directory?($temp_dir)) then fatal_error("#{aux_file} exists, but directory #{$temp_dir} doesn't") end
    slurp_or_die($pass_file) =~ /(\d+)/
    old_pass = $1.to_i
  end
  reset_count = false
  if !(ARGV[1].nil?) then
    pass = ARGV[1].to_i
    if pass>old_pass then reset_count=true end
  else
    pass = old_pass+1
    reset_count = true
  end
  if pass==1 then # make a clean temporary directory
    FileUtils.rm_rf $temp_dir
    Dir.mkdir($temp_dir)
  end
  if reset_count then set_count(0) end
  File.open($pass_file,'w') { |f|  f.print "\\newcommand{\\timetravelpass}{#{pass}}\n"}
  if debug then $stderr.print "pass=#{pass}\n" end

  page_numbers = {}
  if pass>=2 then
    if pass<=$freeze_at_pass then 
      get_page_numbers_from_aux_file(aux_file)
      save_page_numbers
    else
      # Try to make sure it converges rather than oscillating indefinitely.
      $aux_invoked,$aux_par = remember_page_numbers()
    end
  end
  inside = false # are we currently inside a timetravel environment?
  line_num = 0
  code = '' # if inside a block, start accumulating a copy of the code here
  key = get_count()
  File.readlines(in_file).each { |line|
    line_num = line_num+1
    line_type = 'normal'
    if line=~/\s*\\(begin|end){timetravel}/ then line_type=$1 end
    if line_type=='begin' then
      if inside then fatal_error("\\begin{timetravel} twice in a row at line #{line_num}") end
      inside = true
    end
    if inside && line_type=='normal' then code = code+line end
    if line_type=='end' then
      if !inside then fatal_error("\\end{timetravel} occurs when not inside a timetravel block at line #{line_num}") end
      inside = false
      #key = Digest::MD5.hexdigest(code)
      key = key+1
      set_count(key)
      #$stderr.print "hash=#{key}, code=#{code}=\n"
      if pass==1 then
        code_file = "#{$temp_dir}/#{key}.tex"
        File.open(code_file,'w') { |code_f| code_f.print "\\timetraveldisable#{code}\\timetravelenable" }
      end
      if pass>=2 then
        if !$aux_invoked.key?(key.to_s) then fatal_error("aux file #{aux_file} doesn't contain key #{key}") end
        page = $aux_invoked[key.to_s]
        if page>1 then page=page-1 end
        if pass==2 then
          par = $aux_par[page]
          File.open("#{$temp_dir}/par#{par}.tex",'a') { |f_par| f_par.print "\\input{timetravel/#{key}}"}
        end
      end
      %%%%% f_out.print "\\label{timetravelinvoked#{key}}" # This will be immediately followed by the % end-timetravel.
    end
  }
  if inside then fatal_error("\\end{timetravel} ended at end of file") end
end

def set_count(n)
  File.open($count_file,'w') { |f|  f.print n}
end

def get_count
  if File.exist?($count_file) then
    slurp_or_die($count_file).to_i
  else
    return 0
  end
end

def save_page_numbers
  File.open("#{$temp_dir}/freeze_aux_invoked.json",'w') { |f|
    f.print JSON.generate($aux_invoked)
  }
  File.open("#{$temp_dir}/freeze_aux_par.json",'w') { |f|
    f.print JSON.generate($aux_par)
  }
end

def remember_page_numbers
  return [
    get_json_data_from_file_or_die("#{$temp_dir}/freeze_aux_invoked.json"),
    get_json_data_from_file_or_die("#{$temp_dir}/freeze_aux_par.json")
  ]
end

# Initializes $aux_invoked and $aux_par.
# Lines in aux file look like this: 
#   \newlabel{timetravelinvoked1}{{}{2}}
#   \newlabel{timetravelpar14}{{}{2}}
def get_page_numbers_from_aux_file(aux_file)
  $aux_invoked = {} # key=hash, value=page
  $aux_par = {}     # key=page, value=paragraph number
  File.readlines(aux_file).each { |line|
    if line=~/\\newlabel{([^}]+)}{{([^}]*)}{([^}]+)}}/ then
      label,number,page = $1,$2,$3.to_i
      if label=~/\Atimetravel(invoked|par)([^}]*)/ then
        type,key=$1,$2
        if type=="invoked" then $aux_invoked[key]=page end
        if type=="par" then
          if $aux_par.key?(page) then
            if key<$aux_par[page] then $aux_par[page]=key end
          else
            $aux_par[page] = key
          end
        end
      end
    end
  }
end

def fatal_error(message)
  $stderr.print "generate_problems.rb: #{$verb} fatal error: #{message}\n"
  exit(-1)
end

def warning(message)
  $stderr.print "generate_problems.rb: #{$verb} warning: #{message}\n"
end

def get_json_data_from_file_or_die(file)
  r = slurp_file_with_detailed_error_reporting(file)
  if !(r[1].nil?) then fatal_error(r[1]) end
  return parse_json_or_die(r[0])
end

def parse_json_or_die(json)
  begin
    return JSON.parse(json) # use minifier to get rid of comments
  rescue JSON::ParserError
    fatal_error("syntax error in JSON string '#{json}'")
  end
end

# returns contents or nil on error; for more detailed error reporting, see slurp_file_with_detailed_error_reporting()
def slurp_file(file)
  x = slurp_file_with_detailed_error_reporting(file)
  return x[0]
end

def slurp_or_die(file)
  x = slurp_file_with_detailed_error_reporting(file)
  x = x[0]
  if x.nil? then fatal_error("file #{file} not found") end
  return x
end

# returns [contents,nil] normally [nil,error message] otherwise
def slurp_file_with_detailed_error_reporting(file)
  begin
    File.open(file,'r') { |f|
      t = f.gets(nil) # nil means read whole file
      if t.nil? then t='' end # gets returns nil at EOF, which means it returns nil if file is empty
      return [t,nil]
    }
  rescue
    return [nil,"Error opening file #{file} for input: #{$!}."]
  end
end

main()
