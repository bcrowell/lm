#!/usr/bin/ruby

$back_end = 'qpdf'
# $back_end = 'pdftk' # pdftk is slow and buggy

def die(message)
  $stderr.print "error in pdf_page_count.rb: #{message}\n"
  exit(-1)
end

def shell_out(command)
  output = `#{command}`
  result = $?
  if !(result.success?) then
    die("error in command #{command}")
  end
  return output.strip
end

if ARGV.length<1 then
  die("no filename supplied")
end
$file = ARGV[0]

if $back_end=='qpdf' then
  print shell_out("qpdf --show-npages #{$file}")
  exit(0)
end
if $back_end=='pdftk' then
  x = shell_out("pdftk #{$file} dump_data")
  if x =~ /NumberOfPages\:\ (\d+)/ then
    print $1
    exit(0)
  else
    die("no appropriate NumberOfPages line in output of pdftk for file #{$file}")
  end
end
