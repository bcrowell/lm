#!/usr/bin/ruby

require 'fileutils'

$spotter_dir = "/home/bcrowell/Documents/programming/spotter/answers"
$shared_dir = "/home/bcrowell/Documents/writing/books/physics/share/"
$problems_csv = "/home/bcrowell/Documents/writing/books/physics/data/problems.csv"
$book_title = "Fields and Circuits"
$book_label = "fac"

def init(book_title)
  $n_missing_checks = 0  
  $missing_checks_file = "#{Dir.pwd}/missing_checks"
  $spotter1 = spotter_header() # header info for spotter .xml file
  $spotter2 = '' # body of spotter .xml file
  $spotter1 = $spotter1 + "<spotter title=\"#{book_title}\">\n<log_file ext=\"log\"/>\n"
  $spotter2 = ''
  $files_list = Dir[$shared_dir+'*/']
  ["answers","end","toc"].each { |x|
    $files_list.delete($shared_dir+x+"/")
  }
end

def do_problems(problems_csv,book_to_do)
  File.open(problems_csv,'r') { |f|
    f.each_line { |line|
      if line=~/\A([^,]*),([^,]*),([^,]*),([^,]*),([^,\n]*)/ then
        book,chapter,number,label,solution = [$1,$2.to_i,$3,$4,$5]
        next if label=="deleted"
        next unless book==book_to_do
        add_problem(chapter,label,number)
      end
    }
  }
end

def start_chapter(ch,ch_title)
  $spotter1 = $spotter1+"\n\n<!-- ch #{ch}, -->\n\n"
  $spotter2 = $spotter2+"\n\n<toc type=\"chapter\" num=\"#{ch}\" title=\"#{ch_title}\">\n\n"
end

def add_problem(ch,prob,label)
  # prob = symbolic name of problem
  # label = problem number
  file,err = find_file(prob)
  if !err.nil? then
    warning(err)
    return
  end
  tex = slurp_file(file)
  bogus_xml_filename = "#{$spotter_dir}/xml/#{prob}.tex" # misnaming it .tex, which I always do by mistake
  if File.exist?(bogus_xml_filename) then fatal_error("File #{bogus_xml_filename} exists, should end in .xml, not .tex") end
  xml_fragment = "#{$spotter_dir}/xml/#{prob}.xml"
  check_exists = File.exist?(xml_fragment)
  claims_check_exists = (tex =~ /\\answercheck/)
  if check_exists then
    $spotter1 = $spotter1 + "<num id=\"#{prob}\" label=\"#{label}\"/>\n"
    $spotter2 = $spotter2 + "m4_include(xml/#{prob}.xml)\n"
    die_if_bogus_xml(xml_fragment,prob)
  end
  if check_exists && !claims_check_exists then
    log_warning('check',"missing \\answercheck for #{prob}, #{ch}-#{label}","problem #{prob} has an answer check in #{xml_fragment},\n  but file #{file} doesn't have \\answercheck")
  end
  if !check_exists && claims_check_exists then
    log_warning('check',"missing answer check for #{ch}-#{label}, #{prob}","missing answer check for #{ch}-#{label}, #{prob}")
  end
end

def find_file(prob)
  $files_list.each { |location|
    file = location+"/hw/"+prob+".tex"
    if File.exist?(file) then return [file,nil] end
  }
  return [nil,"File #{prob}.tex not found"]
end

def spotter_header()
return <<-'XML'
<?xml version="1.0"?>

<!--










  Don't edit this file directly. To produce it, make the book, which runs the script generate_spotter_file.rb.












-->

m4_include(`spotter_doctype')
XML
end

def fatal_error(message)
  $stderr.print "generate_problems.rb: #{$verb} fatal error: #{message}\n"
  exit(-1)
end

def warning(message)
  $stderr.print "generate_problems.rb: #{$verb} warning: #{message}\n"
end

def informational_message(message)
  $stderr.print "generate_problems.rb: #{$verb} informational message: #{message}\n"
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
    return [nil,"Error opening file #{file} for input, cwd=#{Dir.pwd}: #{$!}."]
  end
end

def log_warning(type,brief,message)
  if type=='check' then
    file = $missing_checks_file
    $n_missing_checks = $n_missing_checks+1
    n = $n_missing_checks
  end
  if n==1 then warning(brief) end
  if n==2 then warning("There are additional missing #{type}s recorded in the file #{File.basename(file)}.") end
  File.open(file,'a') { |f| f.print message+"\n" }
end

def die_if_bogus_xml(xml_file,prob)
  xml = slurp_or_die(xml_file)
  # look for, e.g., <problem id="avg-velocity-bike-ride">
  if !(xml=~/(<problem\s+id="([^"]+)">)/) then
    warning("file xml_file does not appear to have a <problem id=\"...\">")
    return
  end
  id_inside_file = $2
  if prob!=id_inside_file then
    fatal_error("in file #{xml_file}, #{$1} says id is #{$2}, should be #{prob}")
  end
end

#===========================================

init($book_title)
do_problems($problems_csv,$book_label)

