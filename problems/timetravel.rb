#!/usr/bin/ruby

# usage: timetravel.rb foo.tex
# usage: timetravel.rb foo.tex pass

require 'fileutils'
require 'digest'
require 'json'

$freeze_at_pass = 4
  # Recompiling more than this many times should not change what pages floats land on.
  # This is normally 4, must be at least 2.

def main()
  debug = false
  in_file = ARGV[0]
  if in_file.nil? then fatal_error("no input file specified") end
  if !(File.exist?(in_file)) then fatal_error("input file #{in_file} does not exist") end
  aux_file = File.basename(in_file, ".tex") + ".aux"
  $temp_dir = "timetravel" # subdirectory of current working directory
  $log_file = $temp_dir + "/" + File.basename(in_file, ".tex") + ".log"

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
  log("pass=#{pass}, file=#{in_file}, count=#{get_count}")

  page_numbers = {}
  if pass>=2 then
    get_page_numbers_from_aux_file(aux_file) # $aux_invoked, $aux_par, $aux_landed; the first two of these
                                             # may be overwritten below if we calll remember_page_numbers()
    if pass<=$freeze_at_pass then 
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
  par_stuff = {}
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
        File.open(code_file,'w') { |code_f| code_f.print "\\timetraveldisable{}\\label{timetravellanded#{key}}#{code}\\timetravelenable{}" }
        code = ''
      end
      if pass>=2 then
        if !$aux_invoked.key?(key.to_s) then fatal_error("aux file #{aux_file} doesn't contain key #{key}") end
        inv,land = $aux_invoked[key.to_s],$aux_landed[key.to_s]
        offset = -1
        if pass>=3 then
          log("key #{key}, invoked at #{inv}, landed at #{land}")
          if pass>=4 && land<=inv-3 then # empirically, -1 is normal, i.e., tex thinks it landed on the invoking page
                              # -2 isn't unusual
            log("  ...warning, this is much too early")
            # offset = 0 # Don't do this, actually screws things up.
          end
        end
        par = find_target(inv,offset,key,line_num)
        par_file = "#{$temp_dir}/par#{par}.tex"
        if !(par_stuff.key?(par_file)) then par_stuff[par_file]='' end
        par_stuff[par_file] = par_stuff[par_file]+"\\input{timetravel/#{key}}"
      end
      %%%%% f_out.print "\\label{timetravelinvoked#{key}}"
    end
  }
  if pass>=2 then
    # Remove and then replace the par files. The only reason they should actually ever change from one
    # iteration to the next is of a placement was detected to be way off at pass 3, so we change it
    # at pass 4.
    FileUtils.rm Dir.glob("#{$temp_dir}/par*.tex")
    par_stuff.each { |par_file,tex|
      File.open(par_file,'w') { |f_par| f_par.print tex}
    }
  end
  if inside then fatal_error("\\begin{timetravel} ended at end of file") end
end

def find_target(invocation_page,offset,key,line_num)
  # invocation_page = page on which the timetravel environment was invoked
  # return value is paragraph key of the target that we want to travel back in time to
  page = invocation_page
  if page+offset>=1 then page=page+offset end
  par = $aux_par[page]
  if par.nil? then
    par = $aux_par[invocation_page] 
            # as a backup, admit defeat and don't time-travel; a target paragraph
            # should always exist on the invocation page, because we issue a \timetraveltohere
            # as part of the timetravel environment
    log("fallback, #{key}.tex from line #{line_num}, offset=#{offset}, invoked on page #{invocation_page} rather than the previous one, where there was no \\timetraveltohere")
  end
  if par.nil? then fatal_error("no target found for timetravel environment whose code is in #{key}.tex, line #{line_num} of source file, invoked on page #{invocation_page}") end
  return par
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

# Initializes $aux_invoked, $aux_par, and $aux_landed
# Lines in aux file look like this: 
#   \newlabel{timetravelinvoked1}{{}{2}}
#   \newlabel{timetravelpar14}{{}{2}}
#   \newlabel{timetravellanded1}{{2.2.1}{14}} ... the number such as 2.2.1 is meaningless
def get_page_numbers_from_aux_file(aux_file)
  $aux_invoked = {} # key=key, value=page
  $aux_landed = {}  # key=key, value=page
  $aux_par = {}     # key=page, value=paragraph number
  File.readlines(aux_file).each { |line|
    if line=~/\\newlabel{([^}]+)}{{([^}]*)}{([^}]+)}}/ then
      label,number,page = $1,$2,$3.to_i # number is either null or meaningless
      if label=~/\Atimetravel(invoked|par|landed)([^}]*)/ then
        type,key=$1,$2
        if type=="invoked" then $aux_invoked[key]=page end
        if type=="landed" then $aux_landed[key]=page end
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

def log(message)
  File.open($log_file,'a') { |f|
    f.print message+"\n"
  }
end

def fatal_error(message)
  log(message)
  $stderr.print "generate_problems.rb: #{$verb} fatal error: #{message}\n"
  exit(-1)
end

def warning(message)
  log(message)
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
