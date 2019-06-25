#!/usr/bin/ruby

$render = true # run the render_svg script on files that have fonts?

$files = []
Dir["{*/ch*/figs/*,9share/*/*}.pdf"].each { |file|
#Dir["9share/*/*.pdf"].each { |file|
  $files.push file
}

$files.sort!

$count = 0
$total = 0
$no_svg = 0

$files.each { |file|
  #print file+"\n"
  fonts = `pdffonts #{file}`
  #    name                                 type         emb sub uni object ID
  #    ------------------------------------ ------------ --- --- --- ---------
  #    Helvetica                            Type 1       no  no  no       7  0
  fonts.gsub!(/\Aname([^\n]+\n){2,2}/,'')
  has_fonts = (fonts!='')
  if has_fonts then
    print "  File #{file} uses fonts\n"
    $count += 1
  end
  svg = file.clone
  svg.gsub!(/\.pdf/,'.svg')
  eps = file.clone
  eps.gsub!(/\.pdf/,'.eps')
  svg=~/([^\/]+)\.svg/
  name = $1
  if File.exist?(svg) then
    if has_fonts and $render then
      c = "render_svg #{svg}"
      print "  #{c}\n"
      unless system(c) then $stderr.print "error, #{$?}\n" end
    end
  else
    print "  File #{file} doesn't have an svg #{svg}\n"
    $no_svg += 1

    # The following is to make it convenient to convert large batches of files from eps to svg.
    if true then
    c = "cp #{eps} a"
    #print "#{c}\n"
    unless system(c) then $stderr.print "error, #{$?}\n" end
    get_svg = "b/"+name+" [Converted].svg"
    if File.exist?(get_svg) then
      print "converted version #{get_svg} exists\n"
      z = get_svg.clone
      z.gsub!(/ \[/,'\\ [')
      c = "cp #{z} #{svg}"
      print "c=#{c}\n"
      unless system(c) then $stderr.print "error, #{$?}\n" end
      c = "svn add #{svg}"
      unless system(c) then $stderr.print "error, #{$?}\n" end
    end
    end

  end
  $total += 1
}

print "#{$total} files\n"
print "#{$count} files contained fonts\n"
print "#{$no_svg} files had no svg file\n"

