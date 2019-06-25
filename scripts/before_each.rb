#!/usr/bin/ruby

require 'fileutils'

brief_toc_file = 'brief-toc.tex'
new_brief_toc_file = 'brief-toc-new.tex'
declare_graphics_extensions_file = 'declaregraphicsextensions.tex'

if !File.exists?(brief_toc_file) then
  File.open(brief_toc_file,'w') { |f|
    f.write "%\n"
  }
end

if File.exists?(new_brief_toc_file) then
  FileUtils.mv(new_brief_toc_file,brief_toc_file)
end

# graphics extensions for graphicx package
ext = ".pdf,.png,.jpg"
if ENV['PREPRESS']=="1" then
  ext = ".png,.jpg,.pdf" # pdf is unreliable for RIP, sometimes even messes up in screen viewers
end
File.open(declare_graphics_extensions_file,'w') { |f|
  f.write "\\DeclareGraphicsExtensions{#{ext}}\n"
}
