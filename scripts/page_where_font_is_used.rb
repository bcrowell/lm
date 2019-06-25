#!/usr/bin/ruby

# usage:
#  page_where_font_is_used.rb file.pdf Nimbus
# Finds the first page in file.pdf where a font with a name containing Nimbus is used.
# Font names are matched in a case-insensitive way.
# Requires pdffonts, qpdf.

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

def is_used_in_page_range(font,pdf,from,to)
  table = shell_out("pdffonts -f #{from} -l #{to} #{pdf}")
  if table=~/^[a-zA-Z0-9\+\-]*#{font}/i then
    return true
  else
    return false
  end
end

def search_for_font(font,pdf,from,to)
  print "Searching pages #{from}-#{to}.\n"
  if from==to then
    return from
  else
    mid = (from+to)/2
    if mid==to then mid=to-1 end
    if is_used_in_page_range(font,pdf,from,mid) then
      return search_for_font(font,pdf,from,mid)
    else
      return search_for_font(font,pdf,mid+1,to)
    end
  end
end

def main

  pdf = ARGV[0]
  font = ARGV[1] # can be a substring, e.g., Deja or Nimbus
  n = shell_out("qpdf --show-npages #{pdf}").to_i
  print "total pages = #{n}\n"
  if !is_used_in_page_range(font,pdf,1,n) then
    print "No font in #{pdf} has a name containing the string #{font} (case-insensitive).\n"
    exit(0)
  end
  p = search_for_font(font,pdf,1,n)
  print "The font first occurs on page #{p}.\nOutput of pdffonts for this page:\n"
  print shell_out("pdffonts -f #{p} -l #{p} #{pdf}")+"\n"
end


main
