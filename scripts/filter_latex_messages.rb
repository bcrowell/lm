#!/usr/bin/ruby

# This program filters TeX's output to get rid of stuff I don't care about.
# It reads stdin, writes stdout.

def do_filtering(t)
  path_chars = "[a-zA-Z0-9./\-]" # characters that we expect to see in a path name
  extensions = "(sty|aux|fd|cfg|def|ldf|cls|clo|dict)" # tex tells us about these, e.g., (/foo/bar/baz.sty)
  path = "\.*\/#{path_chars}+(\n#{path_chars}+)?"
  t.gsub!(/\(#{path}\.#{extensions}\)*\s+/,'')

  t.gsub!(/\n*pdfTeX warning: pdflatex \(file #{path}\n?\)\n?:\n? \n?[^\n]+(\n[^\n]+)?included in a single page\n*/,'')
       # http://tex.stackexchange.com/questions/183149/cant-silence-a-pdftex-pdf-inclusion-multiple-pdfs-with-page-group-error

  # messages from includegraphics, e.g.,  <./ch01/figs/reservoir-tangent-line.pdf>
  t.gsub!(/<([^\n]+)\n([^\n]+)>/) {"<"+$1+$2+">"} # remove linebreaks in middle of paths
  graphics_extensions = "(jpg|pdf|png)"
  graphics_file = "#{path}\.#{graphics_extensions}( \(PNG copy\))?"
  t.gsub!(/<(#{graphics_file} )*#{graphics_file}>/,'')

  # Underfull \vbox (badness 10000) has occurred while \output is active
  # Underfull \hbox (badness 10000) in paragraph at lines 126--126
  t.gsub!(/Underfull \\(hbox|vbox) \(badness \d+\) (has occurred while \\output is active|in paragraph at lines \d+--\d+)/,'')

  # Overfull \hbox (6.56241pt too wide) detected at line 35
  # Overfull \hbox (8.53581pt too wide) in paragraph at lines 824--824
  # Overfull \vbox (6.66829pt too high) detected at line 54
  t.gsub!(/Overfull \\(hbox|vbox) \(\d+\.\d+pt too (wide|high)\) (detected|in paragraph) at (line \d+|lines \d+--\d+)/,'')

  # clean up page numbers like [18] [19]
  t.gsub!(/\[(\d+) +\]/) {"["+$1+"]"} # remove whitespace inside brackets
  1.upto(10) { |i|
    t.gsub!(/(\[\d+\])\n ?(\[\d+\])/) {$1+" "+$2} # remove newlines between page numbers
  }
  t.gsub!(/\[\]/,'') # empty brackets
  t.gsub!(/\$\[\]\$/,'') # empty $[]$
  t.gsub!(/\$\$/,'') # empty $$
  t.gsub!(/^\s*\n/,'') # lines containing only whitespace

  # messages from specific packages, etc.
  date_version = "<[^>]+>" # e.g., <2008/02/07>, used by packages to announce what version they are
  t.sub!(/\AThis is [^\n]+\n/,'')
  t.sub!(/^LaTeX2e #{date_version}Babel[^\n]+languages loaded\.\n/,'')
  t.sub!(/Package: textpos[^\n]+\n/,'')
  t.sub!(/Package: [^\n]+beamerposter[^\n]+\n/,'')
  # remove lines beginning with specific text
  [
    "For additional information on amsmath",
    "Document Class",
    "Style option",
    "Grid set ",
    "TextBlockOrigin set",
    "ABD: EveryShipout initializing macros",
    "Output written on",
    "Transcript written on",
    "*geometry*",
    "restricted \\write18 enabled.",
    "entering extended mode",
    "( FP-",
    "beamerposter",
    "Package hyperref Message",
    "(/usr/share",
    "(see the transcript file for additional information)",
    "`Fixed Point Package'",
    "[Loading MPS to PDF converter"
  ].each { |x|
    t.gsub!(/^#{Regexp::quote(x)}[^\n]*\n/,'')
  }
  t.gsub!(/^ ?\|?\\OT1[^\n]+(application|derivative|intermediate|acceleration)\|? ?$/,'')
  t.gsub!(/^ ?\|?\\OT1[^\n]+/,'') # \OT1/cmr/m/n/10.95 0.110001000000000000000001

  # list of fonts, e.g., <</usr/share/texlive/texmf-dist/fonts/type1/public/amsfonts/cm/cmbx10.pfb>>
  t.gsub!(/<\n?<\n?#{path}\n?>\n?>/,'') # <<...>>
  t.gsub!(/<\n?#{path}\n?>/,'') # <...>
  t.gsub!(/{\n?#{path}\n?}/,'')
  t.gsub!(/^OMS.*/,'')
  t.gsub!(/OT1\/cmr.*/,'')
  t.gsub!(/OML\/cmm.*/,'')
  t.gsub!(/OMS\/cmsy.*/,'')
  t.gsub!(/y=t /,'')
  t.gsub!(/10 \)/,'')
  t.gsub!(/.*\\$/,'')

  t.gsub!(/^\s*\[\d+\]$/,'') # lines like [1359] -- these should actually have been eliminated earlier...??
  t.gsub!(/^\s*(\[\d+\]\s*)+$/,'') # multiple entries, similar...??

  t.gsub!(/^Overfull.*/,'')
  t.gsub!(/.*There were undefined references.*/,'')
  t.gsub!(/.*Rerun to get cross.*/,'')
  t.gsub!(/^\<\/home\/.*\>$/,'')
  t.gsub!(/^\]$/,'')


  t.gsub!(/\n{2,}/,"\n") # blank lines

  return t
end

t = $stdin.gets(nil) # nil means read whole file
if t.nil? then t='' end # gets returns nil at EOF, which means it returns nil if file is empty

do_filtering(t)

print t
