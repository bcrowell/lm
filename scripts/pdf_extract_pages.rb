#!/usr/bin/ruby

$back_end = 'qpdf'
# $back_end = 'pdftk' # pdftk is slow and buggy

def die(message)
  $stderr.print "error in pdf_extract_pages.rb: #{message}\n"
  exit(-1)
end

def do_shell(command)
  system(command)
  result = $?
  if !(result.success?) then
    die("error in command #{command}")
  end
end

if ARGV.length<3 then
  die("usage: pdf_extract_pages.rb input.pdf 1-42,137-end output.pdf")
end
$input_file = ARGV[0]
$pages = ARGV[1]
$output_file = ARGV[2]

if $back_end=='qpdf' then
  do_shell("qpdf #{$input_file} --pages #{$input_file} #{$pages.gsub(/end/,'z')} -- #{$output_file}")
      # ... this form preserves metadata; do I care?
  exit(0)
end

if $back_end=='pdftk' then
  do_shell("pdftk #{$input_file} cat #{$pages.gsub(/,/,' ')} output #{$output_file}")
  exit(0)
end
