#!/usr/bin/ruby

# (c) 2006-2011 Benjamin Crowell, GPL licensed
#
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
#
#         Always edit the version of this file in ~/Documents/programming/translate_to_html/translate_to_html.rb --
#         it will automatically get copied over into the various projects the next time I do a "make" or a
#         "make preflight".
#
#         When making a new version, test it by building html for all books, and also by making epub of calc and doing
#         a "make epubcheck".
#
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
#
#
#
# must be run from the book's directory
# reads stdin, writes stdout; normally invoked by doing "run_eruby.pl w"
# also has various side-effects, like converting figures to screen resolution if necessary, writing index.html, ...
# dependencies:
#    ruby version 1.9 or later (because of lookbehinds in regexes)
#    tex4ht (used in the equation_to_image.pl script to convert the more complicated equations to bitmaps)
#    pdftoppm (comes bundled with xpdf)
# command-line options:
#   --modern
#                            Generate xhtml 1.1, meta tag saying application/xhtml+xml, use svg and mathml features. The resulting file
#                            should have file extension .xhtml so that apache will serve it as application/xhtml+xml.
#                            If this option is not supplied, then by default:
#                            Generate html 4.01 that should work in all browsers, meta tag saying text/html, no svg or mathml.
#                            The resulting file should have file extension .html so that apache will serve it with as text/html.
#                            As of Dec 2011, this is needed for opera and for old versions of firefox. May also be useful in the
#                            future because xhtml 1.1 is a good format for converting into epub.
#   --html5
#                            Similar to --modern, but generates html 5 with inline mathml. This works in firefox 3.7+.
#   --mathjax
#                            Generate html 4.01, with math in mathjax format.
#   --wiki
#                            Generate MediaWiki format. This is very crude at this point. After I used this to move everything into my mediawiki,
#                            I ended up doing a lot of mucking around  with bots to clean stuff up. See notes below.
#   --test
#                            In test mode, two things happen:
#                              - no ads generated
#                              - css link is to a local copy, not the http url
#   --redo_all_equations
#   --redo_all_tables
#   --no_write
#                            Only prevents writing to the toc and writing external files for equations.
#                            To prevent writing to the html file for each chapter, you also need to
#                            add the x parameter on the command line for run_eruby.pl in lm.make.
#  --override_config_with="foo.config,bar.config"
#                            After reading standard config files, read foo.config and bar.config as well, and overwrite any options previously set.
#  --write_config_and_exit
#                            Just writes temp.config.
#  --util="foo"
#                            Provides certain utility functions rather than doing a format conversion to html.
#  --blind
#                            Produce a version for blind people. Html5 with mathml, no figures.
# notes on handheld output:
#   see calc book for example of handheld.config
#   the idea is to output xhtml that calibre can convert to epub, etc.
#   images may be too big for epub's 63k limit, but I think calibre will fix that...?
# config files:
#   These are all JSON. Later ones override earlier ones.
#     config/default.config  --   is the same for every project: physics, calc, and genrel
#     config/repo.config     --   is shared by all books in this repository
#     ./this.config             --   different for this book than for others in this repository
#     handheld.config           --   for generating epub, etc.; would typically be pointed to by  --override_config_with
#   config variables:
#     book       string     a label for the book, is typically the same as the name of the directory the book resides in
#     title      string     human-readable title
#     url        string
#     The following config variabels are strings representing directories. They can have ~ in them, which expands to
#     home directory. The directories must exist.
#       base_dir, script_dir, html_dir, sty_dir
#     The following are integers relating to sectioning:
#       number_sections_at_depth, spew_figs_at_level, restart_figs_at_level, highest_section_level
#    all_figs_inline                 boolean, 0 or 1
#    max_fig_width_pixels            -1 normally, >0 for handheld readers
#    allow_png                       boolean, 1 normally, may be 0 for handheld readers
#    forbid_mathml                   boolean, 0 or 1, set to 1 to generate xhtml with equations as html or bitmaps, as for epub 2; also used by latex_table_to_html.pl
#    forbid_images_inside_text       boolean, 0 or 1, set to 1 for formats like epub 2
#    standalone                      boolean, 0 or 1, set to 1 if everything like CSS files, etc., has to be local, not at a URL
#    scale_for_bitmapped_equations   normally 100, may need to be more like 150 or 200 for handheld devices
#    forbid_anchors_and_links        don't generate any of these except in TOC; used for handheld output, because they confuse calibre and upset epubcheck
#    text_width_pixels               
#    ad_width_pixels                 
#    margin_width_mm                 
#    mime_type                       normally a null string, but otherwise forces the mime type to be what's given
#    html_file_extension             normally a null string, but otherwise forces the file extension to be what's given; if given, string should include the leading dot
#    mathml_plus_fallback            boolean, 0 or 1, normally 0; for epub 3's "switch" mechanism; see http://idpf.org/epub/30/spec/epub30-contentdocs.html#sec-xhtml-epub-switch
#    mathml_with_epub3_switch        boolean, 0 or 1, normally 0; for epub 3's "switch" mechanism; see http://idpf.org/epub/30/spec/epub30-contentdocs.html#sec-xhtml-epub-switch
#===============================================================================================================================
#===============================================================================================================================
#===============================================================================================================================
#                                                TO DO
#===============================================================================================================================
#===============================================================================================================================
#===============================================================================================================================
# wiki
#   stuff I cleaned up using bots:
#     Should emit {{Fig|...}} and {{Fig_caption|...} templates.
#     For homework problems, should emit {{hw|...}} templates.
# has mysterious bug related to regexes
#   showed up ca. spring 2007
#   not always reproducible
#   ../translate_to_html.rb:604:in `block in handle_math': premature end of char-class: /0a7\313\231+\000\0000a7\313\231+\000\000align\*}/ (RegexpError)
#   probably is related to ruby's new regex engine
#   doesn't complain about the error the first time the line of code is executed; uses the regex many times, then finally breaks
#   Ended up coming up with something that seemed to fix this. Preconstruct an array of the regexes, and construct each regex from
#   a string that's cloned. (If you don't clone it, then it seems to get overwritten.)
#   bug report:
#     http://rubyforge.org/tracker/index.php?func=detail&aid=11510&group_id=426&atid=1698

# keep making sure it validates at http://validator.w3.org/
# Default should be:
#   - redo any figures whose original source files are newer than the bitmaps
#   - delete equations that are no longer referred to

# -- more important --
# The code at "FIXME: The following is meant to get the divs *after* the <h2> for a section..." needs to be fixed. This will tend to break
#     at inopportune times (and already has).
# garbled equations in NP10.5
# handle 'description' environment (NP10 summary)
# environments with 2 args don't work, e.g., \begin{reading}
# tabular in margin (VW4) doesn't get parsed, presumably same problem for equations in captions, etc.
# notation section messed up
# minipagefullpagewidth (just make it into a div?)
# in CL1, some tabular* environments don't come out right

# -- less important --

# try to get figures closer to relevant text; ideas:
#    - flush figures at a lower level in the hierarchy, if the number of figures is relatively low, and the amount of text in the queue is relatively high
#    - flush figures at every homework problem
# stuff marked kludge, bug, etc., in comments
# in math parsing, some TEXT stuff gets left as is; maybe move to a token-based parser, or use an external parser (but tth and ttm have licensing issues)
#       I have various kludges to fix this.
# EM2 equation fails, search for variable "doomed" in source code
# do something with \\ in hw
# align environments, etc., aren't quite done right; the basic reason is that my equation_to_image.pl script is written on the
#     assumption that there is only one line in the equation, and therefore there's only one bitmap to scrape out of the output;
#     to do an align environment or something, I run the script several times in a loop; fixing this would require convincing
#     myself that I understand what bitmap files to scrape out of tex4ht's output, rewriting some code that assumes only one
#     bitmap per environment, and rewriting code to incorporate the html code that tex4ht generates to surround the bitmaps;
#     what I've done instead is to split, e.g., an align up into a bunch of one-liner aligns

#===============================================================================================================================
#===============================================================================================================================
#===============================================================================================================================
#                                                command-line arguments
#===============================================================================================================================
#===============================================================================================================================
#===============================================================================================================================

require "digest/md5"
require "date"
require "tmpdir"
require 'json'
require 'psych' # choice of parser for yaml
require 'yaml'
require 'getoptlong' # pickaxe book, p. 452
require 'fileutils'

def fatal_error(message)
  $stderr.print "error in translate_to_html.rb: #{message}\n"
  exit(-1)
end

# returns contents or nil on error; for more detailed error reporting, see slurp_file_with_detailed_error_reporting()
def slurp_file(file)
  x = slurp_file_with_detailed_error_reporting(file)
  return x[0]
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

def file_contains(file,regexp)
  x = slurp_file(file)
  if x.nil? then return nil end
  return (regexp =~ x)!=nil
end

# This can read either JSON or YAML (since JSON is a subset of YAML).
def get_serialized_data_from_file(file)
  parsed = begin
    YAML.load(File.open(file))
  rescue ArgumentError => e
    fatal_error("invalid YAML syntax in file #{file}")
  end
  return parsed
end

def array_of_strings_to_one_string(s)
  return s.class() == String ? s : s.join("\n")
end

opts = GetoptLong.new(
  [ "--modern",                GetoptLong::NO_ARGUMENT ],
  [ "--html5",                 GetoptLong::NO_ARGUMENT ],
  [ "--mathjax",               GetoptLong::NO_ARGUMENT ],
  [ "--wiki",                  GetoptLong::NO_ARGUMENT ],
  [ "--test",                  GetoptLong::NO_ARGUMENT ],
  [ "--redo_all_equations",    GetoptLong::NO_ARGUMENT ],
  [ "--redo_all_tables",       GetoptLong::NO_ARGUMENT ],
  [ "--no_write",              GetoptLong::NO_ARGUMENT ],
  [ "--override_config_with",  GetoptLong::REQUIRED_ARGUMENT ],
  [ "--write_config_and_exit", GetoptLong::NO_ARGUMENT ],
  [ "--util",                  GetoptLong::REQUIRED_ARGUMENT ],
  [ "--blind",                 GetoptLong::NO_ARGUMENT ]
)

opts_hash = Hash.new
opts.each do |opt,arg|
  opts_hash[opt] = arg # for boolean options, arg is "" if option was set
end

$modern                = opts_hash['--modern']!=nil || opts_hash['--html5']!=nil
$html5                 = opts_hash['--html5']!=nil
$mathjax               = opts_hash['--mathjax']!=nil
$wiki                  = opts_hash['--wiki']!=nil
$test_mode             = opts_hash['--test']!=nil
$redo_all_equations    = opts_hash['--redo_all_equations']!=nil
$redo_all_tables       = opts_hash['--redo_all_tables']!=nil
$no_write              = opts_hash['--no_write']!=nil
$override_config_with  = opts_hash['--override_config_with']
$write_config_and_exit  = opts_hash['--write_config_and_exit']
$util                  = opts_hash['--util']
$blind                 = opts_hash['--blind']!=nil

$xhtml = $modern
$format = {'wiki'=>$wiki,'xhtml'=>$xhtml,'modern'=>$modern,'html5'=>$html5}

$silent = $write_config_and_exit || $util=~/[a-z]/

unless $silent then
  $stderr.print "modern=#{$modern} test=#{$test_mode} redo_all_equations=#{$redo_all_equations} redo_all_tables=#{$redo_all_tables} no_write=#{$no_write} mathjax=#{$mathjax} wiki=#{$wiki} html5=#{$html4}\n"
end

# xhtml requires, e.g., <meta ... />, but html requires <meta ...>
if $xhtml then
  $self_closing_tag = '/'
  $anchor = 'id'
else
  $self_closing_tag = ''
  $anchor = 'name'
end
$br = "<br#{$self_closing_tag}>"

#--------------------------------------------------------------------------------
#          config files
#--------------------------------------------------------------------------------

$config = {}

config_dir = 'config'
if ! FileTest.directory?(config_dir) then config_dir = '../config' end

config_files = ["#{config_dir}/default.config","#{config_dir}/repo.config","this.config"]
if !($override_config_with.nil?) then config_files.concat($override_config_with.split(/,/)) end

config_files.each {|config_file|
  if ! File.exist?(config_file) then
    #$stderr.print "warning, config file #{config_file} does not exist\n" unless $silent
  else
    c = get_serialized_data_from_file(config_file)
    c.keys.each { |k|
      value = c[k]
      if k=~/_dir\Z/ then value.gsub!(/~/,ENV['HOME']) end
      $config[k] = value # override any earlier value that was set
    }
  end
}
$config.keys.each { |k|
  if k=~/_dir\Z/ then
    value = $config[k]
    if ! FileTest.directory?(value) && !$silent then fatal_error("#{k}=#{value}, but #{value} either does not exist or is not a directory") end
  end
}
if false then
  unless $silent then
    $config.keys.each { |k|
      $stderr.print "#{k}=#{$config[k]} "
    }
    $stderr.print "\n"
  end
end

# Write a copy of all the config variables to a temporary file, for use by any other scripts such as latex_table_to_html.pl that might need the info.
File.open("temp.config",'w') { |f| f.print JSON.generate($config)}
if $write_config_and_exit then exit(0) end

#--------------------------------------------------------------------------------
#          utility functions
#--------------------------------------------------------------------------------

if $util=~/[a-z]/ then
  handled = false
  if $util=='ebook_title_footer' then
    handled = true
    today = Date.today()
    print <<-FOOTER;
      <p>(c) #{today.year} Benjamin Crowell, <a href="http://creativecommons.org/licenses/by-sa/3.0/us/">CC-BY-SA</a> license.
      File generated #{today.year}-#{today.mon}-#{today.mday}.</p>
    FOOTER
  end
  if $util=~/learn_commands:(.*)/ then
    # learn-cmd-syntax.sty writes mybook.cmd, which contains data about the names and number of arguments of the commands defined in the .cls file.
    # Read this file and convert it into a json file.
    handled = true
    infile = $1
    unless File.exist?(infile) then fatal_error("in learn_commands: input file #{infile} does not exist") end
    results = {'command'=>[],'environment'=>[]}
    csv = slurp_file(infile)
    csv.split(/\n/).each { |line|
      # command,\currenthwlabel ,0,0,
      # environment,hw,0,1,1
      if line=~/\A(command|environment)\*?,([^,]*),([^,]*),([^,]*),([^,]*)\Z/ then
        type,name,n_req,n_opt,default = [$1,$2,$3.to_i,$4.to_i,$5]
        name.gsub!(/\s/,'')
        name.gsub!(/\\/,'') if type=='command'
        ignore = name=~/"/ || name=~/\\/ || name=~/\?/ # commands that are probably internal to some package, or that are likely to cause an error
        info = {"n_req"=>n_req,"n_opt"=>n_opt}
        if n_opt>0 then info['default']=default end
        results[type].push("    \"#{name.gsub(/\\/,'\\\\\\\\')}\":#{JSON.generate(info)}") unless ignore
      else
        unless line=~/\A\s*\Z/ || line=="command,\\,,0,0," then fatal_error("in learn_commands: syntax error in this line of #{infile}: #{line}") end
      end
    }
    s = {'command'=>'','environment'=>''}
    results.each_key { |type|
      s[type] = "  \"#{type}\":{\n"+results[type].join(",\n")+"\n  }\n"
    }
    s = "{\n"+s.values.join(",\n")+"\n}\n"
    outfile = "learned_commands.json"
    File.open(outfile,'w') { |f|
      f.print s
    }
    begin
      JSON.parse(s)
    rescue JSON::ParserError
      fatal_error("in learn_commands: the JSON I generated in file #{outfile} has invalid syntax")
    end
  end
  if $util=~/patch_epub3:(.*)/ then
    handled = true
    infile = $1
    unless File.exist?(infile) then fatal_error("in patch_epub3: input file #{infile} does not exist") end
    Dir.mktmpdir { |tmpdir|
      unless system("unzip -qq #{infile} -d #{tmpdir}") then fatal_error("in patch_epub3: unable to unzip file #{infile}") end
      # -
      # EPUB 3.0 spec, Section 2.1.1 says, "The XHTML Content Document filename should use the file extension .xhtml." But it's only a "should," not a "must."
      # I doubt that epub 3-compatible readers would care. Sample files at http://code.google.com/p/epub-revision/downloads/list have, e.g., ".xml" in Cosmo magazine.
      # This seems to be a non-issue, and calibre often outputs files named .xhtml anyway, so I'm not worrying about it.
      # -
      # EPUB 3.0 spec, section 4.3.4, says we need to declare mathml and switch properties in manifest file if we use them.
      # Also, change <package> tag so it declares this as EPUB 3.0:
      #   Calibre outputs:       <package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="uuid_id">
      #   Moby Dick example has: <package xmlns="http://www.idpf.org/2007/opf" version="3.0" xml:lang="en" unique-identifier="pub-id">
      # This stuff seems to be important. If I don't change <package>, epubcheck complains. If I don't include properties (or include them for files
      # that don't actually use the relevant property), it complains.
      # The unique-identifier is sort of like an ISBN you assign yourself, but more granular.
      # Note that <switch> mechanism is (a) broken when I generate it for displayed math, (b) further mangled by calibre, (c) not implemented by readers. All of this
      # makes it not at all useful. The only reason I'd want to use it would be in order to distribute a single epub that could be read by both old and new
      # readers. But old readers don't understand switch, so they display math twice, and new readers don't need switch if they have mathml.
      # calibre generates:
      #   <dc:creator opf:file-as="Unknown" opf:role="aut">Herman Melville</dc:creator>
      # epub 3 wants:
      #   <dc:creator id="creator">Herman Melville</dc:creator>
      #   <meta refines="#creator" property="file-as">MELVILLE, HERMAN</meta>
      #   <meta refines="#creator" property="role" scheme="marc:relators">aut</meta>
      # calibre generates:
      #   <dc:identifier id="uuid_id" opf:scheme="uuid">be2fd7f3-e91e-4257-9507-e6c3f7cb473a</dc:identifier>
      # epub 3 wants something more like:
      #   <dc:identifier id="pub-id">urn:isbn:9780316000000</dc:identifier>
      #   <meta refines="#pub-id" property="identifier-type" scheme="onix:codelist5">15</meta>
      # Stacey has:
      #   <dc:identifier id="pub-id">urn:uuid:577f82c9-a78c-493d-a162-9086930d4451</dc:identifier>
      #   <meta refines="#pub-id" property="identifier-type" scheme="xsd:string">15</meta>
      # -
      #---------- Patch the table of contents.
      toc = "#{tmpdir}/index.html"
      xml = slurp_file(toc)
      if xml.nil? then xml='' end
      # calibre generates: <!DOCTYPE html> <html xmlns="http://www.w3.org/1999/xhtml">
      # want: <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
      xml.gsub!(/<\!DOCTYPE[^>]*>/,'') # why doesn't this work?
      xml.gsub!(/<p [^>]*>/,'<li>')
      xml.gsub!(/<\/p>/,'</li>')
      xml.gsub!(/<b [^>]*>/,'')
      xml.gsub!(/<\/b>/,'')
      # li elements are only allowed to contain a elements:
      preserve = ''
      xml.scan(/(<li><a [^>]*>[^>]*<\/a><\/li>)/) { # match the legal pattern
        preserve = preserve + $1 + "\n"
      }
      xml.gsub!(Regexp.new("<li>.*<\/li>",Regexp::MULTILINE),preserve) # delete everything from the first li to the last and replace it with the ok ones
      # Strip chapter numbers, which are generated automatically by the ol:
      xml.gsub!(/((<li><a [^>]*>)([^>]*)(<\/a><\/li>))/) {
        whole,before,during,after = [$1,$2,$3,$4]
        during.gsub!(/[\d\.]+\s*/,'')
        before+during+after
      }
      if xml=~/(<html([^>]*)>)/ then
        whole,attrs = [$1,$2]
        xml.gsub!(/#{Regexp::quote(whole)}/) {"<html #{attrs} xmlns:epub=\"http://www.idpf.org/2007/ops\">"}
      end
      if xml=~/(<body[^>]*>)/ then
        whole = $1
        xml.gsub!(/#{Regexp::quote(whole)}/) {"#{whole}\n<nav epub:type=\"toc\" id=\"toc\"><ol>"}
      end
      if xml=~/(<\/body[^>]*>)/ then
        whole = $1
        xml.gsub!(/#{Regexp::quote(whole)}/) {"</ol></nav>\n#{whole}"}
      end
      File.open(toc,'w') { |f| f.print xml }
      #---------- Patch package file.
      package_document = "#{tmpdir}/content.opf" # this is what calibre generates; other people's epubs can have it in, e.g., OPS/package.opf
      xml = slurp_file(package_document)
      if xml.nil? then xml='' end
      xml = f.gets(nil) # nil means read whole file
      new_pkg = '<package xmlns="http://www.idpf.org/2007/opf" version="3.0" xml:lang="en" unique-identifier="pub-id">'
      xml.gsub!(/<package[^>]+>/,new_pkg)
      if xml=~/(<dc:creator([^>]+)>([^<]+)<\/dc:creator>)/ then
        whole,attributes,author = [Regexp::quote($1),$2,$3]
        creator = "<dc:creator id=\"creator\">#{author}</dc:creator>"
        attributes.scan(/opf:([^=]+)=\"([^"]*)\"/) {
          property,value = [$1,$2]
          creator = creator + "\n<meta refines=\"#creator\" property=\"#{property}\">#{value}</meta>"
        }
        creator = creator + "___placeholder___" # find a reasonable place to stick in some more required stuff
        xml.gsub!(/#{whole}/) {creator}
      end
      # <meta property="dcterms:modified">2012-01-13T01:13:00Z</meta>
      xml.gsub!(/___placeholder___/) {
        # http://idpf.org/epub/30/spec/epub30-publications.html#last-modified-date
        "<meta property=\"dcterms:modified\">#{Time.now.strftime '%Y-%m-%dT%H:%M:%SZ'}</meta>"
      }
      # <item  href="index.html" id="html" media-type="application/xhtml+xml"/>
      if xml=~/(<item([^>]+)(href="index.html")([^>]+)\/>)/ then
        whole,before,href,after = [Regexp::quote($1),$2,$3,$4]
        xml.gsub!(/#{whole}/) {"<item #{before} properties=\"nav\" #{href} #{after} />"}
      end
      xml.gsub!(/#{Regexp::quote(toc)}/) {
        "<item properties=\"nav\" href=\"toc.ncx\" media-type=\"application/xhtml+xml\" id=\"ncx\"/>"
      }
      if xml=~/(<dc:identifier([^>]+)>([^<]+)<\/dc:identifier>)/ then
        whole,attributes,identifier = [Regexp::quote($1),$2,$3]
        i = "<dc:identifier id=\"pub-id\">urn:uuid:#{identifier}</dc:identifier>\n"
        i = i +"<meta refines=\"#pub-id\" property=\"identifier-type\" scheme=\"xsd:string\">15</meta>"
        xml.gsub!(/#{whole}/) {i}
      end
      xml.gsub!(/(<item\s+([^\/]|"[^"]*")*\/>)/) {
        item = $1 # e.g., item=<item href="ch01_split_000.xhtml" id="html15" media-type="application/xhtml+xml"/>
        if item=~/media-type="application\/xhtml\+xml"/ then # don't do images, just html
          #$stderr.print "item=#{item}\n"
          if item=~/href="([^"]+)"/ then html_file="#{tmpdir}/#{$1}" end
          p = []
          ['math','svg','switch'].each { |x|
            if x=='math' then y='mathml' else y=x end
            if file_contains(html_file,/<#{x}/)==true then p.push(y) end
          }
          if item=~/properties="([^"]*)"/ then 
            p.concat($1.split(/\s+/))
          else
            item.gsub!(/<item/,'<item properties=""')
          end
          item.gsub!(/(properties="[^"]*")/) {"properties=\"#{p.uniq.join(' ')}\""}
          item.gsub!(/(properties=""\s*)/,' ')
          #$stderr.print "p=#{p.join(' ')}, changed item to #{item}\n"
        end # if html
        item
      }
      File.open(package_document,'w') { |f| f.print xml }
      # -
      # It's supposed to be xhtml 5, which I interpreted to mean that it should start with <!DOCTYPE html>. But sample
      # files at http://code.google.com/p/epub-revision/downloads/list have:
      #       <?xml version="1.0" encoding="UTF-8"?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"> ... cosmo
      #       <?xml version="1.0" encoding="UTF-8"?><html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"> ... moby dick
      #       So I don't think that part of the following code is actually necessary.
      # Epubcheck complains about <meta http-equiv="content-type" ... /> stuff -- so filter it out.
      # -
      Dir.entries(tmpdir).each { |x|
        file = "#{tmpdir}/#{x}"
        if file=~/html\Z/ then
          #$stderr.print "file #{file}\n"
          html = slurp_file(file)
          if html.nil? then html='' end
          html.gsub!(/<meta[^>]+\/>/,'')
          # first line output by calibre 0.7.44 looks like this: <?xml version='1.0' encoding='utf-8'?>
          if html=~/\A<\?xml/ then
            html.gsub!(/\A[^\n]*/) {"<!DOCTYPE html>"}
          end
          File.open(file,'w') { |f| f.print html}
        end
      }
      # -
      # Zip it up.
      # -
      File.rename(infile,"before_patch_epub3.epub")
      # zip options: -r recursive, -q quiet --quiet --recurse-paths --show-files
      old_dir = Dir.getwd
      Dir.chdir(tmpdir)
      # Mimetype file has to come first. The "extra field" is not allowed, hence the -X.
      unless system("zip --quiet -X #{infile} mimetype") then Dir.chdir(old_dir); fatal_error("in patch_epub3: unable to rezip file #{infile}") end
      unless system("zip --quiet -X --recurse-paths #{infile} *") then Dir.chdir(old_dir); fatal_error("in patch_epub3: unable to rezip file #{infile}") end
      Dir.chdir(old_dir)
      File.rename("#{tmpdir}/#{infile}","#{old_dir}/#{infile}")
    }
  end
  if !handled then fatal_error("illegal util command: #{$util}") end
  exit(0)
end

#=====================================================================================================================
#       html boilerplate
#=====================================================================================================================

def get_boilerplate_from_custom_file(what,format)
  x = get_serialized_data_from_file($custom_config)['boilerplate']
  return '' if x.nil?
  x = x[what]
  return '' if x.nil?
  x = array_of_strings_to_one_string(x)
  return eval "%Q{"+x+"}" # they can put interpolations like #{$config['title']}, #{$config['url']}, or #{boilerplate('valid_icon',format)}
end

# format = wiki,xhtml,modern,html5
def boilerplate(what,format)
unless format.keys.sort.join(',')=="html5,modern,wiki,xhtml" then fatal_error("format has illegal set of keys #{format.keys.sort.join(',')} in boilerplate") end
  # --- google_ad_html ---
  if what=='google_ad_html' then
    if !format['wiki'] then
      if format['xhtml'] and !format['html5'] then
        return get_boilerplate_from_custom_file('google_ad_xhtml',format)
      else
        return get_boilerplate_from_custom_file('google_ad_html',format)
      end
    end
    return ''
  end
  # --- disclaimer_html ---
  if what=='disclaimer_html' then
    if format['wiki'] then
      return get_boilerplate_from_custom_file('disclaimer_wiki',format)
    else
      return get_boilerplate_from_custom_file('disclaimer_html',format)
    end
  end
  # --- copyright_footer_html ---
  if what=='copyright_footer_html' then
    if format['wiki'] then
      return ''
    else
      return get_boilerplate_from_custom_file('copyright_footer_html',format)
    end
  end
  # --- valid_icon ---
  if what=='valid_icon' then
  # In the following, the main point of the icon is to allow me to tell, for testing purposes, whether I'm seeing the xhtml version
  # or the html version. I'm not displaying any icon for the html version, since that would just clutter up the page.
  if format['modern'] and !format['html5'] then
    return '<p><img src="http://www.w3.org/Icons/valid-xhtml11-blue.png" alt="Valid XHTML 1.1 Strict" height="31" width="88"/></p>'
  else
    #return '<p><img src="http://www.w3.org/Icons/valid-html401-blue" alt="Valid HTML 4.01 Strict" height="31" width="88"/></p>'
    return ''
  end
end
end # boilerplate

def generate_ad_if_appropriate
  if $test_mode then
    $stderr.print "***************** not putting an ad in #{$config['book']}, ch. #{$ch}, for testing purposes\n"
  else
    if $config['standalone']==0 then return boilerplate('google_ad_html',$format) + "\n" end
  end
end
#===================================================================================================================================================


#------------------------------------------------------------------------------------------------------------------------------------------------
# "Hiding" mechanism. The idea here is that I basically did this whole program as a glorified series of regex substitutions, but sometimes that's
# not adequate, because processing at a higher level in the structural hierarchy screws up something at a lower level. To avoid that, sometimes
# we need to "hide" lower-level stuff so it won't get messed with. The most common difficulty is that paragraphing gets messed up. We get ill-formed
# <p></p> tags, or nested ones, or things inside them that can't go inside them.
#------------------------------------------------------------------------------------------------------------------------------------------------

$hide = {}
$hide_types = [
  'env',                    # once we've translated a whole environment (like \begin{eg}...\end{eg}), don't screw it up
  'fig',                    # ...similarly for figures
  'mathml_in_captions',     # fix for bug with improperly nested mathml being generated in Calculus when captions contain mathml
  'tex_math_for_mediawiki'  # Normally all tex math has to be translated to html. But if we're outputting mediawiki source, we need to keep it as tex.
] # order is significant; at end, when they're expanded, we go in this order (repeating in case they're nested)
$hide_types.each { |t| $hide[t] = {} }

def hide_code(hash,type)
  return "HIDE_"+type.upcase+"_"+hash+"_HERE"
end

def hide(text,type)
  if !($hide_types.include?(type)) then fatal_error("illegal type=#{type} in hide()") end
  h = hide_code(hash_function(text),type)
  $hide[type][h] = text
  return h
end

#===============================================================================================================================
#===============================================================================================================================
#===============================================================================================================================
#                                                globals
#===============================================================================================================================
#===============================================================================================================================
#===============================================================================================================================
$custom_config = "custom_html.yaml"
$topic_map_file = "../scripts/topic_map.json"


$want_chapter_toc = !$wiki && $config['standalone']==0


$chapter_toc = "<div class=\"container\">Contents#{$br}\n"

$section_level_num = {'chapter'=>1,'section'=>2,'subsection'=>3,'subsubsection'=>4,'subsubsubsection'=>5}

$ch = nil
$chapter_title = nil
$count_eg = 0

$text_width_pixels = $config['text_width_pixels']
$ad_width_pixels = $config['ad_width_pixels']
$margin_width_mm = $config['margin_width_mm']

# In normal web-browser html, it makes sense logically to have displayed math in divs inside paragraphs, and I think it's legal.
# But in handheld-device formats, this can lead to problems, so break the math out into separate divs that aren't enclosed in p tags.
$no_displayed_math_inside_paras = $config['forbid_mathml']==1 && $config['forbid_images_inside_text']==1
$begin_div_not_p = "<!-- ZZZ_BEGIN_DIV_NOT_P -->"
$end_div_not_p   = "<!-- ZZZ_END_DIV_NOT_P -->"

$tex_math_trivial = "lt gt perp times sim ne le perp le nabla alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi omicron pi rho sigma tau upsilon phi chi psi omega Alpha Beta Gamma Delta Epsilon Zeta Eta Theta Iota Kappa Lambda Mu Nu Xi Omicron Pi Rho Sigma Tau Upsilon Phi Chi Psi Omega".split(/ /)
  # ... tex math symbols that have exactly the same names as html entities, e.g., \propto and &propto;
$tex_math_nontrivial = {'infty'=>'infin'  , 'leq'=>'le' , 'geq'=>'ge' , 'partial'=>'part' , 'cdot'=>'sdot' , 'unitdot'=>'sdot'  ,  'propto'=>'prop',
                        'approx'=>'asymp' , 'rightarrow'=>'rarr'   ,  'degunit'=>'deg' ,  'ldots'=>'hellip' }
  # ... nontrivial ones; trivial ones will now be appended to this list:
$tex_math_trivial_not_entities = "sin cos tan ln log exp arg".split(/ /)
$tex_math_not_entities = {
                          'der'=>'d'  , # cases like "\der x" are special-cased elsewhere to avoid rendering with a space like "d x"
                          'pm'=>'&#177;' ,'parallel'=>'||',
#########                          'sharp'=>'&#x266F;' , 'flat'=>'&#x266D;'   , 'ell'=>'&#8467;'
                          'sharp'=>'&#23157;' , 'flat'=>'&#23155;'   , 'ell'=>'&#8467;'
}
$tex_math_not_in_mediawiki = {'der'=>'d'  ,  'cancel'=>''}

$tex_math_to_html = {}
$tex_math_trivial_not_entities.each {|x|
  $tex_math_to_html[x] = x
}
$tex_math_nontrivial.each {|x,y|
  $tex_math_to_html[x] = "&#{y};"
}
$tex_math_trivial.each {|x|
  $tex_math_to_html[x] = "&#{x};"
}
$tex_math_not_entities.each {|x,y|
  $tex_math_to_html[x] = y
}

$tex_symbol_pat = $tex_math_to_html.keys.join('|')
$tex_symbol_replacement_list = {}
$tex_math_to_html.each {|x,y|
  $tex_symbol_replacement_list[/\\#{x}/] = y
}

# generated from Jacques Distler's MathML::Entitities, http://search.cpan.org/perldoc?MathML%3A%3AEntities
# Both Webkit and firefox seem to get upset about certain named entities such as &MediumSpace;, so
# turn these all into numbers.
$mathml_entities_to_numbers = {
  'nlE'=>'&#x02266;&#x00338;', 'harrcir'=>'&#x02948;', 'omid'=>'&#x029B6;', 'cularr'=>'&#x021B6;', 'ycy'=>'&#x0044B;', 'ldca'=>'&#x02936;', 'prec'=>'&#x0227A;', 'sqsupe'=>'&#x02292;', 'nbsp'=>'&#x000A0;', 'dscr'=>'&#x1D4B9;', 'bbrktbrk'=>'&#x023B6;', 'sqcup'=>'&#x02294;', 'cularrp'=>'&#x0293D;', 'Uopf'=>'&#x1D54C;', 'PlusMinus'=>'&#x000B1;', 'gcy'=>'&#x00433;', 'af'=>'&#x02061;', 'DownBreve'=>'&#x00311;', 'Epsilon'=>'&#x0395;', 'nlArr'=>'&#x021CD;', 
  'olt'=>'&#x029C0;', 'longrightarrow'=>'&#x027F6;', 'fallingdotseq'=>'&#x02252;', 'dzcy'=>'&#x0045F;', 'SucceedsEqual'=>'&#x02AB0;', 'boxur'=>'&#x02514;', 'rpar'=>'&#x00029;', 'varphi'=>'&#x003D5;', 'nvle'=>'&#x02264;&#x020D2;', 'RBarr'=>'&#x02910;', 'Mcy'=>'&#x0041C;', 'GreaterFullEqual'=>'&#x02267;', 'varsupsetneqq'=>'&#x02ACC;&#x0FE00;', 'rarrc'=>'&#x02933;', 'rsquo'=>'&#x02019;', 'rarrap'=>'&#x02975;', 'otimes'=>'&#x02297;', 'odot'=>'&#x02299;', 'kappa'=>'&#x003BA;', 'larrbfs'=>'&#x0291F;', 
  'Or'=>'&#x02A54;', 'Yopf'=>'&#x1D550;', 'opar'=>'&#x029B7;', 'SquareSupersetEqual'=>'&#x02292;', 'lesseqqgtr'=>'&#x02A8B;', 'rthree'=>'&#x022CC;', 'triminus'=>'&#x02A3A;', 'nGtv'=>'&#x0226B;&#x00338;', 'Edot'=>'&#x00116;', 'ssmile'=>'&#x02323;', 'lnapprox'=>'&#x02A89;', 'lrhard'=>'&#x0296D;', 'zdot'=>'&#x0017C;', 'NegativeMediumSpace'=>'&#x0200B;', 'Uogon'=>'&#x00172;', 'DownLeftRightVector'=>'&#x02950;', 'kscr'=>'&#x1D4C0;', 'bsemi'=>'&#x0204F;', 'TildeTilde'=>'&#x02248;', 'setminus'=>'&#x02216;', 
  'yicy'=>'&#x00457;', 'check'=>'&#x02713;', 'thicksim'=>'&#x0223C;', 'LowerLeftArrow'=>'&#x02199;', 'cupdot'=>'&#x0228D;', 'varrho'=>'&#x003F1;', 'Conint'=>'&#x0222F;', 'dfr'=>'&#x1D521;', 'leqslant'=>'&#x02A7D;', 'ecir'=>'&#x02256;', 'rArr'=>'&#x021D2;', 'DiacriticalTilde'=>'&#x002DC;', 'Cedilla'=>'&#x000B8;', 'loarr'=>'&#x021FD;', 'frac15'=>'&#x02155;', 'csupe'=>'&#x02AD2;', 'fopf'=>'&#x1D557;', 'xvee'=>'&#x022C1;', 'CircleMinus'=>'&#x02296;', 'efDot'=>'&#x02252;', 
  'iota'=>'&#x003B9;', 'race'=>'&#x0223D;&#x0331;', 'gopf'=>'&#x1D558;', 'nsupE'=>'&#x02AC6;&#x00338;', 'lcub'=>'&#x0007B;', 'Union'=>'&#x022C3;', 'boxHu'=>'&#x02567;', 'top'=>'&#x022A4;', 'ngeqslant'=>'&#x02A7E;&#x00338;', 'curlyeqprec'=>'&#x022DE;', 'dagger'=>'&#x02020;', 'vsubne'=>'&#x0228A;&#x0FE00;', 'UnderBracket'=>'&#x023B5;', 'Exists'=>'&#x02203;', 'notinvb'=>'&#x022F7;', 'rharu'=>'&#x021C0;', 'iprod'=>'&#x02A3C;', 'Proportional'=>'&#x0221D;', 'Ograve'=>'&#x000D2;', 'djcy'=>'&#x00452;', 
  'sqcups'=>'&#x02294;&#x0FE00;', 'Gdot'=>'&#x00120;', 'NestedGreaterGreater'=>'&#x0226B;', 'DJcy'=>'&#x00402;', 'jcy'=>'&#x00439;', 'swarrow'=>'&#x02199;', 'Vdashl'=>'&#x02AE6;', 'NotRightTriangleEqual'=>'&#x022ED;', 'eqsim'=>'&#x02242;', 'circ'=>'&#x002C6;', 'uArr'=>'&#x021D1;', 'Rho'=>'&#x03A1;', 'propto'=>'&#x0221D;', 'simgE'=>'&#x02AA0;', 'loz'=>'&#x025CA;', 'nGg'=>'&#x022D9;&#x00338;', 'kfr'=>'&#x1D528;', 'iinfin'=>'&#x029DC;', 'afr'=>'&#x1D51E;', 'ouml'=>'&#x000F6;', 
  'Tscr'=>'&#x1D4AF;', 'nLeftrightarrow'=>'&#x021CE;', 'cacute'=>'&#x00107;', 'Yfr'=>'&#x1D51C;', 'nis'=>'&#x022FC;', 'ZHcy'=>'&#x00416;', 'succapprox'=>'&#x02AB8;', 'rx'=>'&#x0211E;', 'profline'=>'&#x02312;', 'nsubset'=>'&#x02282;&#x020D2;', 'nsube'=>'&#x02288;', 'planck'=>'&#x0210F;', 'rlhar'=>'&#x021CC;', 'dotminus'=>'&#x02238;', 'lrcorner'=>'&#x0231F;', 'sacute'=>'&#x0015B;', 'gsime'=>'&#x02A8E;', 'nvlArr'=>'&#x02902;', 'dscy'=>'&#x00455;', 'coloneq'=>'&#x02254;', 
  'upharpoonright'=>'&#x021BE;', 'RightTee'=>'&#x022A2;', 'NotLeftTriangleBar'=>'&#x029CF;&#x00338;', 'CapitalDifferentialD'=>'&#x02145;', 'thorn'=>'&#x000FE;', 'll'=>'&#x0226A;', 'Fopf'=>'&#x1D53D;', 'prE'=>'&#x02AB3;', 'downarrow'=>'&#x02193;', 'and'=>'&#x02227;', 'gdot'=>'&#x00121;', 'roplus'=>'&#x02A2E;', 'Dagger'=>'&#x02021;', 'NotSucceeds'=>'&#x02281;', 'tbrk'=>'&#x023B4;', 'Otimes'=>'&#x02A37;', 'DoubleUpDownArrow'=>'&#x021D5;', 'LessLess'=>'&#x02AA1;', 'Tcedil'=>'&#x00162;', 'RightTriangle'=>'&#x022B3;', 
  'langle'=>'&#x027E8;', 'rarrsim'=>'&#x02974;', 'longmapsto'=>'&#x027FC;', 'nsubseteq'=>'&#x02288;', 'eg'=>'&#x02A9A;', 'ltimes'=>'&#x022C9;', 'UnderBrace'=>'&#x023DF;', 'isinsv'=>'&#x022F3;', 'square'=>'&#x025A1;', 'AMP'=>'&#x0026', 'bkarow'=>'&#x0290D;', 'rightrightarrows'=>'&#x021C9;', 'eacute'=>'&#x000E9;', 'sdotb'=>'&#x022A1;', 'Beta'=>'&#x0392;', 'blacksquare'=>'&#x025AA;', 'submult'=>'&#x02AC1;', 'xrArr'=>'&#x027F9;', 'Poincareplane'=>'&#x0210C;', 'pm'=>'&#x000B1;', 
  'NotSquareSubsetEqual'=>'&#x022E2;', 'dlcrop'=>'&#x0230D;', 'SmallCircle'=>'&#x02218;', 'cylcty'=>'&#x0232D;', 'hstrok'=>'&#x00127;', 'angrtvbd'=>'&#x0299D;', 'bbrk'=>'&#x023B5;', 'ntrianglerighteq'=>'&#x022ED;', 'nrarr'=>'&#x0219B;', 'aring'=>'&#x000E5;', 'boxhu'=>'&#x02534;', 'frac13'=>'&#x02153;', 'mscr'=>'&#x1D4C2;', 'Barv'=>'&#x02AE7;', 'uuml'=>'&#x000FC;', 'ctdot'=>'&#x022EF;', 'trisb'=>'&#x029CD;', 'NotRightTriangleBar'=>'&#x029D0;&#x00338;', 'thickapprox'=>'&#x02248;', 'ovbar'=>'&#x0233D;', 
  'xutri'=>'&#x025B3;', 'NotNestedLessLess'=>'&#x02AA1;&#x00338;', 'DiacriticalDoubleAcute'=>'&#x002DD;', 'caps'=>'&#x02229;&#x0FE00;', 'nleftarrow'=>'&#x0219A;', 'ForAll'=>'&#x02200;', 'capbrcup'=>'&#x02A49;', 'nspar'=>'&#x02226;', 'midcir'=>'&#x02AF0;', 'gtreqless'=>'&#x022DB;', 'laemptyv'=>'&#x029B4;', 'aogon'=>'&#x00105;', 'YAcy'=>'&#x0042F;', 'dollar'=>'&#x00024;', 'mfr'=>'&#x1D52A;', 'Jukcy'=>'&#x00404;', 'subseteqq'=>'&#x02AC5;', 'subseteq'=>'&#x02286;', 'horbar'=>'&#x02015;', 'THORN'=>'&#x000DE;', 
  'bnot'=>'&#x02310;', 'swarhk'=>'&#x02926;', 'alpha'=>'&#x003B1;', 'NewLine'=>'&#x0000A;', 'real'=>'&#x0211C;', 'Sscr'=>'&#x1D4AE;', 'Superset'=>'&#x02283;', 'searrow'=>'&#x02198;', 'updownarrow'=>'&#x02195;', 'plus'=>'&#x0002B;', 'qprime'=>'&#x02057;', 'psi'=>'&#x003C8;', 'zopf'=>'&#x1D56B;', 'AElig'=>'&#x000C6;', 'supset'=>'&#x02283;', 'andd'=>'&#x02A5C;', 'rBarr'=>'&#x0290F;', 'notniva'=>'&#x0220C;', 'epsiv'=>'&#x003F5;', 'or'=>'&#x02228;', 
  'Tstrok'=>'&#x00166;', 'operp'=>'&#x029B9;', 'boxUR'=>'&#x0255A;', 'straightepsilon'=>'&#x003F5;', 'cup'=>'&#x0222A;', 'NegativeVeryThinSpace'=>'&#x0200B;', 'rbrack'=>'&#x0005D;', 'scap'=>'&#x02AB8;', 'rnmid'=>'&#x02AEE;', 'Colone'=>'&#x02A74;', 'capcup'=>'&#x02A47;', 'Diamond'=>'&#x022C4;', 'phiv'=>'&#x003D5;', 'gel'=>'&#x022DB;', 'Assign'=>'&#x02254;', 'bump'=>'&#x0224E;', 'nbump'=>'&#x0224E;&#x00338;', 'frac45'=>'&#x02158;', 'Racute'=>'&#x00154;', 'topfork'=>'&#x02ADA;', 
  'gg'=>'&#x0226B;', 'tstrok'=>'&#x00167;', 'angmsdac'=>'&#x029AA;', 'emptyset'=>'&#x02205;', 'hksearow'=>'&#x02925;', 'icy'=>'&#x00438;', 'ltcir'=>'&#x02A79;', 'loplus'=>'&#x02A2D;', 'pound'=>'&#x000A3;', 'rmoustache'=>'&#x023B1;', 'period'=>'&#x0002E;', 'ycirc'=>'&#x00177;', 'lcaron'=>'&#x0013E;', 'male'=>'&#x02642;', 'copysr'=>'&#x02117;', 'Vert'=>'&#x02016;', 'OverBracket'=>'&#x023B4;', 'dbkarow'=>'&#x0290F;', 'curvearrowright'=>'&#x021B7;', 'Tcaron'=>'&#x00164;', 
  'Pcy'=>'&#x0041F;', 'SucceedsTilde'=>'&#x0227F;', 'Tab'=>'&#x00009;', 'sigma'=>'&#x003C3;', 'nedot'=>'&#x02250;&#x00338;', 'Oslash'=>'&#x000D8;', 'CircleTimes'=>'&#x02297;', 'leq'=>'&#x02264;', 'Scaron'=>'&#x00160;', 'SHcy'=>'&#x00428;', 'rightleftarrows'=>'&#x021C4;', 'verbar'=>'&#x0007C;', 'Lt'=>'&#x0226A;', 'LeftCeiling'=>'&#x02308;', 'NotSquareSuperset'=>'&#x02290;&#x00338;', 'Kopf'=>'&#x1D542;', 'lBarr'=>'&#x0290E;', 'origof'=>'&#x022B6;', 'lcy'=>'&#x0043B;', 'trianglelefteq'=>'&#x022B4;', 
  'ograve'=>'&#x000F2;', 'prap'=>'&#x02AB7;', 'lAtail'=>'&#x0291B;', 'Iacute'=>'&#x000CD;', 'DiacriticalDot'=>'&#x002D9;', 'piv'=>'&#x003D6;', 'NotPrecedesEqual'=>'&#x02AAF;&#x00338;', 'LeftTriangleEqual'=>'&#x022B4;', 'lHar'=>'&#x02962;', 'frac58'=>'&#x0215D;', 'vscr'=>'&#x1D4CB;', 'bigstar'=>'&#x02605;', 'boxuR'=>'&#x02558;', 'Dot'=>'&#x000A8;', 'cudarrl'=>'&#x02938;', 'varpropto'=>'&#x0221D;', 'boxvH'=>'&#x0256A;', 'lgE'=>'&#x02A91;', 'Bfr'=>'&#x1D505;', 'xcup'=>'&#x022C3;', 
  'suplarr'=>'&#x0297B;', 'wr'=>'&#x02240;', 'ltri'=>'&#x025C3;', 'frac35'=>'&#x02157;', 'notin'=>'&#x02209;', 'subdot'=>'&#x02ABD;', 'qscr'=>'&#x1D4C6;', 'olcross'=>'&#x029BB;', 'angst'=>'&#x000C5;', 'NotVerticalBar'=>'&#x02224;', 'NotRightTriangle'=>'&#x022EB;', 'sup1'=>'&#x000B9;', 'supsup'=>'&#x02AD6;', 'frac25'=>'&#x02156;', 'nisd'=>'&#x022FA;', 'angzarr'=>'&#x0237C;', 'uogon'=>'&#x00173;', 'plussim'=>'&#x02A26;', 'nltri'=>'&#x022EA;', 'RightTriangleEqual'=>'&#x022B5;', 
  'ldquor'=>'&#x0201E;', 'barwed'=>'&#x02305;', 'lesg'=>'&#x022DA;&#x0FE00;', 'nges'=>'&#x02A7E;&#x00338;', 'num'=>'&#x00023;', 'rdca'=>'&#x02937;', 'xwedge'=>'&#x022C0;', 'LJcy'=>'&#x00409;', 'larrsim'=>'&#x02973;', 'apid'=>'&#x0224B;', 'CenterDot'=>'&#x000B7;', 'langd'=>'&#x02991;', 'nearhk'=>'&#x02924;', 'bottom'=>'&#x022A5;', 'LeftArrowRightArrow'=>'&#x021C6;', 'ApplyFunction'=>'&#x02061;', 'swArr'=>'&#x021D9;', 'NotLessGreater'=>'&#x02278;', 'gnapprox'=>'&#x02A8A;', 'sim'=>'&#x0223C;', 
  'CounterClockwiseContourIntegral'=>'&#x02233;', 'Cayleys'=>'&#x0212D;', 'tcaron'=>'&#x00165;', 'LeftArrow'=>'&#x02190;', 'smeparsl'=>'&#x029E4;', 'Mscr'=>'&#x02133;', 'lesdoto'=>'&#x02A81;', 'risingdotseq'=>'&#x02253;', 'ufisht'=>'&#x0297E;', 'Ycy'=>'&#x0042B;', 'Lfr'=>'&#x1D50F;', 'Gbreve'=>'&#x0011E;', 'orderof'=>'&#x02134;', 'Ucirc'=>'&#x000DB;', 'leftrightharpoons'=>'&#x021CB;', 'topf'=>'&#x1D565;', 'rdldhar'=>'&#x02969;', 'gtrdot'=>'&#x022D7;', 'Acy'=>'&#x00410;', 'xnis'=>'&#x022FB;', 
  'CupCap'=>'&#x0224D;', 'LeftFloor'=>'&#x0230A;', 'aleph'=>'&#x02135;', 'udarr'=>'&#x021C5;', 'uharr'=>'&#x021BE;', 'LowerRightArrow'=>'&#x02198;', 'boxDR'=>'&#x02554;', 'RightArrowLeftArrow'=>'&#x021C4;', 'nwarhk'=>'&#x02923;', 'boxDL'=>'&#x02557;', 'blacktriangledown'=>'&#x025BE;', 'late'=>'&#x02AAD;', 'wreath'=>'&#x02240;', 'Del'=>'&#x02207;', 'DoubleUpArrow'=>'&#x021D1;', 'Dstrok'=>'&#x00110;', 'rmoust'=>'&#x023B1;', 'omega'=>'&#x003C9;', 'prime'=>'&#x02032;', 'bprime'=>'&#x02035;', 
  'HilbertSpace'=>'&#x0210B;', 'uhblk'=>'&#x02580;', 'UpperRightArrow'=>'&#x02197;', 'NotGreaterLess'=>'&#x02279;', 'nsupset'=>'&#x02283;&#x020D2;', 'naturals'=>'&#x02115;', 'lArr'=>'&#x021D0;', 'Vscr'=>'&#x1D4B1;', 'gesl'=>'&#x022DB;&#x0FE00;', 'solb'=>'&#x029C4;', 'die'=>'&#x000A8;', 'lrarr'=>'&#x021C6;', 'rbarr'=>'&#x0290D;', 'utdot'=>'&#x022F0;', 'larrpl'=>'&#x02939;', 'LongLeftRightArrow'=>'&#x027F7;', 'nLtv'=>'&#x0226A;&#x00338;', 'Ropf'=>'&#x0211D;', 'Jcirc'=>'&#x00134;', 'exist'=>'&#x02203;', 
  'OverBar'=>'&#x0203E;', 'Vbar'=>'&#x02AEB;', 'gjcy'=>'&#x00453;', 'boxUr'=>'&#x02559;', 'Gcy'=>'&#x00413;', 'wscr'=>'&#x1D4CC;', 'beth'=>'&#x02136;', 'raemptyv'=>'&#x029B3;', 'DownTee'=>'&#x022A4;', 'natural'=>'&#x0266E;', 'rscr'=>'&#x1D4C7;', 'nsupseteqq'=>'&#x02AC6;&#x00338;', 'NegativeThinSpace'=>'&#x0200B;', 'Oacute'=>'&#x000D3;', 'odiv'=>'&#x02A38;', 'heartsuit'=>'&#x02665;', 'rightleftharpoons'=>'&#x021CC;', 'ltrie'=>'&#x022B4;', 'Kappa'=>'&#x039A;', 'prnE'=>'&#x02AB5;', 
  'boxvl'=>'&#x02524;', 'plankv'=>'&#x0210F;', 'ldquo'=>'&#x0201C;', 'rightharpoonup'=>'&#x021C0;', 'Dfr'=>'&#x1D507;', 'lowbar'=>'&#x0005F;', 'uscr'=>'&#x1D4CA;', 'ordf'=>'&#x000AA;', 'gfr'=>'&#x1D524;', 'ldrdhar'=>'&#x02967;', 'NotGreaterSlantEqual'=>'&#x02A7E;&#x00338;', 'awconint'=>'&#x02233;', 'Eta'=>'&#x0397;', 'ncongdot'=>'&#x02A6D;&#x00338;', 'NotTildeFullEqual'=>'&#x02247;', 'gscr'=>'&#x0210A;', 'lozenge'=>'&#x025CA;', 'realine'=>'&#x0211B;', 'demptyv'=>'&#x029B1;', 'OverParenthesis'=>'&#x023DC;', 
  'Bopf'=>'&#x1D539;', 'fork'=>'&#x022D4;', 'angmsdah'=>'&#x029AF;', 'imped'=>'&#x001B5;', 'NotSubset'=>'&#x02282;&#x020D2;', 'micro'=>'&#x000B5;', 'NotReverseElement'=>'&#x0220C;', 'RightDownVectorBar'=>'&#x02955;', 'thinsp'=>'&#x02009;', 'dashv'=>'&#x022A3;', 'RightUpDownVector'=>'&#x0294F;', 'zcaron'=>'&#x0017E;', 'Lopf'=>'&#x1D543;', 'daleth'=>'&#x02138;', 'hamilt'=>'&#x0210B;', 'NotGreaterTilde'=>'&#x02275;', 'Sub'=>'&#x022D0;', 'sigmav'=>'&#x003C2;', 'ell'=>'&#x02113;', 'uwangle'=>'&#x029A7;', 
  'nscr'=>'&#x1D4C3;', 'DoubleDot'=>'&#x000A8;', 'Acirc'=>'&#x000C2;', 'bNot'=>'&#x02AED;', 'cscr'=>'&#x1D4B8;', 'backepsilon'=>'&#x003F6;', 'Ufr'=>'&#x1D518;', 'efr'=>'&#x1D522;', 'icirc'=>'&#x000EE;', 'perp'=>'&#x022A5;', 'ucirc'=>'&#x000FB;', 'Qopf'=>'&#x0211A;', 'Sup'=>'&#x022D1;', 'udblac'=>'&#x00171;', 'boxbox'=>'&#x029C9;', 'Colon'=>'&#x02237;', 'DownLeftVector'=>'&#x021BD;', 'oint'=>'&#x0222E;', 'rtri'=>'&#x025B9;', 'Chi'=>'&#x03A7;', 
  'fscr'=>'&#x1D4BB;', 'odsold'=>'&#x029BC;', 'Kscr'=>'&#x1D4A6;', 'preccurlyeq'=>'&#x0227C;', 'nldr'=>'&#x02025;', 'jcirc'=>'&#x00135;', 'UnderParenthesis'=>'&#x023DD;', 'varpi'=>'&#x003D6;', 'pre'=>'&#x02AAF;', 'ffilig'=>'&#x0FB03;', 'ccupssm'=>'&#x02A50;', 'rbrace'=>'&#x0007D;', 'dtrif'=>'&#x025BE;', 'Abreve'=>'&#x00102;', 'pi'=>'&#x003C0;', 'scnsim'=>'&#x022E9;', 'angsph'=>'&#x02222;', 'nvge'=>'&#x02265;&#x020D2;', 'QUOT'=>'&#x0022', 'cupbrcap'=>'&#x02A48;', 
  'CircleDot'=>'&#x02299;', 'plusacir'=>'&#x02A23;', 'ratail'=>'&#x0291A;', 'rightarrowtail'=>'&#x021A3;', 'darr'=>'&#x02193;', 'bumpeq'=>'&#x0224F;', 'lneqq'=>'&#x02268;', 'emptyv'=>'&#x02205;', 'Esim'=>'&#x02A73;', 'centerdot'=>'&#x000B7;', 'alefsym'=>'&#x2135;', 'dzigrarr'=>'&#x027FF;', 'escr'=>'&#x0212F;', 'UpArrowBar'=>'&#x02912;', 'emsp14'=>'&#x02005;', 'varnothing'=>'&#x02205;', 'tprime'=>'&#x02034;', 'rdquo'=>'&#x0201D;', 'eqcolon'=>'&#x02255;', 'chi'=>'&#x003C7;', 
  'swnwar'=>'&#x0292A;', 'Emacr'=>'&#x00112;', 'Backslash'=>'&#x02216;', 'Iukcy'=>'&#x00406;', 'ord'=>'&#x02A5D;', 'bcong'=>'&#x0224C;', 'egs'=>'&#x02A96;', 'circledR'=>'&#x000AE;', 'cupcup'=>'&#x02A4A;', 'ncy'=>'&#x0043D;', 'notinva'=>'&#x02209;', 'ThinSpace'=>'&#x02009;', 'RightUpVector'=>'&#x021BE;', 'twoheadrightarrow'=>'&#x021A0;', 'in'=>'&#x02208;', 'breve'=>'&#x002D8;', 'gesles'=>'&#x02A94;', 'Uarrocir'=>'&#x02949;', 'Popf'=>'&#x02119;', 'ensp'=>'&#x02002;', 
  'Jsercy'=>'&#x00408;', 'cuepr'=>'&#x022DE;', 'plusdu'=>'&#x02A25;', 'nwarr'=>'&#x02196;', 'NotExists'=>'&#x02204;', 'vBarv'=>'&#x02AE9;', 'NotSucceedsTilde'=>'&#x0227F;&#x00338;', 'egsdot'=>'&#x02A98;', 'rho'=>'&#x003C1;', 'euro'=>'&#x20AC;', 'LeftUpDownVector'=>'&#x02951;', 'nsup'=>'&#x02285;', 'NotLessSlantEqual'=>'&#x02A7D;&#x00338;', 'minusb'=>'&#x0229F;', 'gEl'=>'&#x02A8C;', 'Topf'=>'&#x1D54B;', 'DiacriticalGrave'=>'&#x00060;', 'precnsim'=>'&#x022E8;', 'ofcir'=>'&#x029BF;', 'Gscr'=>'&#x1D4A2;', 
  'napos'=>'&#x00149;', 'LeftUpVector'=>'&#x021BF;', 'map'=>'&#x021A6;', 'ReverseEquilibrium'=>'&#x021CB;', 'nwArr'=>'&#x021D6;', 'copf'=>'&#x1D554;', 'ntilde'=>'&#x000F1;', 'Oopf'=>'&#x1D546;', 'bscr'=>'&#x1D4B7;', 'mcy'=>'&#x0043C;', 'prsim'=>'&#x0227E;', 'Intersection'=>'&#x022C2;', 'Euml'=>'&#x000CB;', 'numsp'=>'&#x02007;', 'amalg'=>'&#x02A3F;', 'Tau'=>'&#x03A4;', 'lcedil'=>'&#x0013C;', 'larrfs'=>'&#x0291D;', 'osol'=>'&#x02298;', 'zfr'=>'&#x1D537;', 
  'rbrke'=>'&#x0298C;', 'Kcedil'=>'&#x00136;', 'Hat'=>'&#x0005E;', 'conint'=>'&#x0222E;', 'RightDoubleBracket'=>'&#x027E7;', 'isins'=>'&#x022F4;', 'mapstoup'=>'&#x021A5;', 'looparrowleft'=>'&#x021AB;', 'mlcp'=>'&#x02ADB;', 'ifr'=>'&#x1D526;', 'varsubsetneq'=>'&#x0228A;&#x0FE00;', 'luruhar'=>'&#x02966;', 'tint'=>'&#x0222D;', 'squarf'=>'&#x025AA;', 'dtdot'=>'&#x022F1;', 'supseteqq'=>'&#x02AC6;', 'rfloor'=>'&#x0230B;', 'Fscr'=>'&#x02131;', 'varsigma'=>'&#x003C2;', 'models'=>'&#x022A7;', 
  'Lcy'=>'&#x0041B;', 'OElig'=>'&#x00152;', 'NotSucceedsEqual'=>'&#x02AB0;&#x00338;', 'dblac'=>'&#x002DD;', 'pertenk'=>'&#x02031;', 'rationals'=>'&#x0211A;', 'lharul'=>'&#x0296A;', 'leftarrow'=>'&#x02190;', 'pluse'=>'&#x02A72;', 'IOcy'=>'&#x00401;', 'Ocy'=>'&#x0041E;', 'Cap'=>'&#x022D2;', 'InvisibleComma'=>'&#x02063;', 'FilledVerySmallSquare'=>'&#x025AA;', 'NegativeThickSpace'=>'&#x0200B;', 'rAarr'=>'&#x021DB;', 'compfn'=>'&#x02218;', 'simrarr'=>'&#x02972;', 'gesdotol'=>'&#x02A84;', 'GreaterLess'=>'&#x02277;', 
  'Tfr'=>'&#x1D517;', 'DoubleRightTee'=>'&#x022A8;', 'blacktriangleleft'=>'&#x025C2;', 'Sqrt'=>'&#x0221A;', 'DiacriticalAcute'=>'&#x000B4;', 'RightFloor'=>'&#x0230B;', 'kappav'=>'&#x003F0;', 'HumpEqual'=>'&#x0224F;', 'rppolint'=>'&#x02A12;', 'kcy'=>'&#x0043A;', 'Lleftarrow'=>'&#x021DA;', 'DownArrowUpArrow'=>'&#x021F5;', 'xopf'=>'&#x1D569;', 'suphsol'=>'&#x027C9;', 'ropar'=>'&#x02986;', 'utilde'=>'&#x00169;', 'wedgeq'=>'&#x02259;', 'frac16'=>'&#x02159;', 'xharr'=>'&#x027F7;', 'boxVh'=>'&#x0256B;', 
  'ncong'=>'&#x02247;', 'vzigzag'=>'&#x0299A;', 'rpargt'=>'&#x02994;', 'gneq'=>'&#x02A88;', 'gammad'=>'&#x003DD;', 'roang'=>'&#x027ED;', 'Cacute'=>'&#x00106;', 'nshortparallel'=>'&#x02226;', 'ddagger'=>'&#x02021;', 'ddarr'=>'&#x021CA;', 'hookrightarrow'=>'&#x021AA;', 'squ'=>'&#x025A1;', 'jfr'=>'&#x1D527;', 'caron'=>'&#x002C7;', 'zwj'=>'&#x200D;', 'apE'=>'&#x02A70;', 'epar'=>'&#x022D5;', 'preceq'=>'&#x02AAF;', 'semi'=>'&#x0003B;', 'rcy'=>'&#x00440;', 
  'varepsilon'=>'&#x003F5;', 'Kfr'=>'&#x1D50E;', 'blk12'=>'&#x02592;', 'cupor'=>'&#x02A45;', 'ldsh'=>'&#x021B2;', 'ImaginaryI'=>'&#x02148;', 'Tcy'=>'&#x00422;', 'Rarrtl'=>'&#x02916;', 'vrtri'=>'&#x022B3;', 'ohbar'=>'&#x029B5;', 'Ofr'=>'&#x1D512;', 'ggg'=>'&#x022D9;', 'Ncaron'=>'&#x00147;', 'lsim'=>'&#x02272;', 'phis'=>'&#x003D5;', 'dharr'=>'&#x021C2;', 'wedge'=>'&#x02227;', 'cwint'=>'&#x02231;', 'nhpar'=>'&#x02AF2;', 'xoplus'=>'&#x02A01;', 
  'supsub'=>'&#x02AD4;', 'lfr'=>'&#x1D529;', 'uacute'=>'&#x000FA;', 'supnE'=>'&#x02ACC;', 'DoubleLongRightArrow'=>'&#x027F9;', 'rrarr'=>'&#x021C9;', 'Ascr'=>'&#x1D49C;', 'EmptyVerySmallSquare'=>'&#x025AB;', 'NotTildeEqual'=>'&#x02244;', 'lnsim'=>'&#x022E6;', 'nprec'=>'&#x02280;', 'triangle'=>'&#x025B5;', 'olcir'=>'&#x029BE;', 'notindot'=>'&#x022F5;&#x00338;', 'bfr'=>'&#x1D51F;', 'PartialD'=>'&#x02202;', 'leftrightsquigarrow'=>'&#x021AD;', 'lbrace'=>'&#x0007B;', 'xrarr'=>'&#x027F6;', 'upsilon'=>'&#x003C5;', 
  'nleqq'=>'&#x02266;&#x00338;', 'pfr'=>'&#x1D52D;', 'tdot'=>'&#x020DB;', 'boxVH'=>'&#x0256C;', 'rdsh'=>'&#x021B3;', 'LeftTee'=>'&#x022A3;', 'erarr'=>'&#x02971;', 'angle'=>'&#x02220;', 'ntgl'=>'&#x02279;', 'tosa'=>'&#x02929;', 'LessGreater'=>'&#x02276;', 'oopf'=>'&#x1D560;', 'rHar'=>'&#x02964;', 'lessapprox'=>'&#x02A85;', 'nleqslant'=>'&#x02A7D;&#x00338;', 'frac14'=>'&#x000BC;', 'ast'=>'&#x0002A;', 'dArr'=>'&#x021D3;', 'Product'=>'&#x0220F;', 'ccedil'=>'&#x000E7;', 
  'gtdot'=>'&#x022D7;', 'euml'=>'&#x000EB;', 'starf'=>'&#x02605;', 'Uarr'=>'&#x0219F;', 'Upsilon'=>'&#x003A5;', 'MinusPlus'=>'&#x02213;', 'leftrightarrow'=>'&#x02194;', 'nopf'=>'&#x1D55F;', 'pscr'=>'&#x1D4C5;', 'precsim'=>'&#x0227E;', 'permil'=>'&#x02030;', 'lvnE'=>'&#x02268;&#x0FE00;', 'Oscr'=>'&#x1D4AA;', 'boxHU'=>'&#x02569;', 'cuvee'=>'&#x022CE;', 'succ'=>'&#x0227B;', 'Rrightarrow'=>'&#x021DB;', 'biguplus'=>'&#x02A04;', 'lhblk'=>'&#x02584;', 'yuml'=>'&#x000FF;', 
  'gtrless'=>'&#x02277;', 'el'=>'&#x02A99;', 'cire'=>'&#x02257;', 'nexist'=>'&#x02204;', 'Ubrcy'=>'&#x0040E;', 'csube'=>'&#x02AD1;', 'prurel'=>'&#x022B0;', 'Nfr'=>'&#x1D511;', 'leftthreetimes'=>'&#x022CB;', 'Uacute'=>'&#x000DA;', 'oacute'=>'&#x000F3;', 'Leftarrow'=>'&#x021D0;', 'boxUl'=>'&#x0255C;', 'Zscr'=>'&#x1D4B5;', 'nrightarrow'=>'&#x0219B;', 'igrave'=>'&#x000EC;', 'disin'=>'&#x022F2;', 'mopf'=>'&#x1D55E;', 'leqq'=>'&#x02266;', 'intcal'=>'&#x022BA;', 
  'npolint'=>'&#x02A14;', 'quaternions'=>'&#x0210D;', 'rtimes'=>'&#x022CA;', 'Because'=>'&#x02235;', 'ecaron'=>'&#x0011B;', 'equiv'=>'&#x02261;', 'nlt'=>'&#x0226E;', 'Lsh'=>'&#x021B0;', 'iogon'=>'&#x0012F;', 'CloseCurlyDoubleQuote'=>'&#x0201D;', 'fllig'=>'&#x0FB02;', 'nmid'=>'&#x02224;', 'lfisht'=>'&#x0297C;', 'wopf'=>'&#x1D568;', 'image'=>'&#x02111;', 'omicron'=>'&#x03BF;', 'nRightarrow'=>'&#x021CF;', 'hoarr'=>'&#x021FF;', 'triangledown'=>'&#x025BF;', 'rcedil'=>'&#x00157;', 
  'Itilde'=>'&#x00128;', 'rhov'=>'&#x003F1;', 'UpDownArrow'=>'&#x02195;', 'copy'=>'&#x000A9;', 'KJcy'=>'&#x0040C;', 'vartriangleleft'=>'&#x022B2;', 'order'=>'&#x02134;', 'fcy'=>'&#x00444;', 'Cfr'=>'&#x0212D;', 'Bscr'=>'&#x0212C;', 'Jscr'=>'&#x1D4A5;', 'scnE'=>'&#x02AB6;', 'gne'=>'&#x02A88;', 'Ccedil'=>'&#x000C7;', 'jsercy'=>'&#x00458;', 'circeq'=>'&#x02257;', 'Ncy'=>'&#x0041D;', 'div'=>'&#x000F7;', 'EmptySmallSquare'=>'&#x025FB;', 'Dcy'=>'&#x00414;', 
  'par'=>'&#x02225;', 'Wfr'=>'&#x1D51A;', 'GreaterEqualLess'=>'&#x022DB;', 'OpenCurlyQuote'=>'&#x02018;', 'otimesas'=>'&#x02A36;', 'Phi'=>'&#x003A6;', 'xodot'=>'&#x02A00;', 'forkv'=>'&#x02AD9;', 'sup2'=>'&#x000B2;', 'lnap'=>'&#x02A89;', 'hercon'=>'&#x022B9;', 'qint'=>'&#x02A0C;', 'vfr'=>'&#x1D533;', 'subsetneq'=>'&#x0228A;', 'tritime'=>'&#x02A3B;', 'mdash'=>'&#x02014;', 'imagline'=>'&#x02110;', 'boxul'=>'&#x02518;', 'tcy'=>'&#x00442;', 'duhar'=>'&#x0296F;', 
  'mapstoleft'=>'&#x021A4;', 'ccaps'=>'&#x02A4D;', 'reals'=>'&#x0211D;', 'profsurf'=>'&#x02313;', 'timesb'=>'&#x022A0;', 'oror'=>'&#x02A56;', 'Lmidot'=>'&#x0013F;', 'nvHarr'=>'&#x02904;', 'SquareSubset'=>'&#x0228F;', 'cups'=>'&#x0222A;&#x0FE00;', 'llarr'=>'&#x021C7;', 'hearts'=>'&#x02665;', 'leg'=>'&#x022DA;', 'NotDoubleVerticalBar'=>'&#x02226;', 'xcirc'=>'&#x025EF;', 'yacy'=>'&#x0044F;', 'orslope'=>'&#x02A57;', 'lsimg'=>'&#x02A8F;', 'oslash'=>'&#x000F8;', 'dotplus'=>'&#x02214;', 
  'bigcirc'=>'&#x025EF;', 'toea'=>'&#x02928;', 'Zcy'=>'&#x00417;', 'Longleftrightarrow'=>'&#x027FA;', 'LeftVector'=>'&#x021BC;', 'nlarr'=>'&#x0219A;', 'npr'=>'&#x02280;', 'supsim'=>'&#x02AC8;', 'Wscr'=>'&#x1D4B2;', 'rarrfs'=>'&#x0291E;', 'isinE'=>'&#x022F9;', 'coprod'=>'&#x02210;', 'lmoustache'=>'&#x023B0;', 'LeftArrowBar'=>'&#x021E4;', 'eqslantgtr'=>'&#x02A96;', 'tau'=>'&#x003C4;', 'InvisibleTimes'=>'&#x02062;', 'Zfr'=>'&#x02128;', 'telrec'=>'&#x02315;', 'phi'=>'&#x003C6;', 
  'nbumpe'=>'&#x0224F;&#x00338;', 'Icirc'=>'&#x000CE;', 'SupersetEqual'=>'&#x02287;', 'lbrack'=>'&#x0005B;', 'rarr'=>'&#x02192;', 'Xscr'=>'&#x1D4B3;', 'UnionPlus'=>'&#x0228E;', 'frasl'=>'&#x2044;', 'malt'=>'&#x02720;', 'lsquor'=>'&#x0201A;', 'Sc'=>'&#x02ABC;', 'dopf'=>'&#x1D555;', 'primes'=>'&#x02119;', 'eplus'=>'&#x02A71;', 'circledast'=>'&#x0229B;', 'angmsd'=>'&#x02221;', 'Ecirc'=>'&#x000CA;', 'boxvL'=>'&#x02561;', 'scpolint'=>'&#x02A13;', 'barvee'=>'&#x022BD;', 
  'trianglerighteq'=>'&#x022B5;', 'Lcedil'=>'&#x0013B;', 'iquest'=>'&#x000BF;', 'digamma'=>'&#x003DD;', 'Imacr'=>'&#x0012A;', 'phgr'=>'&#x003C6;', 'integers'=>'&#x02124;', 'oS'=>'&#x024C8;', 'simne'=>'&#x02246;', 'Darr'=>'&#x021A1;', 'grave'=>'&#x00060;', 'cupcap'=>'&#x02A46;', 'lltri'=>'&#x025FA;', 'cir'=>'&#x025CB;', 'chcy'=>'&#x00447;', 'maltese'=>'&#x02720;', 'ShortUpArrow'=>'&#x02191;', 'quot'=>'&#x00022;', 'DScy'=>'&#x00405;', 'odash'=>'&#x0229D;', 
  'frac78'=>'&#x0215E;', 'scirc'=>'&#x0015D;', 'omacr'=>'&#x0014D;', 'leftharpoondown'=>'&#x021BD;', 'iacute'=>'&#x000ED;', 'ltrPar'=>'&#x02996;', 'uplus'=>'&#x0228E;', 'Wedge'=>'&#x022C0;', 'it'=>'&#x02062;', 'UpArrowDownArrow'=>'&#x021C5;', 'EqualTilde'=>'&#x02242;', 'GreaterTilde'=>'&#x02273;', 'complexes'=>'&#x02102;', 'iscr'=>'&#x1D4BE;', 'approxeq'=>'&#x0224A;', 'apacir'=>'&#x02A6F;', 'aacute'=>'&#x000E1;', 'lurdshar'=>'&#x0294A;', 'measuredangle'=>'&#x02221;', 'epsi'=>'&#x003F5;', 
  'Yacute'=>'&#x000DD;', 'DownTeeArrow'=>'&#x021A7;', 'weierp'=>'&#x02118;', 'vee'=>'&#x02228;', 'NotSubsetEqual'=>'&#x02288;', 'curarrm'=>'&#x0293C;', 'geq'=>'&#x02265;', 'plustwo'=>'&#x02A27;', 'NotPrecedes'=>'&#x02280;', 'apos'=>'&#x00027;', 'Ucy'=>'&#x00423;', 'circleddash'=>'&#x0229D;', 'uarr'=>'&#x02191;', 'ReverseElement'=>'&#x0220B;', 'smile'=>'&#x02323;', 'dwangle'=>'&#x029A6;', 'half'=>'&#x000BD;', 'nesim'=>'&#x02242;&#x00338;', 'Vdash'=>'&#x022A9;', 'backsimeq'=>'&#x022CD;', 
  'hybull'=>'&#x02043;', 'simdot'=>'&#x02A6A;', 'PrecedesEqual'=>'&#x02AAF;', 'YUcy'=>'&#x0042E;', 'vArr'=>'&#x021D5;', 'boxdR'=>'&#x02552;', 'ulcorner'=>'&#x0231C;', 'block'=>'&#x02588;', 'blacktriangleright'=>'&#x025B8;', 'Ocirc'=>'&#x000D4;', 'ltrif'=>'&#x025C2;', 'sc'=>'&#x0227B;', 'rarrw'=>'&#x0219D;', 'middot'=>'&#x000B7;', 'nsc'=>'&#x02281;', 'LeftVectorBar'=>'&#x02952;', 'sum'=>'&#x02211;', 'lopar'=>'&#x02985;', 'doublebarwedge'=>'&#x02306;', 'cap'=>'&#x02229;', 
  'YIcy'=>'&#x00407;', 'nrtrie'=>'&#x022ED;', 'mnplus'=>'&#x02213;', 'boxDr'=>'&#x02553;', 'colon'=>'&#x0003A;', 'Udblac'=>'&#x00170;', 'pitchfork'=>'&#x022D4;', 'hopf'=>'&#x1D559;', 'HumpDownHump'=>'&#x0224E;', 'asympeq'=>'&#x0224D;', 'spades'=>'&#x02660;', 'GreaterSlantEqual'=>'&#x02A7E;', 'sol'=>'&#x0002F;', 'lambda'=>'&#x003BB;', 'Eacute'=>'&#x000C9;', 'sqsupset'=>'&#x02290;', 'rangle'=>'&#x027E9;', 'eth'=>'&#x000F0;', 'zcy'=>'&#x00437;', 'xhArr'=>'&#x027FA;', 
  'rcaron'=>'&#x00159;', 'dharl'=>'&#x021C3;', 'Ecy'=>'&#x0042D;', 'Gamma'=>'&#x00393;', 'gtrsim'=>'&#x02273;', 'Longleftarrow'=>'&#x027F8;', 'backsim'=>'&#x0223D;', 'LessFullEqual'=>'&#x02266;', 'Mu'=>'&#x039C;', 'cross'=>'&#x02717;', 'lthree'=>'&#x022CB;', 'Rsh'=>'&#x021B1;', 'gescc'=>'&#x02AA9;', 'diams'=>'&#x02666;', 'andv'=>'&#x02A5A;', 'Dcaron'=>'&#x0010E;', 'lbrksld'=>'&#x0298F;', 'nleq'=>'&#x02270;', 'nsubE'=>'&#x02AC5;&#x00338;', 'Sopf'=>'&#x1D54A;', 
  'SHCHcy'=>'&#x00429;', 'itilde'=>'&#x00129;', 'plusdo'=>'&#x02214;', 'npreceq'=>'&#x02AAF;&#x00338;', 'planckh'=>'&#x0210E;', 'ldrushar'=>'&#x0294B;', 'lotimes'=>'&#x02A34;', 'ange'=>'&#x029A4;', 'ofr'=>'&#x1D52C;', 'boxuL'=>'&#x0255B;', 'drbkarow'=>'&#x02910;', 'Ifr'=>'&#x02111;', 'dotsquare'=>'&#x022A1;', 'HorizontalLine'=>'&#x02500;', 'yen'=>'&#x000A5;', 'Therefore'=>'&#x02234;', 'barwedge'=>'&#x02305;', 'rang'=>'&#x027E9;', 'dstrok'=>'&#x00111;', 'eDot'=>'&#x02251;', 
  'DoubleContourIntegral'=>'&#x0222F;', 'Gcirc'=>'&#x0011C;', 'nless'=>'&#x0226E;', 'isinv'=>'&#x02208;', 'NotGreater'=>'&#x0226F;', 'subset'=>'&#x02282;', 'gnsim'=>'&#x022E7;', 'ccups'=>'&#x02A4C;', 'nsccue'=>'&#x022E1;', 'leftleftarrows'=>'&#x021C7;', 'supE'=>'&#x02AC6;', 'supne'=>'&#x0228B;', 'Qscr'=>'&#x1D4AC;', 'DoubleLongLeftRightArrow'=>'&#x027FA;', 'circlearrowleft'=>'&#x021BA;', 'gtrapprox'=>'&#x02A86;', 'drcorn'=>'&#x0231F;', 'acy'=>'&#x00430;', 'urtri'=>'&#x025F9;', 'sime'=>'&#x02243;', 
  'part'=>'&#x02202;', 'LongLeftArrow'=>'&#x027F5;', 'TRADE'=>'&#x2122', 'npar'=>'&#x02226;', 'equivDD'=>'&#x02A78;', 'Element'=>'&#x02208;', 'lopf'=>'&#x1D55D;', 'iff'=>'&#x021D4;', 'setmn'=>'&#x02216;', 'Ouml'=>'&#x000D6;', 'sdot'=>'&#x022C5;', 'RightUpTeeVector'=>'&#x0295C;', 'rharul'=>'&#x0296C;', 'Nu'=>'&#x039D;', 'napE'=>'&#x02A70;&#x00338;', 'Equal'=>'&#x02A75;', 'bumpE'=>'&#x02AAE;', 'fjlig'=>'&#x00066;&#x0006A;', 'questeq'=>'&#x0225F;', 'longleftrightarrow'=>'&#x027F7;', 
  'NotCongruent'=>'&#x02262;', 'Aacute'=>'&#x000C1;', 'Gg'=>'&#x022D9;', 'blacktriangle'=>'&#x025B4;', 'sqcap'=>'&#x02293;', 'blk14'=>'&#x02591;', 'varr'=>'&#x02195;', 'DDotrahd'=>'&#x02911;', 'loang'=>'&#x027EC;', 'LeftDownVectorBar'=>'&#x02959;', 'ReverseUpEquilibrium'=>'&#x0296F;', 'sube'=>'&#x02286;', 'Uparrow'=>'&#x021D1;', 'Coproduct'=>'&#x02210;', 'rarrpl'=>'&#x02945;', 'nsmid'=>'&#x02224;', 'urcrop'=>'&#x0230E;', 'bcy'=>'&#x00431;', 'Breve'=>'&#x002D8;', 'lsaquo'=>'&#x2039;', 
  'lstrok'=>'&#x00142;', 'DownRightVector'=>'&#x021C1;', 'clubsuit'=>'&#x02663;', 'gamma'=>'&#x003B3;', 'Ntilde'=>'&#x000D1;', 'Alpha'=>'&#x0391;', 'Icy'=>'&#x00418;', 'bigcup'=>'&#x022C3;', 'Star'=>'&#x022C6;', 'exponentiale'=>'&#x02147;', 'xlarr'=>'&#x027F5;', 'rarrbfs'=>'&#x02920;', 'Cdot'=>'&#x0010A;', 'ratio'=>'&#x02236;', 'hbar'=>'&#x0210F;', 'angrtvb'=>'&#x022BE;', 'smashp'=>'&#x02A33;', 'Pi'=>'&#x003A0;', 'tscy'=>'&#x00446;', 'glj'=>'&#x02AA4;', 
  'Delta'=>'&#x00394;', 'parsim'=>'&#x02AF3;', 'boxVR'=>'&#x02560;', 'Rightarrow'=>'&#x021D2;', 'ocir'=>'&#x0229A;', 'Dopf'=>'&#x1D53B;', 'larrtl'=>'&#x021A2;', 'multimap'=>'&#x022B8;', 'Zdot'=>'&#x0017B;', 'vartheta'=>'&#x003D1;', 'ring'=>'&#x002DA;', 'blacklozenge'=>'&#x029EB;', 'infintie'=>'&#x029DD;', 'flat'=>'&#x0266D;', 'amp'=>'&#x0026;', 'sqsup'=>'&#x02290;', 'auml'=>'&#x000E4;', 'NotLessTilde'=>'&#x02274;', 'Pfr'=>'&#x1D513;', 'GT'=>'&#x003E', 
  'angmsdad'=>'&#x029AB;', 'angmsdag'=>'&#x029AE;', 'scsim'=>'&#x0227F;', 'ncap'=>'&#x02A43;', 'nge'=>'&#x02271;', 'scy'=>'&#x00441;', 'fflig'=>'&#x0FB00;', 'Longrightarrow'=>'&#x027F9;', 'LeftDownTeeVector'=>'&#x02961;', 'nparallel'=>'&#x02226;', 'isindot'=>'&#x022F5;', 'minusdu'=>'&#x02A2A;', 'Pr'=>'&#x02ABB;', 'divonx'=>'&#x022C7;', 'diam'=>'&#x022C4;', 'squf'=>'&#x025AA;', 'Gfr'=>'&#x1D50A;', 'comp'=>'&#x02201;', 'ZeroWidthSpace'=>'&#x0200B;', 'clubs'=>'&#x02663;', 
  'Auml'=>'&#x000C4;', 'realpart'=>'&#x0211C;', 'laquo'=>'&#x000AB;', 'filig'=>'&#x0FB01;', 'vartriangleright'=>'&#x022B3;', 'seArr'=>'&#x021D8;', 'Qfr'=>'&#x1D514;', 'odblac'=>'&#x00151;', 'Proportion'=>'&#x02237;', 'latail'=>'&#x02919;', 'backcong'=>'&#x0224C;', 'smt'=>'&#x02AAA;', 'colone'=>'&#x02254;', 'gt'=>'&#x0003E;', 'bumpe'=>'&#x0224F;', 'wcirc'=>'&#x00175;', 'qopf'=>'&#x1D562;', 'thetasym'=>'&#x03D1;', 'boxHD'=>'&#x02566;', 'harr'=>'&#x02194;', 
  'boxVr'=>'&#x0255F;', 'ExponentialE'=>'&#x02147;', 'popf'=>'&#x1D561;', 'becaus'=>'&#x02235;', 'boxplus'=>'&#x0229E;', 'nrarrc'=>'&#x02933;&#x00338;', 'ic'=>'&#x02063;', 'Bernoullis'=>'&#x0212C;', 'succneqq'=>'&#x02AB6;', 'intprod'=>'&#x02A3C;', 'nles'=>'&#x02A7D;&#x00338;', 'iocy'=>'&#x00451;', 'bigtriangledown'=>'&#x025BD;', 'VerticalLine'=>'&#x0007C;', 'lat'=>'&#x02AAB;', 'COPY'=>'&#x00A9', 'boxh'=>'&#x02500;', 'lg'=>'&#x02276;', 'Hacek'=>'&#x002C7;', 'NotLessEqual'=>'&#x02270;', 
  'natur'=>'&#x0266E;', 'nexists'=>'&#x02204;', 'uring'=>'&#x0016F;', 'Fcy'=>'&#x00424;', 'KHcy'=>'&#x00425;', 'frac56'=>'&#x0215A;', 'NotSquareSubset'=>'&#x0228F;&#x00338;', 'cirscir'=>'&#x029C2;', 'ncedil'=>'&#x00146;', 'agrave'=>'&#x000E0;', 'Psi'=>'&#x003A8;', 'ndash'=>'&#x02013;', 'congdot'=>'&#x02A6D;', 'vnsub'=>'&#x02282;&#x020D2;', 'subE'=>'&#x02AC5;', 'Wopf'=>'&#x1D54E;', 'NotSucceedsSlantEqual'=>'&#x022E1;', 'NotElement'=>'&#x02209;', 'notnivc'=>'&#x022FD;', 'gnap'=>'&#x02A8A;', 
  'eopf'=>'&#x1D556;', 'cirE'=>'&#x029C3;', 'ssetmn'=>'&#x02216;', 'dfisht'=>'&#x0297F;', 'notni'=>'&#x0220C;', 'Uscr'=>'&#x1D4B0;', 'lessdot'=>'&#x022D6;', 'pr'=>'&#x0227A;', 'ap'=>'&#x02248;', 'uharl'=>'&#x021BF;', 'subrarr'=>'&#x02979;', 'rightharpoondown'=>'&#x021C1;', 'Aring'=>'&#x000C5;', 'Egrave'=>'&#x000C8;', 'gsiml'=>'&#x02A90;', 'rsaquo'=>'&#x203A;', 'RightAngleBracket'=>'&#x027E9;', 'tshcy'=>'&#x0045B;', 'mu'=>'&#x003BC;', 'Prime'=>'&#x02033;', 
  'simg'=>'&#x02A9E;', 'bigodot'=>'&#x02A00;', 'upharpoonleft'=>'&#x021BF;', 'larr'=>'&#x02190;', 'lates'=>'&#x02AAD;&#x0FE00;', 'asymp'=>'&#x02248;', 'gtreqqless'=>'&#x02A8C;', 'cdot'=>'&#x0010B;', 'Lstrok'=>'&#x00141;', 'nvrtrie'=>'&#x022B5;&#x020D2;', 'DoubleRightArrow'=>'&#x021D2;', 'sscr'=>'&#x1D4C8;', 'NotLeftTriangle'=>'&#x022EA;', 'iuml'=>'&#x000EF;', 'Laplacetrf'=>'&#x02112;', 'LongRightArrow'=>'&#x027F6;', 'CirclePlus'=>'&#x02295;', 'upsi'=>'&#x003C5;', 'Atilde'=>'&#x000C3;', 'gnE'=>'&#x02269;', 
  'inodot'=>'&#x00131;', 'TSHcy'=>'&#x0040B;', 'Odblac'=>'&#x00150;', 'oline'=>'&#x203E;', 'Scedil'=>'&#x0015E;', 'RightTriangleBar'=>'&#x029D0;', 'ljcy'=>'&#x00459;', 'between'=>'&#x0226C;', 'And'=>'&#x02A53;', 'npre'=>'&#x02AAF;&#x00338;', 'complement'=>'&#x02201;', 'shchcy'=>'&#x00449;', 'checkmark'=>'&#x02713;', 'phmmat'=>'&#x02133;', 'Updownarrow'=>'&#x021D5;', 'nap'=>'&#x02249;', 'lesdot'=>'&#x02A7F;', 'Iuml'=>'&#x000CF;', 'csup'=>'&#x02AD0;', 'UnderBar'=>'&#x0005F;', 
  'Ccaron'=>'&#x0010C;', 'parallel'=>'&#x02225;', 'gesdoto'=>'&#x02A82;', 'sce'=>'&#x02AB0;', 'Tilde'=>'&#x0223C;', 'curarr'=>'&#x021B7;', 'searr'=>'&#x02198;', 'tscr'=>'&#x1D4C9;', 'rightsquigarrow'=>'&#x0219D;', 'nsqsupe'=>'&#x022E3;', 'Nscr'=>'&#x1D4A9;', 'andslope'=>'&#x02A58;', 'esim'=>'&#x02242;', 'racute'=>'&#x00155;', 'vdash'=>'&#x022A2;', 'delta'=>'&#x003B4;', 'female'=>'&#x02640;', 'npart'=>'&#x02202;&#x00338;', 'boxvh'=>'&#x0253C;', 'NotSquareSupersetEqual'=>'&#x022E3;', 
  'ShortLeftArrow'=>'&#x02190;', 'nearr'=>'&#x02197;', 'supdsub'=>'&#x02AD8;', 'GreaterEqual'=>'&#x02265;', 'fpartint'=>'&#x02A0D;', 'Utilde'=>'&#x00168;', 'Amacr'=>'&#x00100;', 'ngE'=>'&#x02267;&#x00338;', 'Hstrok'=>'&#x00126;', 'zeetrf'=>'&#x02128;', 'jscr'=>'&#x1D4BF;', 'acute'=>'&#x000B4;', 'OpenCurlyDoubleQuote'=>'&#x0201C;', 'ultri'=>'&#x025F8;', 'kcedil'=>'&#x00137;', 'les'=>'&#x02A7D;', 'yucy'=>'&#x0044E;', 'curvearrowleft'=>'&#x021B6;', 'jmath'=>'&#x00237;', 'Iota'=>'&#x0399;', 
  'lagran'=>'&#x02112;', 'quatint'=>'&#x02A16;', 'rsquor'=>'&#x02019;', 'Larr'=>'&#x0219E;', 'xlArr'=>'&#x027F8;', 'bdquo'=>'&#x201E;', 'nvrArr'=>'&#x02903;', 'looparrowright'=>'&#x021AC;', 'Xi'=>'&#x0039E;', 'gcirc'=>'&#x0011D;', 'cent'=>'&#x000A2;', 'nsubseteqq'=>'&#x02AC5;&#x00338;', 'subsub'=>'&#x02AD5;', 'shcy'=>'&#x00448;', 'dash'=>'&#x02010;', 'xcap'=>'&#x022C2;', 'triangleleft'=>'&#x025C3;', 'nLeftarrow'=>'&#x021CD;', 'imath'=>'&#x00131;', 'supplus'=>'&#x02AC0;', 
  'nacute'=>'&#x00144;', 'lrhar'=>'&#x021CB;', 'lescc'=>'&#x02AA8;', 'slarr'=>'&#x02190;', 'PrecedesSlantEqual'=>'&#x0227C;', 'VerticalSeparator'=>'&#x02758;', 'LeftUpTeeVector'=>'&#x02960;', 'approx'=>'&#x02248;', 'rlarr'=>'&#x021C4;', 'rangd'=>'&#x02992;', 'wfr'=>'&#x1D534;', 'cwconint'=>'&#x02232;', 'awint'=>'&#x02A11;', 'puncsp'=>'&#x02008;', 'vsupne'=>'&#x0228B;&#x0FE00;', 'Gammad'=>'&#x003DC;', 'emsp13'=>'&#x02004;', 'thksim'=>'&#x0223C;', 'boxV'=>'&#x02551;', 'Jfr'=>'&#x1D50D;', 
  'triangleq'=>'&#x0225C;', 'Sum'=>'&#x02211;', 'khcy'=>'&#x00445;', 'numero'=>'&#x02116;', 'isin'=>'&#x02208;', 'ang'=>'&#x02220;', 'larrlp'=>'&#x021AB;', 'imof'=>'&#x022B7;', 'nsupseteq'=>'&#x02289;', 'trpezium'=>'&#x023E2;', 'ntriangleright'=>'&#x022EB;', 'Hopf'=>'&#x0210D;', 'ugrave'=>'&#x000F9;', 'Mopf'=>'&#x1D544;', 'dsol'=>'&#x029F6;', 'ETH'=>'&#x000D0;', 'glE'=>'&#x02A92;', 'nvdash'=>'&#x022AC;', 'lparlt'=>'&#x02993;', 'NotHumpDownHump'=>'&#x0224E;&#x00338;', 
  'ncup'=>'&#x02A42;', 'ac'=>'&#x0223E;', 'xotime'=>'&#x02A02;', 'llhard'=>'&#x0296B;', 'xdtri'=>'&#x025BD;', 'LeftTriangle'=>'&#x022B2;', 'tridot'=>'&#x025EC;', 'zacute'=>'&#x0017A;', 'rotimes'=>'&#x02A35;', 'gap'=>'&#x02A86;', 'Ycirc'=>'&#x00176;', 'ClockwiseContourIntegral'=>'&#x02232;', 'Lambda'=>'&#x0039B;', 'nparsl'=>'&#x02AFD;&#x020E5;', 'downharpoonleft'=>'&#x021C3;', 'nsqsube'=>'&#x022E2;', 'Rscr'=>'&#x0211B;', 'prnap'=>'&#x02AB9;', 'frac12'=>'&#x000BD;', 'sfr'=>'&#x1D530;', 
  'veeeq'=>'&#x0225A;', 'jukcy'=>'&#x00454;', 'cuwed'=>'&#x022CF;', 'Jopf'=>'&#x1D541;', 'gneqq'=>'&#x02269;', 'gtlPar'=>'&#x02995;', 'there4'=>'&#x02234;', 'nearrow'=>'&#x02197;', 'rsh'=>'&#x021B1;', 'TildeEqual'=>'&#x02243;', 'varsupsetneq'=>'&#x0228B;&#x0FE00;', 'napid'=>'&#x0224B;&#x00338;', 'Ncedil'=>'&#x00145;', 'boxdr'=>'&#x0250C;', 'ddotseq'=>'&#x02A77;', 'nsucc'=>'&#x02281;', 'vBar'=>'&#x02AE8;', 'Igrave'=>'&#x000CC;', 'esdot'=>'&#x02250;', 'ThickSpace'=>'&#x0205F;&#x0200A;', 
  'Yscr'=>'&#x1D4B4;', 'LT'=>'&#x003C', 'ntlg'=>'&#x02278;', 'Sigma'=>'&#x003A3;', 'boxhU'=>'&#x02568;', 'ocirc'=>'&#x000F4;', 'ropf'=>'&#x1D563;', 'ogon'=>'&#x002DB;', 'nsupe'=>'&#x02289;', 'lacute'=>'&#x0013A;', 'srarr'=>'&#x02192;', 'boxtimes'=>'&#x022A0;', 'SquareUnion'=>'&#x02294;', 'gacute'=>'&#x001F5;', 'nu'=>'&#x003BD;', 'twoheadleftarrow'=>'&#x0219E;', 'robrk'=>'&#x027E7;', 'NJcy'=>'&#x0040A;', 'target'=>'&#x02316;', 'utrif'=>'&#x025B4;', 
  'nlsim'=>'&#x02274;', 'comma'=>'&#x0002C;', 'emsp'=>'&#x02003;', 'nGt'=>'&#x0226B;&#x020D2;', 'lmidot'=>'&#x00140;', 'supmult'=>'&#x02AC2;', 'hcirc'=>'&#x00125;', 'ulcrop'=>'&#x0230F;', 'rarrlp'=>'&#x021AC;', 'angmsdae'=>'&#x029AC;', 'Omega'=>'&#x003A9;', 'cedil'=>'&#x000B8;', 'ge'=>'&#x02265;', 'utri'=>'&#x025B5;', 'oast'=>'&#x0229B;', 'subsim'=>'&#x02AC7;', 'smallsetminus'=>'&#x02216;', 'ffr'=>'&#x1D523;', 'precapprox'=>'&#x02AB7;', 'upsih'=>'&#x03D2;', 
  'nLt'=>'&#x0226A;&#x020D2;', 'Lang'=>'&#x027EA;', 'Pscr'=>'&#x1D4AB;', 'lne'=>'&#x02A87;', 'nrtri'=>'&#x022EB;', 'Yuml'=>'&#x00178;', 'Re'=>'&#x0211C;', 'vsubnE'=>'&#x02ACB;&#x0FE00;', 'homtht'=>'&#x0223B;', 'NotGreaterFullEqual'=>'&#x02266;&#x00338;', 'rbbrk'=>'&#x02773;', 'Upsi'=>'&#x003D2;', 'lceil'=>'&#x02308;', 'RoundImplies'=>'&#x02970;', 'vcy'=>'&#x00432;', 'ContourIntegral'=>'&#x0222E;', 'Gcedil'=>'&#x00122;', 'vellip'=>'&#x022EE;', 'DoubleLeftArrow'=>'&#x021D0;', 'curren'=>'&#x000A4;', 
  'vnsup'=>'&#x02283;&#x020D2;', 'sbquo'=>'&#x201A;', 'sqsubseteq'=>'&#x02291;', 'sstarf'=>'&#x022C6;', 'Omicron'=>'&#x039F;', 'topbot'=>'&#x02336;', 'nle'=>'&#x02270;', 'Lscr'=>'&#x02112;', 'succnapprox'=>'&#x02ABA;', 'oscr'=>'&#x02134;', 'TScy'=>'&#x00426;', 'hslash'=>'&#x0210F;', 'rarrtl'=>'&#x021A3;', 'Zcaron'=>'&#x0017D;', 'eqcirc'=>'&#x02256;', 'shortparallel'=>'&#x02225;', 'scedil'=>'&#x0015F;', 'ffllig'=>'&#x0FB04;', 'bernou'=>'&#x0212C;', 'because'=>'&#x02235;', 
  'DotEqual'=>'&#x02250;', 'szlig'=>'&#x000DF;', 'iiiint'=>'&#x02A0C;', 'siml'=>'&#x02A9D;', 'bigoplus'=>'&#x02A01;', 'PrecedesTilde'=>'&#x0227E;', 'bot'=>'&#x022A5;', 'nesear'=>'&#x02928;', 'amacr'=>'&#x00101;', 'ngeq'=>'&#x02271;', 'succeq'=>'&#x02AB0;', 'Rang'=>'&#x027EB;', 'RightVector'=>'&#x021C0;', 'sharp'=>'&#x0266F;', 'Mfr'=>'&#x1D510;', 'scaron'=>'&#x00161;', 'ltcc'=>'&#x02AA6;', 'bsol'=>'&#x0005C;', 'simplus'=>'&#x02A24;', 'MediumSpace'=>'&#x0205F;', 
  'frac23'=>'&#x02154;', 'lesdotor'=>'&#x02A83;', 'varsubsetneqq'=>'&#x02ACB;&#x0FE00;', 'suphsub'=>'&#x02AD7;', 'bull'=>'&#x02022;', 'ntriangleleft'=>'&#x022EA;', 'straightphi'=>'&#x003D5;', 'tilde'=>'&#x002DC;', 'circledS'=>'&#x024C8;', 'shy'=>'&#x000AD;', 'prnsim'=>'&#x022E8;', 'dtri'=>'&#x025BF;', 'rarrb'=>'&#x021E5;', 'bsime'=>'&#x022CD;', 'Hcirc'=>'&#x00124;', 'zigrarr'=>'&#x021DD;', 'nleftrightarrow'=>'&#x021AE;', 'bopf'=>'&#x1D553;', 'wp'=>'&#x02118;', 'DownArrowBar'=>'&#x02913;', 
  'intercal'=>'&#x022BA;', 'Vee'=>'&#x022C1;', 'lbarr'=>'&#x0290C;', 'bne'=>'&#x0003D;&#x020E5;', 'thetav'=>'&#x003D1;', 'sigmaf'=>'&#x03C2;', 'marker'=>'&#x025AE;', 'rect'=>'&#x025AD;', 'NotLeftTriangleEqual'=>'&#x022EC;', 'empty'=>'&#x02205;', 'Escr'=>'&#x02130;', 'boxminus'=>'&#x0229F;', 'Aopf'=>'&#x1D538;', 'Not'=>'&#x02AEC;', 'Iogon'=>'&#x0012E;', 'trade'=>'&#x02122;', 'NotGreaterEqual'=>'&#x02271;', 'UpTee'=>'&#x022A5;', 'epsilon'=>'&#x03B5;', 'cuesc'=>'&#x022DF;', 
  'elinters'=>'&#x023E7;', 'ne'=>'&#x02260;', 'gl'=>'&#x02277;', 'equals'=>'&#x0003D;', 'para'=>'&#x000B6;', 'Uring'=>'&#x0016E;', 'rtriltri'=>'&#x029CE;', 'DoubleLeftRightArrow'=>'&#x021D4;', 'RightCeiling'=>'&#x02309;', 'frac18'=>'&#x0215B;', 'xmap'=>'&#x027FC;', 'forall'=>'&#x02200;', 'vsupnE'=>'&#x02ACC;&#x0FE00;', 'lnE'=>'&#x02268;', 'ges'=>'&#x02A7E;', 'rightarrow'=>'&#x02192;', 'Scy'=>'&#x00421;', 'ENG'=>'&#x0014A;', 'raquo'=>'&#x000BB;', 'easter'=>'&#x02A6E;', 
  'timesd'=>'&#x02A30;', 'uparrow'=>'&#x02191;', 'nequiv'=>'&#x02262;', 'iiota'=>'&#x02129;', 'Zopf'=>'&#x02124;', 'aopf'=>'&#x1D552;', 'llcorner'=>'&#x0231E;', 'vangrt'=>'&#x0299C;', 'pcy'=>'&#x0043F;', 'lrm'=>'&#x200E;', 'lbrkslu'=>'&#x0298D;', 'nabla'=>'&#x02207;', 'prop'=>'&#x0221D;', 'kgreen'=>'&#x00138;', 'Precedes'=>'&#x0227A;', 'urcorn'=>'&#x0231D;', 'DownRightVectorBar'=>'&#x02957;', 'acd'=>'&#x0223F;', 'yfr'=>'&#x1D536;', 'ccaron'=>'&#x0010D;', 
  'swarr'=>'&#x02199;', 'DownArrow'=>'&#x02193;', 'uHar'=>'&#x02963;', 'ulcorn'=>'&#x0231C;', 'crarr'=>'&#x21B5;', 'REG'=>'&#x00AE', 'lsquo'=>'&#x02018;', 'LessTilde'=>'&#x02272;', 'lessgtr'=>'&#x02276;', 'lesseqgtr'=>'&#x022DA;', 'dd'=>'&#x02146;', 'doteqdot'=>'&#x02251;', 'angmsdaf'=>'&#x029AD;', 'lsime'=>'&#x02A8D;', 'Verbar'=>'&#x02016;', 'diamond'=>'&#x022C4;', 'gtcc'=>'&#x02AA7;', 'ii'=>'&#x02148;', 'subne'=>'&#x0228A;', 'leftarrowtail'=>'&#x021A2;', 
  'orv'=>'&#x02A5B;', 'mid'=>'&#x02223;', 'macr'=>'&#x000AF;', 'Ecaron'=>'&#x0011A;', 'mapstodown'=>'&#x021A7;', 'Gt'=>'&#x0226B;', 'NotTilde'=>'&#x02241;', 'RightArrowBar'=>'&#x021E5;', 'doteq'=>'&#x02250;', 'longleftarrow'=>'&#x027F5;', 'eta'=>'&#x003B7;', 'GJcy'=>'&#x00403;', 'rightthreetimes'=>'&#x022CC;', 'nsub'=>'&#x02284;', 'incare'=>'&#x02105;', 'SquareIntersection'=>'&#x02293;', 'ngtr'=>'&#x0226F;', 'rfisht'=>'&#x0297D;', 'boxUL'=>'&#x0255D;', 'ogt'=>'&#x029C1;', 
  'NotSuperset'=>'&#x02283;&#x020D2;', 'supdot'=>'&#x02ABE;', 'Cconint'=>'&#x02230;', 'LeftDoubleBracket'=>'&#x027E6;', 'hscr'=>'&#x1D4BD;', 'Dscr'=>'&#x1D49F;', 'vprop'=>'&#x0221D;', 'Eogon'=>'&#x00118;', 'LeftTriangleBar'=>'&#x029CF;', 'lAarr'=>'&#x021DA;', 'atilde'=>'&#x000E3;', 'lang'=>'&#x027E8;', 'Rcedil'=>'&#x00156;', 'bigotimes'=>'&#x02A02;', 'Xopf'=>'&#x1D54F;', 'VeryThinSpace'=>'&#x0200A;', 'Jcy'=>'&#x00419;', 'Implies'=>'&#x021D2;', 'int'=>'&#x0222B;', 'bemptyv'=>'&#x029B0;', 
  'Bcy'=>'&#x00411;', 'Im'=>'&#x02111;', 'infin'=>'&#x0221E;', 'rlm'=>'&#x200F;', 'sqsube'=>'&#x02291;', 'parsl'=>'&#x02AFD;', 'gE'=>'&#x02267;', 'ubrcy'=>'&#x0045E;', 'Omacr'=>'&#x0014C;', 'ufr'=>'&#x1D532;', 'NotHumpEqual'=>'&#x0224F;&#x00338;', 'NotTildeTilde'=>'&#x02249;', 'DotDot'=>'&#x020DC;', 'reg'=>'&#x000AE;', 'angrt'=>'&#x0221F;', 'zwnj'=>'&#x200C;', 'hyphen'=>'&#x02010;', 'dlcorn'=>'&#x0231E;', 'CHcy'=>'&#x00427;', 'NotEqualTilde'=>'&#x02242;&#x00338;', 
  'supedot'=>'&#x02AC4;', 'boxH'=>'&#x02550;', 'kopf'=>'&#x1D55C;', 'Downarrow'=>'&#x021D3;', 'DoubleLongLeftArrow'=>'&#x027F8;', 'nvltrie'=>'&#x022B4;&#x020D2;', 'simeq'=>'&#x02243;', 'radic'=>'&#x0221A;', 'mcomma'=>'&#x02A29;', 'boxdl'=>'&#x02510;', 'ecolon'=>'&#x02255;', 'njcy'=>'&#x0045A;', 'boxVL'=>'&#x02563;', 'umacr'=>'&#x0016B;', 'lobrk'=>'&#x027E6;', 'therefore'=>'&#x02234;', 'ngt'=>'&#x0226F;', 'nfr'=>'&#x1D52B;', 'ShortRightArrow'=>'&#x02192;', 'downdownarrows'=>'&#x021CA;', 
  'Barwed'=>'&#x02306;', 'VerticalTilde'=>'&#x02240;', 'ccirc'=>'&#x00109;', 'LeftAngleBracket'=>'&#x027E8;', 'lbbrk'=>'&#x02772;', 'LeftUpVectorBar'=>'&#x02958;', 'thkap'=>'&#x02248;', 'Ccirc'=>'&#x00108;', 'triangleright'=>'&#x025B9;', 'xsqcup'=>'&#x02A06;', 'ecy'=>'&#x0044D;', 'nvap'=>'&#x0224D;&#x020D2;', 'HARDcy'=>'&#x0042A;', 'Lcaron'=>'&#x0013D;', 'imagpart'=>'&#x02111;', 'Scirc'=>'&#x0015C;', 'duarr'=>'&#x021F5;', 'ubreve'=>'&#x0016D;', 'lowast'=>'&#x02217;', 'sqcaps'=>'&#x02293;&#x0FE00;', 
  'Wcirc'=>'&#x00174;', 'Umacr'=>'&#x0016A;', 'bigtriangleup'=>'&#x025B3;', 'plusmn'=>'&#x000B1;', 'expectation'=>'&#x02130;', 'Hscr'=>'&#x0210B;', 'spar'=>'&#x02225;', 'iopf'=>'&#x1D55A;', 'quest'=>'&#x0003F;', 'divide'=>'&#x000F7;', 'fnof'=>'&#x00192;', 'Dashv'=>'&#x02AE4;', 'NotEqual'=>'&#x02260;', 'SuchThat'=>'&#x0220B;', 'notinE'=>'&#x022F9;&#x00338;', 'urcorner'=>'&#x0231D;', 'hfr'=>'&#x1D525;', 'hkswarow'=>'&#x02926;', 'UpperLeftArrow'=>'&#x02196;', 'Iscr'=>'&#x02110;', 
  'wedbar'=>'&#x02A5F;', 'oplus'=>'&#x02295;', 'acirc'=>'&#x000E2;', 'sup'=>'&#x02283;', 'mldr'=>'&#x02026;', 'gtrarr'=>'&#x02978;', 'Square'=>'&#x025A1;', 'dcaron'=>'&#x0010F;', 'gtquest'=>'&#x02A7C;', 'NotGreaterGreater'=>'&#x0226B;&#x00338;', 'Efr'=>'&#x1D508;', 'nhArr'=>'&#x021CE;', 'bigsqcup'=>'&#x02A06;', 'ncaron'=>'&#x00148;', 'NotCupCap'=>'&#x0226D;', 'sect'=>'&#x000A7;', 'RightArrow'=>'&#x02192;', 'varkappa'=>'&#x003F0;', 'sopf'=>'&#x1D564;', 'niv'=>'&#x0220B;', 
  'ominus'=>'&#x02296;', 'TripleDot'=>'&#x020DB;', 'lharu'=>'&#x021BC;', 'capdot'=>'&#x02A40;', 'yscr'=>'&#x1D4CE;', 'Theta'=>'&#x00398;', 'pluscir'=>'&#x02A22;', 'mstpos'=>'&#x0223E;', 'lesssim'=>'&#x02272;', 'xscr'=>'&#x1D4CD;', 'simlE'=>'&#x02A9F;', 'precneqq'=>'&#x02AB5;', 'iukcy'=>'&#x00456;', 'searhk'=>'&#x02925;', 'ngeqq'=>'&#x02267;&#x00338;', 'Lacute'=>'&#x00139;', 'Congruent'=>'&#x02261;', 'cfr'=>'&#x1D520;', 'bigwedge'=>'&#x022C0;', 'lE'=>'&#x02266;', 
  'vopf'=>'&#x1D567;', 'bullet'=>'&#x02022;', 'rtrif'=>'&#x025B8;', 'scnap'=>'&#x02ABA;', 'OverBrace'=>'&#x023DE;', 'gtcir'=>'&#x02A7A;', 'Gopf'=>'&#x1D53E;', 'geqslant'=>'&#x02A7E;', 'leftharpoonup'=>'&#x021BC;', 'frac38'=>'&#x0215C;', 'Xfr'=>'&#x1D51B;', 'Eopf'=>'&#x1D53C;', 'Vcy'=>'&#x00412;', 'sext'=>'&#x02736;', 'DifferentialD'=>'&#x02146;', 'nsim'=>'&#x02241;', 'rhard'=>'&#x021C1;', 'supseteq'=>'&#x02287;', 'DownRightTeeVector'=>'&#x0295F;', 'uopf'=>'&#x1D566;', 
  'ltdot'=>'&#x022D6;', 'midast'=>'&#x0002A;', 'sup3'=>'&#x000B3;', 'xuplus'=>'&#x02A04;', 'nVDash'=>'&#x022AF;', 'smtes'=>'&#x02AAC;&#x0FE00;', 'notinvc'=>'&#x022F6;', 'spadesuit'=>'&#x02660;', 'ntrianglelefteq'=>'&#x022EC;', 'Vopf'=>'&#x1D54D;', 'sqsub'=>'&#x0228F;', 'vltri'=>'&#x022B2;', 'Zacute'=>'&#x00179;', 'eng'=>'&#x0014B;', 'nvDash'=>'&#x022AD;', 'caret'=>'&#x02041;', 'NotPrecedesSlantEqual'=>'&#x022E0;', 'notnivb'=>'&#x022FE;', 'ocy'=>'&#x0043E;', 'sqsubset'=>'&#x0228F;', 
  'ijlig'=>'&#x00133;', 'rsqb'=>'&#x0005D;', 'supe'=>'&#x02287;', 'timesbar'=>'&#x02A31;', 'RightTeeArrow'=>'&#x021A6;', 'lfloor'=>'&#x0230A;', 'Zeta'=>'&#x0396;', 'Cross'=>'&#x02A2F;', 'DoubleLeftTee'=>'&#x02AE4;', 'nvinfin'=>'&#x029DE;', 'Subset'=>'&#x022D0;', 'ape'=>'&#x0224A;', 'rbrksld'=>'&#x0298E;', 'NoBreak'=>'&#x02060;', 'nang'=>'&#x02220;&#x020D2;', 'lozf'=>'&#x029EB;', 'pointint'=>'&#x02A15;', 'prcue'=>'&#x0227C;', 'DownLeftVectorBar'=>'&#x02956;', 'SubsetEqual'=>'&#x02286;', 
  'uml'=>'&#x000A8;', 'subplus'=>'&#x02ABF;', 'gvnE'=>'&#x02269;&#x0FE00;', 'GreaterGreater'=>'&#x02AA2;', 'nltrie'=>'&#x022EC;', 'tfr'=>'&#x1D531;', 'curlywedge'=>'&#x022CF;', 'Vfr'=>'&#x1D519;', 'vDash'=>'&#x022A8;', 'NestedLessLess'=>'&#x0226A;', 'RuleDelayed'=>'&#x029F4;', 'lmoust'=>'&#x023B0;', 'CloseCurlyQuote'=>'&#x02019;', 'gimel'=>'&#x02137;', 'eDDot'=>'&#x02A77;', 'rtrie'=>'&#x022B5;', 'roarr'=>'&#x021FE;', 'eogon'=>'&#x00119;', 'nprcue'=>'&#x022E0;', 'DD'=>'&#x02145;', 
  'diamondsuit'=>'&#x02666;', 'acE'=>'&#x0223E;&#x00333;', 'capcap'=>'&#x02A4B;', 'succsim'=>'&#x0227F;', 'downharpoonright'=>'&#x021C2;', 'curlyvee'=>'&#x022CE;', 'lEg'=>'&#x02A8B;', 'cirfnint'=>'&#x02A10;', 'Leftrightarrow'=>'&#x021D4;', 'zeta'=>'&#x003B6;', 'nharr'=>'&#x021AE;', 'percnt'=>'&#x00025;', 'rbrkslu'=>'&#x02990;', 'nsime'=>'&#x02244;', 'supsetneqq'=>'&#x02ACC;', 'hellip'=>'&#x02026;', 'bigvee'=>'&#x022C1;', 'nLl'=>'&#x022D8;&#x00338;', 'kjcy'=>'&#x0045C;', 'Ugrave'=>'&#x000D9;', 
  'SquareSuperset'=>'&#x02290;', 'aelig'=>'&#x000E6;', 'Sfr'=>'&#x1D516;', 'Integral'=>'&#x0222B;', 'tcedil'=>'&#x00163;', 'ee'=>'&#x02147;', 'bsolb'=>'&#x029C5;', 'RightUpVectorBar'=>'&#x02954;', 'nshortmid'=>'&#x02224;', 'strns'=>'&#x000AF;', 'nrarrw'=>'&#x0219D;&#x00338;', 'Sacute'=>'&#x0015A;', 'boxvr'=>'&#x0251C;', 'Int'=>'&#x0222C;', 'phone'=>'&#x0260E;', 'Ll'=>'&#x022D8;', 'rcub'=>'&#x0007D;', 'Supset'=>'&#x022D1;', 'lscr'=>'&#x1D4C1;', 'elsdot'=>'&#x02A97;', 
  'supsetneq'=>'&#x0228B;', 'VerticalBar'=>'&#x02223;', 'smte'=>'&#x02AAC;', 'Cup'=>'&#x022D3;', 'Fouriertrf'=>'&#x02131;', 'larrhk'=>'&#x021A9;', 'eqslantless'=>'&#x02A95;', 'Copf'=>'&#x02102;', 'RightDownTeeVector'=>'&#x0295D;', 'harrw'=>'&#x021AD;', 'subsup'=>'&#x02AD3;', 'ucy'=>'&#x00443;', 'precnapprox'=>'&#x02AB9;', 'equest'=>'&#x0225F;', 'ShortDownArrow'=>'&#x02193;', 'rarrhk'=>'&#x021AA;', 'VDash'=>'&#x022AB;', 'excl'=>'&#x00021;', 'bsim'=>'&#x0223D;', 'seswar'=>'&#x02929;', 
  'Aogon'=>'&#x00104;', 'backprime'=>'&#x02035;', 'leftrightarrows'=>'&#x021C6;', 'UpTeeArrow'=>'&#x021A5;', 'succcurlyeq'=>'&#x0227D;', 'angmsdaa'=>'&#x029A8;', 'Equilibrium'=>'&#x021CC;', 'nrArr'=>'&#x021CF;', 'Iopf'=>'&#x1D540;', 'lsqb'=>'&#x0005B;', 'lhard'=>'&#x021BD;', 'nwnear'=>'&#x02927;', 'Otilde'=>'&#x000D5;', 'oelig'=>'&#x00153;', 'Mellintrf'=>'&#x02133;', 'LeftTeeVector'=>'&#x0295A;', 'iexcl'=>'&#x000A1;', 'blank'=>'&#x02423;', 'commat'=>'&#x00040;', 'frown'=>'&#x02322;', 
  'abreve'=>'&#x00103;', 'boxdL'=>'&#x02555;', 'twixt'=>'&#x0226C;', 'mDDot'=>'&#x0223A;', 'Cscr'=>'&#x1D49E;', 'lsh'=>'&#x021B0;', 'lvertneqq'=>'&#x02268;&#x0FE00;', 'drcrop'=>'&#x0230C;', 'vert'=>'&#x0007C;', 'qfr'=>'&#x1D52E;', 'NotNestedGreaterGreater'=>'&#x02AA2;&#x00338;', 'boxVl'=>'&#x02562;', 'ascr'=>'&#x1D4B6;', 'nvgt'=>'&#x0003E;&#x020D2;', 'DownLeftTeeVector'=>'&#x0295E;', 'andand'=>'&#x02A55;', 'yacute'=>'&#x000FD;', 'IJlig'=>'&#x00132;', 'iecy'=>'&#x00435;', 'uuarr'=>'&#x021C8;', 
  'RightVectorBar'=>'&#x02953;', 'topcir'=>'&#x02AF1;', 'sfrown'=>'&#x02322;', 'lbrke'=>'&#x0298B;', 'cemptyv'=>'&#x029B2;', 'minus'=>'&#x02212;', 'mho'=>'&#x02127;', 'circledcirc'=>'&#x0229A;', 'mumap'=>'&#x022B8;', 'bowtie'=>'&#x022C8;', 'le'=>'&#x02264;', 'capand'=>'&#x02A44;', 'xi'=>'&#x003BE;', 'bepsi'=>'&#x003F6;', 'circlearrowright'=>'&#x021BB;', 'DoubleDownArrow'=>'&#x021D3;', 'hardcy'=>'&#x0044A;', 'LeftDownVector'=>'&#x021C3;', 'orarr'=>'&#x021BB;', 'cirmid'=>'&#x02AEF;', 
  'brvbar'=>'&#x000A6;', 'UpEquilibrium'=>'&#x0296E;', 'lneq'=>'&#x02A87;', 'SucceedsSlantEqual'=>'&#x0227D;', 'cudarrr'=>'&#x02935;', 'yopf'=>'&#x1D56A;', 'LeftRightArrow'=>'&#x02194;', 'Rfr'=>'&#x0211C;', 'dcy'=>'&#x00434;', 'rceil'=>'&#x02309;', 'ltlarr'=>'&#x02976;', 'DoubleVerticalBar'=>'&#x02225;', 'shortmid'=>'&#x02223;', 'Rarr'=>'&#x021A0;', 'frac34'=>'&#x000BE;', 'rAtail'=>'&#x0291C;', 'LessSlantEqual'=>'&#x02A7D;', 'gesdot'=>'&#x02A80;', 'gbreve'=>'&#x0011F;', 'gvertneqq'=>'&#x02269;&#x0FE00;', 
  'els'=>'&#x02A95;', 'Bumpeq'=>'&#x0224E;', 'boxHd'=>'&#x02564;', 'succnsim'=>'&#x022E9;', 'solbar'=>'&#x0233F;', 'sung'=>'&#x0266A;', 'smid'=>'&#x02223;', 'nwarrow'=>'&#x02196;', 'eqvparsl'=>'&#x029E5;', 'egrave'=>'&#x000E8;', 'LeftRightVector'=>'&#x0294E;', 'nsimeq'=>'&#x02244;', 'star'=>'&#x02606;', 'LeftTeeArrow'=>'&#x021A4;', 'UpArrow'=>'&#x02191;', 'subsetneqq'=>'&#x02ACB;', 'fltns'=>'&#x025B1;', 'softcy'=>'&#x0044C;', 'veebar'=>'&#x022BB;', 'FilledSmallSquare'=>'&#x025FC;', 
  'TildeFullEqual'=>'&#x02245;', 'Vvdash'=>'&#x022AA;', 'jopf'=>'&#x1D55B;', 'Rcy'=>'&#x00420;', 'sdote'=>'&#x02A66;', 'SquareSubsetEqual'=>'&#x02291;', 'NotSupersetEqual'=>'&#x02289;', 'IEcy'=>'&#x00415;', 'RightDownVector'=>'&#x021C2;', 'upuparrows'=>'&#x021C8;', 'otilde'=>'&#x000F5;', 'mapsto'=>'&#x021A6;', 'zscr'=>'&#x1D4CF;', 'Nopf'=>'&#x02115;', 'Ubreve'=>'&#x0016C;', 'nvsim'=>'&#x0223C;&#x020D2;', 'ruluhar'=>'&#x02968;', 'subnE'=>'&#x02ACB;', 'boxv'=>'&#x02502;', 'not'=>'&#x000AC;', 
  'rdquor'=>'&#x0201D;', 'eparsl'=>'&#x029E3;', 'subedot'=>'&#x02AC3;', 'ecirc'=>'&#x000EA;', 'neArr'=>'&#x021D7;', 'boxDl'=>'&#x02556;', 'lrtri'=>'&#x022BF;', 'scE'=>'&#x02AB4;', 'gla'=>'&#x02AA5;', 'ohm'=>'&#x03A9;', 'divideontimes'=>'&#x022C7;', 'RightTeeVector'=>'&#x0295B;', 'hairsp'=>'&#x0200A;', 'trie'=>'&#x0225C;', 'napprox'=>'&#x02249;', 'imacr'=>'&#x0012B;', 'sccue'=>'&#x0227D;', 'ngsim'=>'&#x02275;', 'NonBreakingSpace'=>'&#x000A0;', 'ltquest'=>'&#x02A7B;', 
  'range'=>'&#x029A5;', 'Uuml'=>'&#x000DC;', 'mp'=>'&#x02213;', 'lap'=>'&#x02A85;', 'larrb'=>'&#x021E4;', 'lesges'=>'&#x02A93;', 'dHar'=>'&#x02965;', 'Idot'=>'&#x00130;', 'Map'=>'&#x02905;', 'ni'=>'&#x0220B;', 'erDot'=>'&#x02253;', 'boxhd'=>'&#x0252C;', 'nsce'=>'&#x02AB0;&#x00338;', 'beta'=>'&#x003B2;', 'plusb'=>'&#x0229E;', 'minusd'=>'&#x02238;', 'udhar'=>'&#x0296E;', 'profalar'=>'&#x0232E;', 'prod'=>'&#x0220F;', 'zhcy'=>'&#x00436;', 
  'curlyeqsucc'=>'&#x022DF;', 'ordm'=>'&#x000BA;', 'csub'=>'&#x02ACF;', 'bigcap'=>'&#x022C2;', 'Agrave'=>'&#x000C0;', 'dot'=>'&#x002D9;', 'deg'=>'&#x000B0;', 'times'=>'&#x000D7;', 'LessEqualGreater'=>'&#x022DA;', 'gsim'=>'&#x02273;', 'hookleftarrow'=>'&#x021A9;', 'boxvR'=>'&#x0255E;', 'theta'=>'&#x003B8;', 'boxhD'=>'&#x02565;', 'nVdash'=>'&#x022AE;', 'Hfr'=>'&#x0210C;', 'cong'=>'&#x02245;', 'intlarhk'=>'&#x02A17;', 'xfr'=>'&#x1D535;', 'iiint'=>'&#x0222D;', 
  'SOFTcy'=>'&#x0042C;', 'rfr'=>'&#x1D52F;', 'hArr'=>'&#x021D4;', 'lt'=>'&#x003C;', 'nsucceq'=>'&#x02AB0;&#x00338;', 'blk34'=>'&#x02593;', 'NotLess'=>'&#x0226E;', 'Succeeds'=>'&#x0227B;', 'bnequiv'=>'&#x02261;&#x020E5;', 'sqsupseteq'=>'&#x02292;', 'NotLessLess'=>'&#x0226A;&#x00338;', 'edot'=>'&#x00117;', 'Ffr'=>'&#x1D509;', 'olarr'=>'&#x021BA;', 'angmsdab'=>'&#x029A9;', 'geqq'=>'&#x02267;', 'emacr'=>'&#x00113;', 'triplus'=>'&#x02A39;', 'DZcy'=>'&#x0040F;', 'Afr'=>'&#x1D504;', 
  'bsolhsub'=>'&#x27C8;', 'sub'=>'&#x02282;', 'Nacute'=>'&#x00143;', 'Rcaron'=>'&#x00158;', 'lpar'=>'&#x00028;', 'Kcy'=>'&#x0041A;'
}

$ref = {}
$fig_ctr = 0
$footnote_ctr = 0
$footnote_stack = []

#===============================================================================================================================
#===============================================================================================================================
#===============================================================================================================================
#                                                methods
#===============================================================================================================================
#===============================================================================================================================
#===============================================================================================================================

def preprocess(tex,command_data,style_files)
  # command_data looks like {"unitdot":{"n_req":0,"n_opt":0},...}; only lists commands that we've specifically been told to handle
  curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested
  style = ''
  style_files.each { |s|  style = style + "\n" + slurp_file(s) }

  # delete material marked to be ignored by me
  ignore_these_keys = []
  tex.scan(/begin_ignore_for_web:(\d+)/) {
    ignore_these_keys.push($1)
  }
  ignore_these_keys.each { |n|
    tex.sub!(Regexp.new("%begin_ignore_for_web:#{n}.*%end_ignore_for_web:#{n}\n",Regexp::MULTILINE),'') 
  }

  # Convert summary and hwsection environments into sections, which is what they really are, anyway.
  ['summary','hwsection'].each { |s|
    a = {'summary'=>'Summary','hwsection'=>'Homework Problems'}[s]
    begin
      tex.gsub!(/\\begin{#{s}}((.|\n)*)\\end{#{s}}/) {"\\mysection{*#{a}}#{$1}"} # The * warns later code not to produce a section number in the header.
    rescue ArgumentError
      $stderr.print "Illegal character in input. This typically happens with things like octal 322 for curly quotes. Can troubleshoot by running it through clean_up_text and then doing a diff.\n"
      raise
    end
  }

  tex.gsub!(/mysubsectionnotoc/) {"mysubsection"}
  tex.gsub!(/(myoptionalsection)(\[\d\])?{/) {"mysection{?"} # ? marks it as optional
  tex.gsub!(/(myoptionalcalcsection)(\[\d\])?{/) {"mysection{@"} # @ marks it as calc-based, optional
  tex.gsub!(/(mycalcsection)(\[\d\])?{/) {"mysection{@"} # @ marks it as calc-based, optional

  # remove comments and indexing (indexing is evil when it occurs inside sectioning, messes everything up)
  # First, preserve percent signs inside listing and verbatim environments:
  r = {}
  s = {}
  envs = ['listing','verbatim']
  envs.each { |x|
    pat = x
    s[x] = "\\\\(?:begin|end){#{pat}}"
    z = s[x].clone  # workaround for bug in the ruby interpreter, which causes the first 8 bytes of the regex string to be overwritten with garbage
    r[x] = Regexp.new(z)
  }  
  envs.each { |x|
    result = ''
    inside = false # even if the environment starts at the beginning of the string, split() gives us a null string as our first string
    tex.split(r[x]).each { |d|
      if !(d=~/\A\s*\Z/) then
        if inside then
          d.gsub!(/%/,'KEEP_PERCENT')
          d = "\\begin{#{x}}" + d + "\\end{#{x}}"
        end
        result = result + d
      end
      inside = !inside
    } # end loop over d
    tex = result
  } # end loop over x

  tex.gsub!(/\\index{#{curly}}/,'')

  # Get rid of comments:
  tex.gsub!(/(?<!\\)%[^\n]*(\n?[ \t]*)?/,'')

  # remove whitespace from lines consisting of nothing but whitespace
  tex.gsub!(/^[ \t]+$/,'')

  # kludge, fix:
  tex.gsub!(/myoptionalsection/,'mysection')

  tex = apply_custom_macros(tex,command_data,style)

  # minipages inside figures aren't necessary in html, and confuse the parser
  tex.gsub!(/\\begin{minipage}\[[a-z]\]{\d+[a-z]*}/,'')
  tex.gsub!(/\\end{minipage}/,'')
  # ... and, e.g., make it do something sensible with non-graphical figures, as in EM 1
  tex.gsub!(/\\docaption{(#{curly})}/) {"ZZZWEB:fig,zzzfake,narrow,1,#{newlines_to_spaces($1)}END_CAPTION"} # name,width,anon,caption

  return tex
end

def apply_custom_macros(tex,command_data,style)
  # command_data looks like [cmds,info], where info looks like {"unitdot":{"n_req":0,"n_opt":0},...}; 
  #         only lists commands that we've specifically been told to handle
  # style is the LaTeX source code defining these commands
  curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested
  max_depth = 30
  1.upto(max_depth) {
    before = tex.clone
    command_data[0].each { |c|
      info = command_data[1][c]
      if info==nil then fatal_error("no command_data for #{c} in apply_custom_macros, so it shouldn't be in custom_html.yaml") end
      n_req,n_opt = [info['n_req'],info['n_opt']]
      if style =~ /\\newcommand{\\#{c}}\s*(?:\[(\d+)\])?\s*{(#{curly})}/ then
        nargs,definition = [$1,$2]
        if n_req==0 && n_opt==0 then tex.gsub!(/\\#{c}/,definition) end
        if n_req==1 && n_opt==0 then tex.gsub!(/\\#{c}{(#{curly})}/) {definition.gsub(/#1/,$1)} end
      else
        $stderr.print "failed to find definition for \\#{c}\n"
      end
    }
    break if before==tex
  }
  return tex
end

def process(tex,environment_data)
  result = ''
  parse(tex,1,[],environment_data).each {|s|
    t,m = s[0],s[1]
    m = '<div class="margin">' + parse_para(m) + '</div>'  unless m=~/\A\s*\Z/
    # FIXME: The following is meant to get the divs *after* the <h2> for a section, so that the css "clear" mechanism works properly.
    # This should really be handled by making parse return an array of triplets, (h,t,m), rather than (t,m).
    h = ''
    level = nil
    1.upto(2) { |i|
      if t =~ /^(\s*<h#{i}>(?:<a #{$anchor}=[^>]+><\/a>)?(?:[^<>]+)<\/h#{i}>)((.|\n)*)/ then
        h,t,level=$1,$2,i
      end
    }
    if level==2 then result = result + "___AD___" end
    result = result + h + m + t # m has to come first, because that causes it to be positioned as close as possible to the top of the section
  }
  return result
end

def postprocess(tex)
  curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested
  tex.gsub!(/ {2,}/,' ') # multiple spaces
  tex.gsub!(/<p>\s*<\/p>/,'') # peepholer to get rid of <p></p> pairs
  tex.gsub!(/\n{3,}/,"\n\n") # 3 or more newlines in a row
  tex.gsub!(/\\&/,"&amp;")
  tex.gsub!(/&(?![a-zA-Z0-9#]+;)/,"&amp;")
  tex.gsub!(/<\/h1>\n*<\/p>/,"</h1>") # happens in NP, which has part I, II, ...; see above in handling for mypart
  tex.gsub!(/<td>([^<>]+)<\/t>/) {"<td>#{$1}<\/td>"}; # bug in htlatex?
  tex.gsub!(/<!-- ZZZ_TWO_NEWLINES -->/,"\n\n")

  tex.gsub!(/#{$begin_div_not_p}(<div class="equation">([^\n])+)#{$end_div_not_p}\n/) {"</p>#{$1}<p>"}
  tex.gsub!(/#{$begin_div_not_p}/,'')
  tex.gsub!(/#{$end_div_not_p}/,'')

  # for human-readability, keep lines from getting too long:
  tex.gsub!(/(?<!\n)(<div)/) {"\n#{$1}"}
  tex.gsub!(/\n{0,1}(<p[^ ])/) {"\n\n#{$1}"}
  tex.gsub!(/(<\/p>)\n{0,1}/) {"#{$1}\n\n"}

  1.upto(10) { |i| # Allow for nesting 10 deep.
    $hide_types.each { |type|
      pat = "(#{hide_code('[0-9a-f]+)',type)}"
      tex.gsub!(/(#{hide_code('[0-9a-f]+',type)})/) {
        #$stderr.print "replacing #{pat} with #{$1}"
        $hide[type][$1]
      }
    }
  }
  tex.gsub!(/<p><!--BEGIN_IMG-->/) {''}
  tex.gsub!(/<!--END_IMG--><\/p>/) {''}
  tex.gsub!(/<p>\s*(<div\s+class="[^"]*"\s*>)/) {$1}
  tex.gsub!(/(<\/div>)\s*<\/p>/) {$1}
  tex.gsub!(/(Example \d+): ZZZ_NO_EG_TITLE/) {$1}

  tex.gsub!(/KEEP_INDENTATION_(\d+)_SPACES/) {replicate_string(' ',$1.to_i)}
  tex.gsub!(/<!-- ZZZ_END_OF_CAPTION -->/,"")


  # ultra-kludge: depend on the formatting of the code at this point to let us to a final cleanup of a small number of cases where the $begin_div_not_p kludge didn't work:
  if $no_displayed_math_inside_paras then
    paras = []
    tex.split(/\n{2,}/).each { |para|
      if para=~/\A<p/ && para=~/<\/p>\Z/ then
        old = para.clone()
        para.gsub!(/^(<div)(.*)(<\/div>)$/) {"</p>\n\n#{$1}#{$2}#{$3}<!-- I will come to your emotional rescue. -->\n\n<p>"}
        #if old!=para then $stderr.print "******** changed from:\n#{old}\n******** to:\n#{para}\n********\n" end
      end
      paras.push(para)
    }
    tex = paras.join("\n\n")
  end

  tex.gsub!(/\\\$/,'$') # Do this here to avoid confusion with $...$ for math.

  if $wiki then
    ['p','a','div'].each { |x|
      tex.gsub!(/<#{x}(\s+[^>]*)?>/,'')
      tex.gsub!(/<\/#{x}>/,'')
    }
    #tex.gsub!(/<img src="(figs|math)\/([^"]*)"([^>]*)>/) {"[http://www.lightandmatter.com/html_books/#{$config['book']}/ch#{$ch}/#{$1}/#{$2} figure #{$2} needs to be imported]"}
    tex.gsub!(/<img src="(figs|math)\/([^"]*)"([^>]*)>/) {"{{Missing_fig|book=#{$config['book']}|ch=#{$ch}|file=#{$2}}} - "}
    tex.gsub!(/(\n+)\s+/) {$1}
    tex.gsub!(/<br>\n?{2,}\s+/,"<br>\n")
  end

  $mathml_entities_to_numbers.each_pair { |k,v| tex.gsub!(/\&#{k};/,v) } # see comments near top of file

  if !$wiki then tex =  "<div class=\"container\">\n"+tex+"</div>\n" end

  # Google only allows three ads per page.
  1.upto(3) {
    tex.sub!(/___AD___/) {generate_ad_if_appropriate}
  }
  tex.gsub!(/___AD___/,'') # eliminate the rest

  return tex
end

def html_subdir(subdir)
  d = $config['html_dir'] + '/ch' + $ch + '/' + subdir
  make_directory_if_nonexistent(d,'html_subdir')
  return d
end

def all_figs_inline
  return $config['all_figs_inline']==1
end

def make_directory_if_nonexistent(d,context)
  if ! File.exist?(d) then
    if system("mkdir -p #{d}") then
      $stderr.print "translate_to_html.rb successfuly created directory #{d}, context=#{context}\n"
    else
      $stderr.print "error in translate_to_html.rb, #{$?}, creating directory #{d}, context=#{context}\n"
      exit(-1) 
    end
  end
end

def wiki_style_section(n)
  h = ''
  (n-1).times do |i|
    h = h + '='
  end
  return h
end

def parse_itty_bitty_stuff!(tex)
  curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested
  tex.gsub!(/\\verb@([^@]*)@/) {"\\verb{#{$1}}"}  # The \verb{} macro can be given with other delimeters, and I often use \verb@@.
  tex.gsub!(/\\verb\-([^\-]*)\-/) {"\\verb{#{$1}}"}  # ... or \verb--
  tex.gsub!(/\\verb{(#{curly})}/) {"<span class='monospace'>#{$1}</span>"}
  ["a","e","i","o","u"].each { |vowel|
    accents = {"`"=>'grave',"'"=>'acute','"'=>'uml'}
    accents.keys.each { |acc|
      entity = "&"+vowel+accents[acc]+";"
      tex.gsub!(/\\#{acc}\{#{vowel}\}/) {entity}
      tex.gsub!(/\\#{acc}#{vowel}/) {entity}
    }
  }
  tex.gsub!(/\\O{}/,'&Oslash;')
  tex.gsub!(/\\ae{}/,'&aelig;')
  tex.gsub!(/\.~/,'. ')
  tex.gsub!(/\\\-/,'')
  if !$mathjax then tex.gsub!(/\\ /,' ') end
  tex.gsub!(/\\%/,'%')
  tex.gsub!(/\\#/,'#')
  tex.gsub!(/\\(quad|qquad)/,' ')
  tex.gsub!(/\\hfill({#{curly}})?/,' ')
  tex.gsub!(/\\photocredit{(#{curly})}/) {" (#{$1})"}
  tex.gsub!(/\\textbf{(#{curly})}/) {"<b>#{$1}</b>"}
  tex.gsub!(/\\(?:textit|emph){(#{curly})}/) {"<i>#{$1}</i>"}
  tex.gsub!(/{\s*\\footnotesize\s+(#{curly})\s*}/) {"<span style=\"font-size: small;\">#{$1}</span>"}
  if $wiki then
    tex.gsub!(/\\mypart{(#{curly})}/) {"\n\n=#{$1}=\n\n"} # extra newlines prevent confusion with <p></p> tags in NP 2, 6
    tex.gsub!(/\\formatlikesubsection{(#{curly})}/) {"===#{$1}==="}
  else
    tex.gsub!(/\\mypart{(#{curly})}/) {"\n\n<h1>#{$1}</h1>\n\n"} # extra newlines prevent confusion with <p></p> tags in NP 2, 6
    tex.gsub!(/\\formatlikesubsection{(#{curly})}/) {"<h3>#{$1}</h3>"}
  end
  tex.gsub!(/\\begin{indentedblock}/,'<div class="indentedblock"><p>')
  tex.gsub!(/\\end{indentedblock}/,'</p></div>')
  tex.gsub!(/\\begin{quote}/,'<div class="indentedblock"><p>')
  tex.gsub!(/\\end{quote}/,'</p></div>')
  tex.gsub!(/\\begin{offsettopic}/,'<div class="indentedblock"><p>')
  tex.gsub!(/\\end{offsettopic}/,'</p></div>')
  tex.gsub!(/\\epigraphnobyline{(#{curly})}/) {"<div class=\"epigraph\">#{$1}</div>"}
  tex.gsub!(/\\hwremark{(#{curly})}/) {"<div class=\"hwremark\">#{$1}</div>"}
  tex.gsub!(/\\oneofaseriesofpoints{(#{curly})}{(#{curly})}/) {"<b>#{$1}</b> #{$2}"}
  tex.gsub!(/\\linebreak/,$br)
  tex.gsub!(/\\pagebreak/,'')
  tex.gsub!(/\\smspacebetweenfigs/,'')
  tex.gsub!(/\\raggedright/,'')
  tex.gsub!(/\\thompson/,' [Thompson, 1919] ')
  tex.gsub!(/\\granville/,' [Granville, 1911] ')

  # environments that we don't care about:
  tex.gsub!(/\\(begin|end){(preface|longnoteafterequation|flushleft)}/,'')

  tex.gsub!(/\\anonymousinlinefig{(#{curly})}/) {name = $1; file=find_figure(name,'raw'); "<img src=\"figs/#{file}\" alt=\"#{name}\"#{$self_closing_tag}>"}
  tex.gsub!(/\\fullpagewidthfignocaption{(#{curly})}/) {name = $1; file=find_figure(name,'fullpage'); "<img src=\"figs/#{file}\" alt=\"#{name}\"#{$self_closing_tag}>"}
end

def parse_marg_stuff!(m)
  m.gsub!(/[ ]*\\(vfill|spacebetweenfigs)[ ]*/,'')
  m.gsub!(/[ ]*\\(vspace|hspace){[^}]+}[ ]*/,'')
  m.replace(parse_eensy_weensy(handle_tables(m)))
end

def parse_macros_outside_para!(tex)

  # macros that may occur by themselves, not part of any paragraph:
  tex.gsub!(/[ ]*\\(vspace|hspace|enlargethispage){[^}]+}[ ]*/,'')
  tex.gsub!(/[ ]*\\pagebreak\[\d+\][ ]*/,'')
  tex.gsub!(/[ ]*\\(vfill|spacebetweenfigs)[ ]*/,'')
  tex.gsub!(/[ ]*\\addtocontents[^\n]*[ ]*/,'')

  curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested
  if $wiki then
    tex.gsub!(/\\startdq(s?)/) {"''Discussion Question#{$1}''\n\n"}
    tex.gsub!(/\\extitle{(#{curly})}{(#{curly})}/) {"===Exercise #{$1}: #{$2}==="}
  else
    tex.gsub!(/\\startdq(s?)/) {"<h5 class=\"dq\">Discussion Question#{$1}</h5>\n\n"}
    tex.gsub!(/\\extitle{(#{curly})}{(#{curly})}/) {"<h3>Exercise #{$1}: #{$2}</h3>"}
  end
  tex.gsub!(/\\selfcheck{[^}]*}{(#{curly})}/) {"\\begin{selfcheck}#{$1}\\end{selfcheck}"} # kludge for SN, which doesn't have them as environments; fails if nested {} inside $1
end

def get_environment_data
  # Read command and environment data from learned_commands.json and custom_html.yaml.
  # Returns [envs,env_data], where
  #   envs = array containing names of environments that we actually intend to try to parse (only those in custom_html.yaml)
  #   env_data = a hash containing info about each of those environments (plus data about other environments that we don't intend to try to parse)
  # The only environments we actually try to parse are those in custom_html.yaml.
  # In learned_commands.json, inferred from .cls file:
  #   n_req = # of required args
  #   n_opt = # of optional args (0 or 1)
  #   default = default value for optional arg
  # In custom.json:
  #   use_arg_as_title : true, or number of arg to use, or nil if we don't want to use an arg as the title
  #   generate_header : e.g., [2,'Summary'] -- level of <hN> tag, text of header
  #   used only for environments that are going to become divs:
  #     stick_in : string that goes right before the text
  #     stick_at_end : goes right after text
  #     stick_in_front_of_header
  #   used only for environments that are not going to become divs:
  #     surround_with_tag : e.g., 'ol' means surround it with <ol>...</ol>; must be present for anything that will not be a div
  learned = get_serialized_data_from_file("learned_commands.json")['environment'] # {"eg":{"n_req":0,"n_opt":1,"default":""},...}
  custom =  get_serialized_data_from_file($custom_config)['environment']           # {"eg":{"use_arg_as_title":true,...},...}
  env_data = {}
  learned.merge(custom).keys.each { |e|
    if learned.has_key?(e) && custom.has_key?(e) then
      env_data[e] = learned[e].merge(custom[e])
    else
      env_data[e] = learned[e] if learned.has_key?(e)
      env_data[e] = custom[e] if custom.has_key?(e)
    end
  }
  return [custom.keys,env_data]
end

def get_command_data
  # similar to get_environment_data(), but does commands rather than environments
  # commands are ignored unless they're listed in custom config
  learned = get_serialized_data_from_file("learned_commands.json")['command'] # {"unitdot":{"n_req":0,"n_opt":0},...}
  custom =  get_serialized_data_from_file($custom_config)['command']          # {"unitdot":{},...}
  cmd_data = {}
  learned.merge(custom).keys.each { |c|
    if learned.has_key?(c) && custom.has_key?(c) then
      cmd_data[c] = learned[c].merge(custom[c])
    end
  }
  return [custom.keys,cmd_data]
end

def parse_section(tex,environment_data)
  envs,env_data = environment_data
  parse_macros_outside_para!(tex)
  curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested

  # <ol>, <ul>, and <pre> can't occur inside paragraphs, so make sure they're separated into their own paragraphs.
  # These are the environments that have a surround_with_tag (['itemize','enumerate','listing','tabular','verbatim'), plus tabular.
  envs.select { |x| env_data[x].has_key?('surround_with_tag') }.push('tabular').each { |x|
    tex.gsub!(/(\\begin{#{x}})/) {"\n\n#{$1}"}
    tex.gsub!(/(\\end{#{x}})/) {"#{$1}\n\n"}
  }

  # Optional arguments are confusing, so replace them with {} that are always there.
  envs_opt = envs.select{ |x| env_data[x].has_key?('n_opt') && env_data[x]['n_opt']>0} 
  r = {}
  envs_opt.each { |x|
    r[x] = /\\(?:begin|end){#{Regexp::quote(x)}}/ # workaround for ruby bug
  }  
  envs_opt.each { |x|
    result = ''
    inside = false # even if the environment starts at the beginning of the string, split() gives us a null string as our first string
    tex.split(r[x]).each { |d|
      if !(d=~/\A\s*\Z/) then
        if inside then
          if d=~/\A\[[^\]]*\]/ then
            d.gsub!(/\A\[([^\]]*)\]/) {"{#{$1}}"}
          else
            d = "{}" + d
          end
          d = "\\begin{#{x}}" + d + "\\end{#{x}}"
        end # if inside
        result = result + d
      end
      inside = !inside
    }
    tex = result
  }

  tex.gsub!(/egwide/,'eg')
  tex.gsub!(/\\begin{description}/,'\\begin{itemize}')
  tex.gsub!(/\\end{description}/,'\\end{itemize}')
  hw = 1

  # hwsection and summary are actually not needed in the following, since we change them to mysection using regexes early on
  # hwwithsoln is taken care of in prep_web.pl to homework

  r = {}
  s = {}
  envs.each { |x|
    pat = x
    s[x] = "\\\\(?:begin|end){#{Regexp::quote(pat)}}"
    z = s[x].clone  # workaround for bug in the ruby interpreter, which causes the first 8 bytes of the regex string to be overwritten with garbage
    r[x] = Regexp.new(z)
  }  
  envs.each { |x|
    nargs = nil
    if env_data[x].has_key?('n_req') && env_data[x].has_key?('n_opt') then nargs = env_data[x]['n_req']+env_data[x]['n_opt'] end
    use_arg_as_title = env_data[x].has_key?('use_arg_as_title') ? env_data[x]['use_arg_as_title'] : nil
    # The following become nil if the key doesn't exist:
    generate_header = env_data[x]['generate_header']
    stick_in = env_data[x]['stick_in']
    stick_at_end = env_data[x]['stick_at_end']
    stick_in_front_of_header = env_data[x]['stick_in_front_of_header']
    surround_with_tag = env_data[x]['surround_with_tag']

    will_not_be_a_div = surround_with_tag!=nil
    # Normally we hide what's inside an environment from the parser so it doesn't get confused. Don't do it on ones that won't be divs, because it doesn't work on those:
    no_hiding = will_not_be_a_div
    result = ''
    inside = false # even if the environment starts at the beginning of the string, split() gives us a null string as our first string
    tex.split(r[x]).each { |d|
      if !(d=~/\A\s*\Z/) then
        if inside then
          if nargs==nil then fatal_error("environment #{x} is used, but I can't infer how many arguments it takes from learned_commands.json; add data to custom.json") end
          if generate_header!=nil then
            l,h = generate_header[0],generate_header[1]
            if $wiki then
              equals = wiki_style_section(l)
              d = "#{equals}#{h}#{equals}\n\n" + d
            else
              d = "<h#{l}>#{h}</h#{l}>\n\n" + d
            end
          end
          args=[]
          if nargs then
           1.upto(nargs) { |i|
              d=~/\A{(#{curly})}/
              args[i]=$1
              d.gsub!(/\A{([^}]*)}/,'')
            }
          end
          arg = args[1]
          if use_arg_as_title!=nil then
            if use_arg_as_title==true then title=arg else title=args[use_arg_as_title] end
            if title!=nil and title.length>0 then
              title = handle_math(title)
              front = ''
              if stick_in_front_of_header!=nil then
                front=stick_in_front_of_header.clone
                if x=='eg' then $count_eg += 1 ; front.gsub!(/NNNEG/) {$count_eg.to_s} end
              end
              if $wiki then
                d = "=====#{front}#{title}=====\n#{d}"
              else
                d = "<h5 class=\"#{x}\">#{front}#{title}</h5>\n#{d}"
              end
            end
          end
          if $wiki then
            top = "\n\n"
            bottom = "\n\n"
          else
            type_of_div = x
            if x=='homeworkforcelabel' then type_of_div='homework' end
            top = "\n\n<div class=\"#{type_of_div}\">\n\n"
            bottom = "\n\n</div>\n\n"
          end
          if x=~/\A(homework|hw|homeworkforcelabel)\Z/ then 
            d = "<b>#{hw}</b>. " + d
            hw+=1
            if args[1]!='' && !$wiki && $config['forbid_anchors_and_links']==0 then top = top + "<a #{$anchor}=\"hw:#{arg}\"></a>" end
            if args[3]=='1' then d = d + " &int;" end
          end
          if x=='reading' then top = top + "<b>#{args[1]}</b>, <i>#{args[2]}</i>. " end
          if stick_in!=nil then top = top + stick_in end
          if x=='dialogline' then top = top + arg + ': ' end 
          if surround_with_tag!=nil then 
            top="<#{surround_with_tag}>"
            bottom="</#{surround_with_tag}>"
            top.gsub!(/DQCTR/) {$dq_ctr} 
          end
          if stick_at_end!=nil then bottom = stick_at_end+bottom end
          if x=='listing' or x=='verbatim' then
            d.gsub!(/(<br>|<br\/>|<i>|<\/i>)/,'')
            d.gsub!('<','&lt;')
            d.gsub!('>','&gt;')
            d.gsub!(/\n\s*\n/,"\nKEEP_BLANK_LINE\n")
            d.gsub!(/\n(\s+)/) {"\nKEEP_INDENTATION_#{$1.length}_SPACES"}
          end
          if x=='enumerate' or x=='itemize' then
            d.gsub!(/\\item\[([^\]]*)\]/) {"</li><li><b>#{$1}</b> "}
            d.gsub!(/\\item/,'</li><li>')
            d.sub!('</li>','') # get rid of bogus closing tag at first item
            d = d + '</li>' # add closing tag on last item
          end
          unless no_hiding then
            y = top + parse_section(d,environment_data) + bottom 
            result = result + "\n\n#{hide(y,'env')}\n\n"
          else
            result = result + top + d + bottom 
          end
        else # not inside
          result = result + d
        end
      end
      inside = !inside
    } # end loop over d
    tex = result
  } # end loop over x

  # Massage tabular environments:
  # Change tabular* to tabular:
  tex.gsub!(/\\begin{tabular\*}{#{curly}}/,'\\begin{tabular}')
  tex.gsub!(/\\end{tabular\*}/,'\\end{tabular}')
  # Eliminate extra newlines in tabulars:
  tex.gsub!(/(\\begin{tabular})\n*/) {"\n\n"+$1}
  tex.gsub!(/\n*(\\end{tabular})/) {$1+"\n\n"}

  # Bug fix for case like \section{foo}\label{bar}, which becomes incorrectly joined together with the following paragraph. See calc, ch 1, subsec "A derivative."
  # Looks like this at this point:
  #   <h3> A derivative</h3>
  #   \label{scaling}
  #   That proves that $\xdot(1)=1$, but it was a lot of work, and we don't want to do
  tex.gsub!(/(<h\d>[^<]+<\/h\d>\s*\n\\label{[^}]+}\n)([A-Z])/) {"#{$1}\n#{$2}"}

  # Break it up into paragraphs, parse each paragraph, surround paras with <p> tags, but make sure not to make <p></p> pairs that surround one half of a <div></div> pair.
  # So far, the low-level parsing of equations and tables hasn't happened, so we don't have any of those divs yet. All we have is higher level ones, like
  # <div class="eg">. The way those were produced above, we made sure each <div> or </div> was on a line by itself, with blank lines above and below it.
  # Also, <p> tags can't contain any of the following: <p>, <h>, <div>
  # Bug: if parse_para returns something with nested divs in it, the code below won't work properly.
  result = ''
  tex.split(/\n{2,}/).each { |para|
    debug = false
    if para=~/^(<div|<\/div)/ then
      p = para
    else
      cooked = parse_para(para)
      #$stderr.print "cooked=============\n#{cooked}\n==============\n" if debug
      if para=~/<h\d/ or para=~/<p[^a-z]/ then # bug, won't work with wiki output
        p = cooked
      else
        # Can't have <div>'s nested inside <p>, so if there are equations, etc...:
        if !(cooked=~/<table/) then
          cooked.gsub!(/(<div)/) {"</p>"+$1}
          cooked.gsub!(/(<\/div>)/) {$1+"<p class=\"noindent\">"}
        end
        p = "\n\n" + '<p>' + cooked + "</p>\n\n"
      end
    end
    result = result + p
  }
  tex = result

  # Eliminate illegal and unnecessary <p> tags inside <ol>, <ul>, or <pre>.
  ['ol','ul','pre'].each { |x|
    result = ''
    inside = false # even if the environment starts at the beginning of the string, split() gives us a null string as our first string
    tex.split(/<\/?#{x}>/).each { |d|
      if !(d=~/\A\s*\Z/) then
        if inside then
          d.gsub!(/<p>/,'')
          d.gsub!(/<\/p>/,'')
          d = "<#{x}>" + d + "</#{x}>"
        end # if inside
        result = result + d
      end
      inside = !inside
    }
    tex = result
  }

  # Also can't enclose <ol>, <ul>, <pre>, or <table> inside <p>.
  ['ol','ul','pre','table'].each { |x|
    tex.gsub!(/<p>\s*<#{x}([^>]*)>/) {"<#{x}#{$1}>"}
    tex.gsub!(/<\/#{x}>\s*<\/p>/) {"</#{x}>"}
  }

  tex.gsub!(/KEEP_BLANK_LINE/,'')
  tex.gsub!(/KEEP_PERCENT/,'%')
  tex.gsub!(/\\&/,"&amp;")
  tex.gsub!(/&(?!#?\w+;)/,"&amp;")

  return tex
end

def replicate_string(s,n)
  if n<=0 then return '' end
  return s + replicate_string(s,n-1)  
end

def replace_list(x,r)
  # r = hash with regexes as keys
  k = r.keys.sort {|a,b| b.source.length <=> a.source.length} # do long ones first, so, e.g., \munit doesn't get parsed as \mu
  k.each { |a|
    b=r[a]
    debug = false
    $stderr.print "doing #{a.to_s} to #{b} on #{x}\n" if debug
    x.gsub!(a,b)
  }
  return x
end

def parse_simple_equation(x)
  debug = (x =~  /\(1\/f - 1\/d_i\)/)
  if x =~ /\\\\/ then return nil end
  if debug then $stderr.print "debugging #{x}\n" end
  # A common special case: a single boldfaced letter:
  if x=~/^\\vc{([a-zA-Z])}$/ then
    return "<b>#{$1}</b>" # I think this would already be a TEXTb0001x before we got in here
  end
  # The following is all complicated because < and > look like html.
  x.gsub!(/\\ll/,"\\lt\\lt")
  x.gsub!(/\\gg/,"\\gt\\gt")
  # don't want macros \munit and \nunit to be read as greek letters \mu and \nu
  x.gsub!(/\\munit/,"qqqmunitqqq")
  x.gsub!(/\\nunit/,"qqqnunitqqq")
  y = nil
  # Protect < and >, which would look like html:
  if x=~/(.*)([<>])(.*)/ then
    left,op,right = $1,$2,$3
    if op=='<' then u="\\lt" else u="\\gt" end
    left = parse_simple_equation(left)
    right = parse_simple_equation(right)
    if left!=nil and right!=nil then
      return left+u+right
    else
      return nil
    end
  end
  # nothing but whitespace, variables, digits, decimal points, addition, subtraction, division, equality, commas, parens, ||, symbols,
  # superscripts and subscripts, primes:
  if x=~/^((?:[ \ta-zA-Z\d\.\+\-\/\=\,\(\)\|{}\^\_\']|(?:\\(?:#{$tex_symbol_pat})))+)$/ then
    y = $1
    curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested
    y.gsub!(/\^{(#{curly})}/) {"<sup>#{$1}</sup>"}
    y.gsub!(/\_{(#{curly})}/) {"<sub>#{$1}</sub>"}
    y.gsub!(/\^(\\[a-z]+)/) {"<sup>#{$1}</sup>"} # e.g., e^\pi
    y.gsub!(/\_(\\[a-z]+)/) {"<sub>#{$1}</sub>"} # e.g., E_\perp
    y.gsub!(/\^(.)/) {"<sup>#{$1}</sup>"}
    y.gsub!(/\_(.)/) {"<sub>#{$1}</sub>"}
    y.gsub!(/qqqmunitqqq/,"\\munit")
    y.gsub!(/qqqnunitqqq/,"\\nunit")
  end
  if debug then $stderr.print "debugging final result is #{y}\n" end
  return y
end

def truth_to_s(t)
  if t then return 'true' else return 'false' end
end

# Be careful not to return nested div's, because the code in parse_section can't handle that.
def handle_tables(tex)
  #$stderr.print "calledme\n"
  n= -1
  table = []


  result = ''
  inside = false # even if it starts with the environment, we get a null string for our first chunk
  tex.split(/\\(?:begin|end){tabular}/).each { |m|
    if !(m=~/\A\s*\Z/) then
      if inside then
        n+=1;
        table[n] = m
        # In the following, I'm not sure why I used to surround it in a div.table. I don't define any such div in lm.css.
        # Doing it resulted in ill-formed xhtml.
        # result = result + "<div class=\"table\">TABLE#{n}\.</div>"
        result = result + "TABLE#{n}."
      else
        result = result + m
      end
    end
    inside = !inside # needs to be outside the test for whether m is null, because we get a null for first chunk if string begins with envir
  }
  tex = result

  table.each_index { |n|
    m = handle_table_one(table[n])
    if m==nil then m=table[n] end
    tex.gsub!(/TABLE#{n}\./,m)
  }

  return tex

end

# arg is everything inside the tabular environment, including the parameter of the begin{tabular}.
# When tex4ht converts the table, it will convert the math inside it as well.
# However, it may generate bitmaps for complex math, which I don't want it to do inside a table (script can't handle it).
# Therefore, if a table comes back from tex4ht with bitmaps in it, we replace each bitmap with its alt value, and give a warning.
def handle_table_one(original)
        cache_dir = html_subdir('cache_tables')
        hash = hash_function(original)
        if $xhtml then ext='.xhtml' else ext='.html' end
        cache_file = cache_dir + '/table_' + hash + ext
        if (!$redo_all_tables) && File.exist?(cache_file) then
          return slurp_file(cache_file)
        end

        t = original.clone
        t = "\\begin{tabular}" + t + "\\end{tabular}"

        summarize = t.clone
        summarize =~ /^((.|\n){,80})/
        summarize = $1
        summarize.gsub!(/\n/,' ')
        $stderr.print "Producing table from latex code #{summarize}...\n"
        temp = 'temp.tex'
        temp_html = 'temp.html'
        File.open(temp,'w') do |f|
        f.print <<-TEX
  	\\documentclass{book}[12pt]
	\\RequirePackage{lmmath,amssymb,cancel}
        \\RequirePackage[leqno]{amsmath}
        \\begin{document}
        #{t}
        \\end{document}               
        TEX
        end # file
        doomed =  false 
        html = ''
        if doomed then
          $stderr.print "****************************This table is marked as not working -- not doing it ***********************************\n"
          return ''
        else
          if !File.exist?(temp) then $stderr.print "error, temp file #{temp} doesn't exist"; exit(-1) end
          fmt = 'html'
          if $xhtml then fmt='xhtml' end
          unless system("#{$config['script_dir']}/latex_table_to_html.pl #{temp} #{$config['sty_dir']}/lmmath.sty #{fmt} >/dev/null") then
            $stderr.print "warning, error translating table to html, #{$?}"
          end
          html = slurp_file(temp_html)
          if html.nil? then html='' end
          html.gsub!(/\n*$/,"\n") # exactly one newline at the end
        end
        failed = false
        html.gsub!(/<img[^<>]*alt=\"([^"]*)\"[^<>]*>/) {failed=true; $1} # replace image with its alt tag
        if failed then $stderr.print "warning, this table has complex math, couldn't do it correctly\n" end
        html.gsub!(/\n{2,}/,"\n")

        if html==nil or html=='' then
          $stderr.print "warning: table generated nil or null string for html"
        else
          html.gsub!(/<div class="tabular">/,'')
          html.gsub!(/<\/div>/,'')

          # The following are obsolete in html 5, validator complains about them:
          html.gsub!(/cellspacing="\d+"/,' ')
          html.gsub!(/cellpadding="\d+"/,' ')

          File.open(cache_file,'w') do |f|
            f.print html
          end
        end


        return html
end

# This was faster, but lost a lot of formatting, and couldn't handle complicated tables.
def handle_table_one_myself(original)
  t = original.clone
  t.gsub!(/\A{[^}]+}/,'') # get rid of, e.g., {|l|l|l|}
  t.gsub!(/\\hline/,'')
  result = ''
  t.split(/\\\\/).each { |line|
    unless line=~/\A\s*\Z/ then
      line = '<tr><td>' + ( line.split(/\&/).join('</td><td>') ) + '</td></tr>'
    end
    result = result + line + "\n"
  }
  return "<table>\n#{result}</table>\n"
end

# Handle all math occurring in a block of text.
# Be careful not to return nested div's, because the code in parse_section can't handle that.
def handle_math(tex,inline_only=false,allow_bitmap=true)

  n= -1
  math = []
  math_type = [] # inline, equation, align, multline, gather

  curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested

  unless inline_only then

  tex.gsub!(/\\mygamma/) {"\\gamma"}

  if false then # I think this is no longer necessary now that I'm using footex, and in fact it causes problems.
  #--------------------- locate displayed math with intertext or multiple lines, and split into smaller pieces ----------------------------
  ############################### DEACTIVATED BY IF FALSE ABOVE #####################
  # This has to come before inline ($...$) math, because sometimes displayed math has \text{...$...$...} inside it.
  envs = ['align','equation','multline','gather','align*','equation*','multline*','gather*']
  r = {}
  s = {}
  envs.each { |x|
    pat = x.clone
    pat.gsub!(/\*/,'\\*')
    s[x] = "\\\\(?:begin|end){#{pat}}"
    z = s[x].clone # workaround for bug in the ruby interpreter, which causes the first 8 bytes of the regex string to be overwritten with garbage
    r[x] = Regexp.new(z)
  }  
  envs.each { |x|
    result = ''
    inside = false # even if it starts with the environment, we get a null string for our first chunk
    tex.split(r[x]).each { |m|
      if !(m=~/\A\s*\Z/) then # not pure whitespace
        if inside then 
          debug = m=~/\\vc{v} &= \\frac{\\der/
          debug = true
          m.gsub!(/\\\\\s*\\intertext{(#{curly})}/) {"\\end{#{x}}\n#{$1}\n\\begin{#{x}}"}
          m.gsub!(/\\\\/,"\\end{#{x}}\n\\begin{#{x}}")
          result = result + "\\begin{#{x}}"
          result = result + m
          result = result + "\\end{#{x}}"
        else
          result = result + m
        end
      end
      inside = !inside # needs to be outside the test for whether m is null, because we get a null for first chunk if string begins with envir
    }
    tex = result
  } # end loop over align, equation, ...
  end

  #--------------------- locate displayed math ----------------------------
  # This has to come before inline ($...$) math, because sometimes displayed math has \text{...$...$...} inside it.
  envs = ['align','equation','multline','gather']
  r = {}
  s = {}
  envs.each { |x|
    s[x] = "\\\\(?:begin|end){#{x}\\*?}"
    z = s[x].clone  # workaround for bug in the ruby interpreter, which causes the first 8 bytes of the regex string to be overwritten with garbage
    r[x] = Regexp.new(z)
  }  
  envs.each { |x|
    result = ''
    inside = false # even if it starts with the environment, we get a null string for our first chunk
    tex.split(r[x]).each { |m|
      if !(m=~/\A\s*\Z/) then # not pure whitespace
        if inside then
          n = n+1
          math[n] = m
          math_type[n] = x
          mm = "MATH#{n}\."
          if $no_displayed_math_inside_paras && x!='equation' then
            result = result + $begin_div_not_p + mm + $end_div_not_p
          else
            result = result + mm
          end
        else
          result = result + m
        end
      end
      inside = !inside # needs to be outside the test for whether m is null, because we get a null for first chunk if string begins with envir
    }
    tex = result
  }

  end # unless inline_only

  #--------------------- locate inline math ----------------------------
  # figure out what $ corresponds to what $:
  tex.gsub!(/(?<!\\)\$([^$]*[^$\\])\$/) {n+=1; math[n]=$1; math_type[n]='inline'; "MATH#{n}\."}

  #-------------------------------------------------

  math.each_index { |n|
    debug = false # math[n]=~/\{1\}\{2\}/
    m = handle_math_one(math[n],math_type[n],(allow_bitmap && !($config['forbid_images_inside_text']==1 && math_type[n]=='inline')))
    if m==nil then
      m=math[n].gsub(/</,"&lt;")
    else
      if math_type[n]!='inline' and !( m=~/<div/) then
        # begin_equation() and end_equation() produce <div> tags
        m = begin_equation() + m + end_equation() # already has divs in it if it's not inline and was parsed into bitmaps
      end
    end
    tex.gsub!(/MATH#{n}\./,m)
  }


  #-------------------------------------------------
  # misc.:

  # certain macros force math environment, so sometimes I use them without $$; make sure those don't slip by:
  tex.gsub!(/\\vc{([a-zA-Z])}/) {"<b>#{$1}</b>"}
  tex.gsub!(/\\degunit/) {"&deg;"}
  tex.gsub!(/\\degcunit/) {"&deg;C"}
  tex.gsub!(/\\degfunit/) {"&deg;F"}
  tex.gsub!(/\\munit/,'m')
  tex.gsub!(/\\sunit/,'s')

  if !$mathjax then tex.gsub!(/\&\=/,'=') end # happens for displayed math that we couldn't handle, or didn't try to handle, from align environment

  return tex

end

# translate one particular equation, if possible; otherwise return nil
# foo = tex code for equation
# math_type = 'inline', 'align', or 'equation', or 'multline', or 'gather'
# allow_bitmap = boolean
def handle_math_one(foo,math_type,allow_bitmap)
  tex = foo.clone

  tex.gsub!(/\\textup/,'\\text')

  if tex=='' then  $stderr.print "warning, null string passed to handle_math_one\n"; return '' end

  if $mathjax then
    if math_type=='inline' then
      return '\\('+prep_math_for_mathjax(tex)+'\\)' 
    else
      return "\\[\\begin{#{math_type}*}"+prep_math_for_mathjax(tex)+"\\end{#{math_type}*}\\]"
    end
  end

  tex.gsub!(/\\(begin|end){split}/,'') # we don't handle these (they occur inside other math environments)

  debug = foo=~/\\vc{v} &= \\frac{\\de/
  html = handle_math_one_html(tex.clone,math_type) # may return either plain html or html with mathml, if config says that's allowed

  use_desperate_fallback_if_necessary = !allow_bitmap && $config['standalone']==1

  # $stderr.print "mathml_plus_fallback=#{$config['mathml_plus_fallback']} html.nil?=#{html.nil?} contains_mathml=#{contains_mathml(html)}\n"

  if $config['mathml_plus_fallback']==1 && html!=nil && contains_mathml(html) then
    # The following doesn't really work. Later stages mangle the structure, and calibre mangles it further. Don't use.
    # http://idpf.org/epub/30/spec/epub30-contentdocs.html#sec-xhtml-epub-switch
    # namespace is http://www.idpf.org/2007/ops
    fallback = ''
    if $config['mathml_with_epub3_switch']==0 then fatal_error("mathml_plus_fallback=1, but mathml_with_epub3_switch=0, and I don't have any other fallback mechanism") end
    if use_desperate_fallback_if_necessary then fallback=handle_math_one_desperate_fallback(tex.clone) else fallback=handle_math_one_bitmap(tex.clone,math_type) end
    # http://idpf.org/epub/20/spec/OPS_2.0.1_draft.htm#Section2.6.3.1.1
    # http://www.dessci.com/en/reference/ebooks/EPUBMath_spec.htm
    # http://code.google.com/p/epub-revision/source/browse/trunk/test/xhtml/valid/switch-001.xhtml?r=2949
    # http://www.w3schools.com/xml/xml_namespaces.asp
    # It doesn't matter if you do the xmlns: in a particular element or in a parent element such as the <html> tag.
    # This page implies that epubcheck can handle case/switch: http://code.google.com/p/epubcheck/issues/detail?id=132
    #  ... but when I do it, epubcheck is upset.
    # Doesn't actually work in calibre 0.7.44: http://www.mobileread.com/forums/showthread.php?p=1905534#post1905534
    return (<<-SWITCH
      <epub:switch xmlns:epub="http://www.idpf.org/2007/ops"> 
        <epub:case required-namespace="http://www.w3.org/1998/Math/MathML">
          #{html}
        </epub:case>
        <epub:default>
          #{fallback}
        </epub:default>
      </epub:switch>
    SWITCH
    ).gsub(/\n/,' ')
  else
    # not producing multiple versions using epub switch
    return html if html!=nil
    if use_desperate_fallback_if_necessary then return handle_math_one_desperate_fallback(tex.clone) end
    return nil if !allow_bitmap
    html = handle_math_one_bitmap(tex.clone,math_type)
    return html if html!=nil
    return nil
  end
end

def contains_mathml(html)
  return (html=~/<math/)!=nil
end

def prep_math_for_mathjax(math)
  m = math.clone
  m.gsub!(/\</,'\\lt') # Keep < from being interpreted as html tag by browser.
  m.gsub!(/\\vc{([A-Za-z]+)}/) {"\\mathbf{#{$1}}"}
  m.gsub!(/\\unitdot/) {"\\!\\cdot\\!"}
  m.gsub!(/\\zu{([A-Za-z]+)}/) {"\\text{#{$1}}"}
  m.gsub!(/\\intertext/) {"\\text"}
  $tex_math_not_in_mediawiki.each { |k,v|
    m.gsub!(/\\#{k}/) {v}
  }
  m.gsub!(/\\$/) {"PROTECT_DOUBLE_BACKSLASH_FOR_MATHJAX"}
  return m
end

# translate one particular equation to html or mathml, if possible; return nil on failure
# math_type = 'inline', 'align', or 'equation', or 'multline', or 'gather'
def handle_math_one_html(tex,math_type)
  debug = false

  original = tex.clone
  if original=~/<\/?i>/ then
    $stderr.print "huh? m has <i> in it, getting ready to produce tex code\n#{original}\n"
    return tex
  end

  m = tex.clone
    m.gsub!(/\n/,' ')
    m.gsub!(/\&\=/,'=') # we don't try to handle alignment
    m.gsub!(/\\(quad|qquad)/,' ') # we don't try to handle spacing
    m.gsub!(/\\[ :,]/,' ')
    m.gsub!(/\\(left|right)(?!\w)/,'') # we don't handle these, and \left becomes <=ft; the negative lookahead is so we don't mess up \leftarrow and \rightarrow
    m.gsub!(/_\\text{([A-Za-z])}/) {"_#{$1}"} # handle x_\text{o} as x_o, not worrying about the italicization of the o; prevent _TEXTu0001o, which gives subscripted T
    m.gsub!(/\\text{([A-Za-z]+)}/) {"TEXTu#{sprintf("%04d",$1.length)}#{$1}"} # parsing gets too complex if not A-Za-z, because can't tell what gets italicized
    m.gsub!(/\\mathbf{([A-Za-z]+)}/) {"TEXTb#{sprintf("%04d",$1.length)}#{$1}"}
    y = parse_simple_equation(m)
    if debug then $stderr.print "--------in handle_math_one_html, y=#{y}\n" end
    if y!=nil then
      if debug then $stderr.print "--------in handle_math_one_html, y not nil\n" end
      # italicize variables
      y.gsub!(/((?:[^<>]+)|(?:<\/?\w+>))/) {
        e=$1;
        if !(e=~/</) then e.gsub!(/([a-zA-Z]+)/) {"<i>#{$1}</i>"} end;
        e
      }
      # stuff like \pi gets the p and the i italicized; fix this:
      y.gsub!(/\\<i>([^<]+)<\/i>/) {"\\#{$1}"}
      $stderr.print "3. #{y}\n" if debug
      y = replace_list(y,$tex_symbol_replacement_list)
      if debug then $stderr.print "~~~~~~~~ 1   "+y+"\n" end
      y.gsub!(/<i>([a-zA-Z]+)TEXT/) {"#{$1}<i>TEXT"} # e.g., <i>qTEXTb</i>0001 becomes q<i>TEXTb</i>0001
      if debug then $stderr.print "~~~~~~~~ 2   "+y+"\n" end
      begin # I don't understand why it's necessary to wrap y.gsub! in this loop, but apparently it is
        did_one = false
        y.gsub!(/<i>TEXT(.)<\/i>(\d\d\d\d)<i>(.*)/) { # guaranteed an <i> marker, because only matched if A-Za-z
          did_one = true
          what,len,stuff = $1,$2.to_i,$3
          crud = stuff[0..len-1]
          if what=='b' then crud = "<b>#{crud}</b>" end
          final = crud + "<i>" + stuff[len..(stuff.length-1)] # may cause <i></i>, which gets eliminated by peepholer below
          if debug then $stderr.print "~~~~~~~~ 3   "+final+"\n" end
          final
        }
      end while did_one
      if debug then $stderr.print "~~~~~~~~ 4   "+y+"\n" end
      y.gsub!(/<i><\/i>/,'')
      #$stderr.print "parsed $#{original}$ to $#{m}$, to #{y}\n"
      y.gsub!(/TEXT.\d\d\d\d/) {''} # shouldn't happen, but does in SN10
      y.gsub!(/<i>TEXT.<\/i>\d\d\d\d/) {''} # shouldn't happen, but does in SN10
    end
    # remove leading and trailing whitespace
    if y!=nil then
      y.gsub!(/^\s+/,'')
      y.gsub!(/\s+$/,'')
      y.gsub!(/{}/,'') # some equations in SN have empty {} for tex
      if y=='' then y=nil end
    end
    if y!=nil then return y end

    if $xhtml && $config['forbid_mathml']==0 then
      # If it's something like an align environment, it may have \\ in it, so we need to surround it with a begin/end block, or else blahtex will get upset.
      surround = (math_type!='inline' && math_type!='equation') 
      t = 'temp_mathml'
      if surround then original = "\\begin{#{math_type}}" + original + "\\end{#{math_type}}" end
      original.gsub!(/\\eqquad/,'')
      File.open("#{t}.tex",'w') do |f| f.print original end
      unless system("footex --prepend-file #{$config['sty_dir']}/lmmath.sty --mathml #{t}.tex #{t}.html") then return nil end
      y = nil
      File.open("#{t}.html",'r') { |f|
        y = "<!-- #{original} -->"
        y.gsub!(/\n/,' ')
        y = y + "\n" + '<math xmlns="http://www.w3.org/1998/Math/MathML">'+(f.gets(nil))+'</math>' # nil means read whole file
      }
      y.gsub!(/<mtext>([^<]*)<mtext>([^<]*)<\/mtext>([^<]*)<\/mtext>/) {"<mtext>#{$1}#{$2}#{$3}</mtext>"}
    end

    if $wiki then
      # If it's something like an align environment, it may have \\ in it, so we need to surround it with a begin/end block, or else blahtex will get upset.
      surround = (math_type!='inline' && math_type!='equation') 
      t = 'temp_mathml'
      if surround then original = "\\begin{#{math_type}}" + original + "\\end{#{math_type}}" end # mediawiki's texvc can handle these; see http://en.wikipedia.org/wiki/Help:Displaying_a_formula
      y = "\n" + hide('<math>'+original+'</math>','tex_math_for_mediawiki')
    end

    return y
end

# Translate one particular equation to xhtml, trying to create something half-way legible if all else fails.
# This is meant only for use in math that occurs inline in ebooks that don't support mathml.
def handle_math_one_desperate_fallback(tex)
  debug = false # tex=~/omega/ && tex=~/intertext/
  curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested

  if debug then $stderr.print "=================== in handle_math_one_desperate_fallback, input=#{tex}\n" end

  m = tex.clone

  m.gsub!(/\&\=/,'=') # we don't try to handle alignment
  m.gsub!(/_\\zu{o}/,'_o')
  m.gsub!(/\\(quad|qquad)/,' ') # we don't try to handle spacing
  m.gsub!(/\\[ :,]/,' ')
  m.gsub!(/\\(?:text|zu){([A-Za-z]+)}/) {$1} 
  m.gsub!(/\\(?:vc|mathbf){([A-Za-z]+)}/) {"<b>#{$1}</b>"}
  m.gsub!(/\\ge/,'>=')
  m.gsub!(/\\le/,'&lt;=')
  m.gsub!(/\\frac{([A-Za-z0-9]+)}{([A-Za-z0-9])}/) {"<sup>#{$1}</sup>/<sub>#{$2}</sub>"}
  m.gsub!(/\\frac{([A-Za-z0-9]+)}{([0-9]{2,})}/) {"<sup>#{$1}</sup>/<sub>#{$2}</sub>"}
  m.gsub!(/\\frac{([A-Za-z0-9]+)}{([A-Za-z0-9]{2,})}/) {"<sup>#{$1}</sup>/<sub>(#{$2})</sub>"} # needs parens

  m.gsub!(/\\(?:sqrt){(#{curly})}/) {"&radic;#{$1}"} # If possible, strip of the curly braces.
  m.gsub!(/\\sqrt/) {"&radic;"}                      # ... otherwise, still do something with it.
  m.gsub!(/_([A-Za-z0-9])/) {"<sub>#{$1}</sub>"}
  m.gsub!(/\^([A-Za-z0-9])/) {"<sup>#{$1}</sup>"}
  m.gsub!(/\\xdot/,"\\dot{x}")
  m.gsub!(/\\dot{([A-Za-z])}/) {"#{$1}<sup>&middot;</sup>"}
  m.gsub!(/\\(Ddot|ddot){([A-Za-z])}/) {"#{$2}&uml;"}
  m.gsub!(/\\bar{([A-Za-z])}/) {"#{$1}<sup>-</sup>"}
  m = replace_list(m,$tex_symbol_replacement_list)

  # Make sure nothing gets sent back with a raw < or > in it. But don't mung the <sup> and <sub> tags that I myself generated.
  m.gsub!(/<(?!\/?(sup|sub)>)/,'&lt;')
  # The following gives an error because of a limitation in ruby's regex engine:
  #m.gsub!(/(?<!<\/?(sup|sub))>/,'&gt;') # causes error
  # See http://stackoverflow.com/questions/3479131/problem-with-quantifiers-and-look-behind . (The same regex *does* work in perl 5.10.1, but
  # others fail, e.g., /(?<=\w*)o/.
  # workaround:
  m.gsub!(/(?<!su[pb])>/,'&gt;')

  if debug then $stderr.print "===================in handle_math_one_desperate_fallback, old=#{old}, output=#{m}\n" end

  return m
end



# <b>F</b>=<i>qTEXTb</i>0001<i>v</i>&times;<i>B</i>

# translate one particular equation to a bitmap; return the html code to display the bitmap
# if the type isn't inline, then we put div's around the equation(s)
def handle_math_one_bitmap(tex,math_type)
    if $blind then return '' end
    m = tex.clone
    scale = $config['scale_for_bitmapped_equations']

    if m=~/\\(begin|end){array}/ then return nil end # can't handle these because they contain \\ inside

    curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested
    m.gsub!(/\\indices{(#{curly})}/) {$1} # has to strip curly braces off, not just delete the macro
    # if you really try to do an align environment, it wants to make separate bitmaps for each column
    t = {'inline'=>'equation*', 'equation'=>'equation*' , 'align'=>'equation*', 'multline'=>'multline*' , 'gather'=>'gather*'}[math_type]    
    if (math_type=='equation' || math_type=='inline') && tex=~/\\\\/ && !(tex=~/\\begin{matrix}/) then
      $stderr.print "double backslash not allowed in equation environment: #{tex}\n...This may not be a LaTeX error if it has intertext, but may cause parser to generate invalid xhtml.\n"
    end
    # stuff that's illegal in equation environment:
    m.gsub!(/\&/,'')
    m.gsub!(/\\intertext{([^}]+)}/) {" \\text{#{$1}} "} 
    result = ''
    m.split(/\\\\/).each { |e|
      original = e.clone
      e.gsub!(/\n/,' ') # empty lines upset tex
      if (e=~/\A\s*\Z/) then
        $stderr.print "double backslash not allowed after final line in displayed math: #{tex}\n...This may not be a LaTeX error if it has intertext, but may cause parser to generate invalid xhtml.\n"
      else
      eq_dir = html_subdir('math')
      eq_base = 'eq_' + hash_equation(e,scale) + '.png'
      eq_file = eq_dir + '/' + eq_base
      if $redo_all_equations || ! File.exist?(eq_file) then
        temp = 'temp.tex'
        temp_png = 'temp.png'
        if e=~/<\/?i>/ then
          $stderr.print "huh? equation has <i> in it, getting ready to produce tex code\n#{original}\n"
        end
        unless $no_write then $stderr.print "Producing equation file #{eq_file} from latex code #{e}\n" end
        File.open(temp,'w') do |f|
        f.print <<-TEX
  	\\documentclass{book}[12pt]
	\\RequirePackage{lmmath,amssymb,cancel}
        \\RequirePackage[leqno]{amsmath}
        \\begin{document}
        \\begin{#{t}}
        #{e}
	\\end{#{t}}
        \\end{document}               
        TEX
        end # file
        doomed = ( e=~/{212/ )
        if doomed then
          $stderr.print "****************************This equation is marked as not working -- not doing it ***********************************\n"
        else
          if ! $no_write then
            if !File.exist?(temp) then $stderr.print "error, temp file #{temp} doesn't exist"; exit(-1) end
            unless system("#{$config['script_dir']}/equation_to_image.pl #{temp} #{$config['sty_dir']}/lmmath.sty #{scale}>/dev/null") then $stderr.print "error, #{$?}"; exit(-1) end
            unless system("mv #{temp_png} #{eq_file}") then $stderr.print "WARNING, error #{$?}, probably tex4ht isn't installed\n" end
          end
        end
      end # end if file doesn't exist yet
      end # if not null string
      plain_equation = original
      plain_equation.gsub!(/[\n"]/,'')
      plain_equation.gsub!(/</,'&lt;')
      plain_equation.gsub!(/\\/,'') # If we don't do this, then the latex math inside the alt="" gets translated to html later, and it's not valid html
      curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested
      plain_equation.gsub!(/\\label{#{curly}}/,'')
      # $stderr.print ".......................... #{plain_equation} ............................\n"
      if math_type=='inline' then
        result = result + "<img src=\"math/#{eq_base}\" alt=\"#{plain_equation}\"#{$self_closing_tag}>"
      else
        result = result + "#{begin_equation()}<img src=\"math/#{eq_base}\" alt=\"#{plain_equation}\"#{$self_closing_tag}>#{end_equation()}"
      end
    }
    return result
end

def begin_equation
  return '<div class="equation">'
end

def end_equation
  return '</div>'
end


def hash_equation(foo,scale)
  tex = foo.clone
  # strip any leading or trailing dollar signs or spaces:
  tex.gsub!(/^[$ ]+/,'')
  tex.gsub!(/[$ ]+$/,'')
  return hash_function(hash_function(tex)+scale.to_s)
end

def hash_function(x)
  h = Digest::MD5.new
  h << x
  return h.to_s[-8..-1] # to_s method gives the result in hex
end

# Take care of the math and tables, as well as other misc. junk, in an individual paragraph.
# Be careful not to return nested div's, because the code in parse_section can't handle that.
# Guaranteed not to make any <p> or <div> tags, and therefore safe to use for stuff like figure captions,
# provided the argument doesn't have any displayed math or tables inside it.
def parse_para(t)
  tex = t.clone

  # Do tables before handling math, because otherwise, e.g., \alpha becomes &alpha;, which looks like & in table.
  # When latex_table_to_html converts the table, it will convert the math inside it as well.
  # However, it may generate bitmaps for complex math, which I don't want it to do inside a table (script can't handle it).
  # Therefore, if a table comes back from tex4ht with bitmaps in it, handle_tables replaces each bitmap with its alt value.
  tex = handle_tables(tex)
  tex = handle_math(tex)
  tex = parse_eensy_weensy(tex) # has to be done after handling math (see, e.g., comment about ldots, but other reasons, too, I think)
  return tex
end

# Parse very simple low-level stuff. It's safe to call this routine for stuff like figure captions. Guaranteed not to make
# any <p> or <div> tags.
def parse_eensy_weensy(t)
  tex = t.clone

  curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested
  curly_safe = "(?:[^{}]*)" # can't contain any curlies

  # macros we don't care about:
  tex.gsub!(/\\index{#{curly}}/,'') # This actually gets taken care of earlier by duplicated code. Probably not necessary to have it here as well.
  tex.gsub!(/\\noindent/,'') # Should pay attention to this, but it would be really hard.
  tex.gsub!(/\\write18{#{curly}}/,'')
  tex.gsub!(/\\anchor{#{curly}}/,'')
  tex.gsub!(/\\link{#{curly}}/,'')
  # kludge, needed in SN 10:
  tex.gsub!(/\\formatlikecaption{/,'') 
  tex.gsub!(/\\normalsize/,'') 
  tex.gsub!(/\\normalfont/,'') 

  # macros that we treat as identity operators:
  tex.gsub!(/\\(?:indices){(#{curly})}/) {$1}

  # macros that are easy to process:
  tex.gsub!(/\\(?:emph|optionalchapternote){(#{curly})}/) {"<i>#{$1}</i>"}
  tex.gsub!(/\\(?:givecredit){(#{curly})}/) {" [#{$1}] "}
  tex.gsub!(/\\epigraph(?:long|longfitbyline)?{(#{curly})}{(#{curly})}/) {"#{$1} -- <i>#{$2}</i>"}
  tex.gsub!(/\\\//,' ')
  tex.gsub!(/\\\\/,$br)
  tex.gsub!(/PROTECT_DOUBLE_BACKSLASH_FOR_MATHJAX/,"\\\\")
  tex.gsub!(/\\xmark/,'&times;')
  tex.gsub!(/\\hwsoln/,'(solution in the pdf version of the book)')
  tex.gsub!(/\\hwendpart/,$br)
  tex.gsub!(/\\answercheck/,'(answer check available at lightandmatter.com)')
  tex.gsub!(/\\ldots/,'...') # won't mess up math, because this is called after we handle math
  if $mathjax then tex.gsub!(/\\(egquestion|eganswer)/,'\\(\\triangleright\\)') else tex.gsub!(/\\(egquestion|eganswer)/,'&loz;') end
  tex.gsub!(/\\notationitem{(#{curly_safe})}{(#{curly_safe})}/) {"#{$1} &mdash; #{$2}"} # endless loop in NP7 if I don't use curly_safe?? why??
  tex.gsub!(/\\vocabitem{(#{curly})}{(#{curly})}/) {"<i>#{$1}</i> &mdash; #{$2}"}
  tex.gsub!(/\\label{([^}]+)}/) {
    x=$1
    unless x=~/^splits:/ then # kludge to avoid malformed xhtml resulting from \label in a paragraph by itself
      if $config['forbid_anchors_and_links']==0 then "<a #{$anchor}=\"#{x}\"></a>" else '' end
    end
  }

  tex.gsub!(/\\url{(#{curly})}/) {$config['forbid_anchors_and_links']==0 ? "<a href=\"#{$1}\">#{$1}</a>" : $1}

  # footnotes:
  tex.gsub!(/\\footnote{(#{curly})}/) {
    text=$1
    $footnote_ctr += 1
    n = $footnote_ctr
    label = "footnote" + n.to_s
    $footnote_stack.push([n,label,parse_para(text)])
    fn = "<sup>#{n}</sup>"
    $config['forbid_anchors_and_links']==0 ? "<a href=\"\##{label}\">#{fn}</a>" : fn
  }

  parse_references!(tex)

  # quotes:
  tex.gsub!(/\`\`/,'&ldquo;')
  tex.gsub!(/\'\'/,'&rdquo;')

  parse_itty_bitty_stuff!(tex)

  return tex
end

# Guaranteed not to make any <p> or <div> tags.
# Normally called by parse_eensy_weensy(), not called directly.
def parse_references!(tex)
  curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested

  tex.gsub!(/\\subfigref{([^}]+)}{([^}]+)}/) {"\\ref{fig:#{$1}}/#{$2}"}
  tex.gsub!(/\\figref{([^}]+)}/) {"\\ref{fig:#{$1}}"}
  tex.gsub!(/\\ref{([^}]+)}/)     { # example: <a href="#sec:basicrel">7.1</a>
    this_ch=$ch.to_i # strip any leading zero, and make it an integer
    x=$1 # the TeX label, e.g., "sec:basicrel"
    r=$ref[x]
    if r!=nil then
      number=r[0] # e.g., 7.1 (section) or c (figure)
      # Bug: the following doesn't correctly handle references across chapters to a figure, only to a section, subsection, etc.
      url = "\##{x}"
      if x=~/(ch|sec):/ then # ch:, sec:, subsec:, ...
        if number =~ /\A(\d+)/ then
          that_ch = $1.to_i
        else
          that_ch = this_ch
        end
        if this_ch!=that_ch then # reference acrosss chapters
          # $stderr.print "reference #{x}, #{r}, #{number}\n"
          # $stderr.print "that_ch=#{that_ch}, this_ch=#{this_ch}\n"
          t = that_ch.to_s
          if that_ch<10 then t = '0'+t end
          url = "../ch#{t}/ch#{t}.html" + url
        end
      end
      y=($config['forbid_anchors_and_links']==0 ? "<a href=\"#{url}\">#{number}</a>" : number)
    else
      $stderr.print "warning, undefined reference #{x}\n"
      y=''
    end
    y 
  }
  tex.gsub!(/\\worked{([^}]+)}{(#{curly})}/)     {
    ref,title='hw:'+$1,$2
    r=$ref[ref]
    if r!=nil then
      #y="&loz; Solved problem: #{title} &mdash; <a href=\"\##{ref}\">page #{r[1]}, problem #{r[0]}</a>" ### hw refs aren't actually there
      y="&loz; Solved problem: #{title} &mdash; problem #{r[0]}"
    else
      $stderr.print "warning, undefined reference #{r}\n"
      y=''
    end
    y 
  }
  tex.gsub!(/\\pageref{([^}]+)}/) {
    x=$1
    r=$ref[x]
    if r!=nil then
      y=r[1].to_s
    else
      $stderr.print "warning, undefined reference #{x}\n"
      y=''
    end
    y 
  }
end

$read_topic_map = false
$topic_map = {}
def find_topic(ch,book,own)
  if book=='calc' || book=='genrel'  || book=='sr' || book=='fund' then return own end

  # Topic maps are also used in scripts/BookData.pm.
  if !$read_topic_map then
    $topic_map = get_serialized_data_from_file($topic_map_file)
    $read_topic_map = true
  end

  ch_string = ch.to_i.to_s # e.g., convert '07' to '7'

  t1 = $topic_map['1']
  x = t1[book]
  if x==nil then return own end
  own.push("../share/#{x[ch_string]}/figs")

  # secondary places to look:
  t2 = $topic_map['2']
  x = t2[book]
  if x!=nil and x[ch_string]!=nil then own.push("../share/#{x[ch_string]}/figs") end

  t3 = $topic_map['3']
  x = t3[book]
  if x!=nil and x[ch_string]!=nil then own.push("../share/#{x[ch_string]}/figs") end

  return own
end


def die(name,message)
  $stderr.print "eruby_util: figure #{name}, #{message}\n"
  exit(-1)
end

# returns, e.g., 'n3/figs' or 'ch09/figs'
def own_figs
  if ENV['OWN_FIGS'].nil? then
    return "ch#{$ch}/figs"
  else
    return ENV['OWN_FIGS']
  end
end

# Example:
#   if called with name='tied-rocks-1', returns 'tied-rocks-1.png'
#   if the screen-resolution bitmap 'tied-rocks-1.png' doesn't exist yet, has the side-effect of creating it in $config['html_dir'].
# This most commonly gets called by parse(), but also gets called by parse_itty_bitty_stuff() for \anonymousinlinefig and \fullpagewidthfignocaption.
def find_figure(name,width_type)
  # width_type = 'narrow' , 'wide' , 'fullpage' , 'raw'

  # Allow for kludges like fig('../../../lm/vw/figs/doppler',...), which I do in an E&M chapter of LM.
  # But don't do stuff like ../../../share/mechanics/fig/tractor, which shows up in chapter openers.
  if name=~/^\.\./ && !(name=~/\.\.\/share/) then
    return name
  end

  name.gsub!(/(.*\/)/,'') # get rid of anything before the last slash; if it's shared, we'll figure that out ourselves

  if name=='zzzfake' then return nil end

  output_dir = "#{$config['html_dir']}/ch#{$ch}/figs"
  make_directory_if_nonexistent(output_dir,'find_figure')

  search = Dir["#{output_dir}/#{name}.*"]
  unless search.empty? then
    unique = search.shift # better be unique
    unique =~ /([^\/]+)$/
    return $1
  end
  
  debug = false # debug mechanism for finding where the figure is

  possible_dirs = find_topic($ch,$config['book'],[own_figs()])
  allowed_formats = ['jpg','png','pdf'] # input formats
  found_in_dir = nil
  found_in_fmt = nil
  allowed_formats.each {|fmt|
    possible_dirs.each {|dir|
      if Dir["#{dir}/#{name}\.#{fmt}"].empty? then
        if debug then $stderr.print "debugging: didn't find #{name}.#{fmt} in #{dir}\n" end
      else
        if debug then $stderr.print "debugging: found #{name} in #{dir}\n" end
        if found_in_dir.nil? then # prefer the earliest in the list
          found_in_dir = dir
          found_in_fmt = fmt
        end
      end
    }
  }
  fmt = found_in_fmt
  dir = found_in_dir

  base = "#{dir}/#{name}."
  if dir==nil then
    $stderr.print "translate_to_html: error finding figure #{base}*, not found in any of these dirs: ",possible_dirs.join(','),", relative to cwd=#{Dir.getwd()}; one way to fix this might be to edit topic_map.json\n"
    exit(-1)
  else
    result = "#{dir}/#{name}.#{fmt}"
  end
  return '' if result==nil

  output_format = {'jpg'=>'jpg','png'=>'png','pdf'=>'png'}[fmt]
  if $config['allow_png']==0 && output_format=='png' then output_format='jpg' end
  if output_format==nil then $stderr.print "error in translate_to_html.rb, find_figure, output_format is nil, name=#{name}\n"; exit(-1) end
  if name==nil then $stderr.print "error in translate_to_html.rb, find_figure, name is nil\n"; exit(-1) end
  if $config['html_dir']==nil then $stderr.print "error in translate_to_html.rb, find_figure, $config['html_dir'] is nil\n"; exit(-1) end
  dest = $config['html_dir'] + '/' + "ch#{$ch}/figs/" + name + '.' + output_format
  unless File.exist?(dest) || $blind then
    # need to call ImageMagick even if input and output formats are the same, to convert to web resolution
    infile = base+fmt
    did_it = false
    if fmt=='jpg' or fmt=='png' then
      rescale_image(width_type,infile,dest)
      did_it = true
    end
    if fmt=='pdf' then
      # Can convert pdf directly to bitmap of the desired resolution using imagemagick, but it messes up on some files (e.g., huygens-1.pdf), so
      # go through pdftoppm first.
      pdftoppm_command = "pdftoppm -r 440 #{infile} z" # 4x the resolution we actually want
      do_system(pdftoppm_command) 
      ppm_file = 'z-000001.ppm' # only 1 page in pdf
      unless File.exist?(ppm_file) then ppm_file = 'z-1.ppm' end # different versions of pdftoppm use different naming conventions
      if File.exist?(ppm_file) then
        rescale_image(width_type,ppm_file,dest)
        FileUtils.rm(ppm_file)
        did_it = true
      else
        fatal_error(
          <<-DEATH
            Error converting figure #{dest}, no file z-000001.ppm or z-1.ppm created as output by pdftoppm; perhaps pdftoppm isn't installed?
            Command line was #{pdftoppm_command}
          DEATH
        )
      end
    end # if pdf
    fatal_error("error in translate_to_html.rb, find_figure(), converting from illegal format #{fmt} to #{output_format}") unless did_it
  end
  return name+'.'+output_format
end

def rescale_image(width_type,infile,dest)
  options = find_rescaling_info_for_image(width_type,infile,dest)
  do_system("convert #{options} #{infile} #{dest}")
end

def find_rescaling_info_for_image(width_type,infile,name_of_dest_file_for_error_reporting)
  (width,height) = get_image_file_dimensions(infile)
  target_width = -1
  if width_type=='raw' then target_width = width end
  if width_type=='narrow' then target_width = ($margin_width_mm/25.4)*72 end
  if width_type=='wide' or width_type=='fullpage' then target_width = $text_width_pixels end
  if target_width == -1 then
    target_width = 100
    $stderr.print "Warning, unrecognized width type #{width_type} for figure #{name_of_dest_file_for_error_reporting}\n"
  end
  if $config['max_fig_width_pixels']>0 && target_width>$config['max_fig_width_pixels'] then target_width=$config['max_fig_width_pixels'] end
  scale = target_width/width
  width = (width*scale).to_i
  height = (height*scale).to_i
  return " -resize #{width}x#{height}" # for ImageMagick's convert
end

def get_image_file_dimensions(infile) # returns [width,height] in floating-point format
  # Use ImageMagick's identify script to determine the dimensions of the image:
  `identify #{infile}`.split(/ /)[2]=~/(\d+)x(\d+)/ or fatal_error("error in translate_to_html, get_image_file_dimensions(), ImageMagick's identify utility failed on file #{infile}")
  return [$1.to_f,$2.to_f]
end

def do_system(cmd)
  $stderr.print "#{cmd}\n"
  system(cmd)
end

def alphalph(x)
  if x>26 then return alphalph(((x-1)/26).to_i) + alphalph((x-1)%26+1) end
  # kludge: in the following, 97 is the harcoded ascii code for 'a'
  return (97+x-1).chr
end

# returns an array consisting of text column and margin column blocks, [[t1,m1],[t2,m2],...]
# m1, m2, ... will be null strings if the book has no marg() figures (as with Calculus), or if all_figs_inline is set
def parse(t,level,current_section,environment_data)
  tex = t.clone

  tex.gsub!(/\\der ([A-Za-z])/) {"d#{$1}"} # otherwise we get "d x"

  # The following is so that text right before or right after an enumerate or itemize will be in its own paragraph:
  tex.gsub!(/(\\end{(enumerate|itemize)})/) {$1+"\n"}
  tex.gsub!(/(\\begin{(enumerate|itemize)})/) {"\n"+$1}
  if level<=$config['restart_figs_at_level']+1 then $fig_ctr = 0 end
  #------------------------------------------------------------------------------------------------------------------------------------
  if level>$config['highest_section_level'] then return [ [parse_section(tex,environment_data),''] ] end
  #------------------------------------------------------------------------------------------------------------------------------------
  marg_stuff = ''
  end_of_caption_marker = "<!-- ZZZ_END_OF_CAPTION -->"
  if level==$config['spew_figs_at_level'] then
    non_marg_stuff = ''
    tex.gsub!(/END_CAPTION\n*/,"END_CAPTION\n") # the newline is because without it, the code below will eat too much with each regex match
    # The following code assumes that each ZZZWEB thingie is on a separate line; if there aren't newlines between them, it eats too much and goes nuts.
    in_marg = false # even if it starts with a marg, split() gives us a null string for the first chunk()
    tex.split(/ZZZWEB\:(?:end\_)?marg/).each { |x|
      inline = !in_marg || all_figs_inline
      x.gsub!(/ZZZWEB\:fig,([^,]+),(\w+),(\d),([^\n]*)END_CAPTION/) {
        name,width,anon,caption = $1,$2,$3.to_i,$4
        #if name=='zzzfake' then $stderr.print "zzzfake------------\n#{name}\n#{width}\n#{anon}\n#{caption}-------\n" end
        if anon==0 then $fig_ctr += 1 ; l=alphalph($fig_ctr).to_s+' / ' else l='' end
        if name=='zzzfake' then $fig_ctr += 1 end # kludge, I don't understand why this is needed, but it is, or else EM1 figures get out of step at the end
        whazzat = find_figure(name,width) # has the side-effect of copying or converting it if necessary
        if caption=~/\A\s*\Z/ then c='' else 
          pc=parse_para(caption)
          if pc=~/<math/ then pc=hide(pc,'mathml_in_captions') end
          c="<p class=\"caption\">#{l}#{pc}</p>#{end_of_caption_marker}"  
        end
        a = ($config['forbid_anchors_and_links']==0 ? "<a #{$anchor}=\"fig:#{name}\"></a>" : '')
        i = "<img src=\"figs/#{whazzat}\" alt=\"#{name}\"#{$self_closing_tag}>#{a}"
        if name=='zzzfake' then i='' end
        y="<!--BEGIN_IMG--><p class=\"noindent\">"+i+"</p>"+c+"<!--END_IMG-->"
        "\n\n#{hide(y,'fig')}\n\n"
      }
      if inline then
        non_marg_stuff = non_marg_stuff + x
      else
        marg_stuff = marg_stuff + x
      end
      in_marg = !in_marg
    }
    tex = non_marg_stuff
    parse_marg_stuff!(marg_stuff)
    #if marg_stuff=~/261/ then $stderr.print "back from parse_marg_stuff!, **#{marg_stuff}**\n" end
  end
  #------------------------------------------------------------------------------------------------------------------------------------
  highest = $section_level_num.invert[level]
  result = []
  secnum = 0
  first_one = true # first one is a preamble or whatever; even if it starts with section, split() gives a null string for the first chunk
  tex.split(/\\(?:my)?#{highest}/).each { |section|
    if !first_one then
      curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested
      section.gsub!(/\A(?:\[\d*\])?{(#{curly})}/) {
        title = $1
        label = current_section.join('.') + '.' + secnum.to_s
        s=label
        if level==1 and $chapter_title==nil then $chapter_title=title; s=$ch.to_i.to_s end
        if level>=$config['number_sections_at_depth'] then s='' end
        special = ''
        if title=~/^([\*\@\?]+)(.*)/ then special,title=$1,$2 end
        if special=~/\*/ then s='' end # * is a marker to say not to produce a section number
        if special=~/\@/ then title=title + ' (optional calculus-based section)' end
        if special=~/\?/ then title=title + ' (optional)' end
        if level==1 then  label=s ; s="Chapter #{s}." end # so people hitting the page realize it's one chapter of a book
        sec_type = ''
        if level==1 then sec_type="Chapter" end
        if level==2 then sec_type="Section" end
        if level==3 then sec_type="Subsection" end
        if level==4 then sec_type="Subsubsection" end
        ll = "#{sec_type}#{label}"
        parse_itty_bitty_stuff!(title)
        if level==2 and !(title=~/^Homework/) then 
          t = "#{sec_type} #{label} - #{title}"
          $chapter_toc = $chapter_toc + ($config['forbid_anchors_and_links']==0 ? "<a href=\"\##{ll}\">#{t}</a>#{$br}\n" : "#{t}\n")
        end
        if $wiki then
          h_start = wiki_style_section(level)
          h_end   = wiki_style_section(level)
          s_name = ''
          s_num = ''
        else
          h_start = "<h#{level}>"
          #if level==2 then h_start="___AD___"+h_start end # wrong place in html, is after <div class="margin">
          h_end   = "</h#{level}>"
          s_name = ($config['forbid_anchors_and_links']==0 ? "<a #{$anchor}=\"#{ll}\"></a>" : '')
          s_num = s + ' '
        end
        "#{h_start}#{s_name}#{s_num}#{title}#{h_end}\n"
      }
    end
    first_one = false
    if level==1 then secnum=$ch.to_i end
    current_section.push(secnum)
    section.gsub!(/\\marg{(#{curly})}/) {"<p>#{$1}</p>"} # occurs in EM 5, opener


    # kludgy fix for bug that causes paragraphs not to have <p></p> after caption:
    if true then
      #if section=~/and its derivative cos/ then $stderr.print "\n********\n#{section}\n********\n"; exit(-1) end
      section.gsub!(/#{end_of_caption_marker}(\n?(<p|\\begin))/) {$1} # When multiple figures are in a row, don't do this more than once, producing illegal nested p tags. Ditto
                                                                  # for a figure immediately followed by an example, etc.
      section.gsub!(/#{end_of_caption_marker}\n?(([^\n]+(?<!-->)\n)+)/) {"<!-- ZZZ_TWO_NEWLINES --><p>#{$1}</p>\n\n"} # \n\n is cosmetic; if I put it in now, it gets munged later
      section.gsub!(/#{end_of_caption_marker}/) {""} # Clean up ones that fell at end of section.
    end

    section.gsub!(/\n*(\\begin{(important|lessimportant)})/) {"\n\n#{$1}"}
    section.gsub!(/(\\end{(important|lessimportant)})\n*/) {"#{$1}\n\n"}

    if !(section=~/\A\s*\Z/) then
      result.concat(parse(section,level+1,current_section,environment_data))
    end
    current_section.pop
    secnum += 1
  }
  result.each { |s| 0.upto(1) { |i| $hide['mathml_in_captions'].each { |k,v| unless s[i].nil? then s[i].gsub!(/#{k}/,v) end  } } } # this gets checked for again at end
  #------------------------------------------------------------------------------------------------------------------------------------
  curly = "(?:(?:{[^{}]*}|[^{}]*)*)" # match anything, as long as any curly braces in it are paired properly, and not nested
  if level==$config['spew_figs_at_level'] then
    tex = ''
    result.each { |s|
      tex = tex + s[0] # guaranteed to have null for s[1] for level==$config['spew_figs_at_level']
    }
    return [ [tex,marg_stuff] ]
  else
    return result
  end
  #------------------------------------------------------------------------------------------------------------------------------------
end

def newlines_to_spaces(s)
  x = s.clone
  x.gsub!(/\n/,' ')
  return x
end

#------------------------------------------------------------------------------------------------------------------------------------
#      print_head()
#------------------------------------------------------------------------------------------------------------------------------------
def print_head()
if $modern && !$html5 && !$wiki then
  if $config['forbid_mathml']==1 then
    doctype = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
  else
    doctype = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" "http://www.w3.org/Math/DTD/mathml2/xhtml-math11-f.dtd" >'
  end
  print <<STUFF
<?xml version="1.0" encoding="utf-8" ?>
#{doctype}
<html xmlns="http://www.w3.org/1999/xhtml">
STUFF
  mime = 'application/xhtml+xml'
end

if $html5 then
  print <<STUFF
<!DOCTYPE html>
<html>
STUFF
  mime = 'text/html'
end

if !$modern && !$wiki then
print <<STUFF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
STUFF
  mime = 'text/html'
end

banner_css =  <<STUFF
    <link rel="stylesheet" type="text/css" href="http://www.lightandmatter.com/banner.css" media="all"#{$self_closing_tag}>
STUFF

if $test_mode then
  stylesheet = 'file:///home/bcrowell/Lightandmatter/lm.css'
else
  if $config['standalone']==0 then
    stylesheet = 'http://www.lightandmatter.com/lm.css'
  else
    stylesheet = '../standalone.css'
    banner_css = ''
  end
end

mathjax_in_head = ''
if $mathjax then
  mathjax_in_head = '<script type="text/javascript" src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"></script>'
end

if $config['mime_type']=~/\w/ then mime=$config['mime_type'] end

if !$wiki then
print <<STUFF
  <head>
    <title>#{$chapter_title}</title>
    #{banner_css}
    <link rel="stylesheet" type="text/css" href="#{stylesheet}" media="all"#{$self_closing_tag}>
    <meta http-equiv="Content-Type" content="#{mime}; charset=utf-8"#{$self_closing_tag}>
    #{mathjax_in_head}
  </head>
  <body>
STUFF

# duplicated in run_eruby.pl, ****************** but with a different number of ../'s before banner.jpg ******************************
if $config['standalone']==0 then
print <<BANNER
  <div class="banner">
    <div class="banner_contents">
        <div class="banner_logo" id="logo_div"><img src="http://www.lightandmatter.com/logo.png" alt="Light and Matter logo" id="logo_img"#{$self_closing_tag}></div>
        <div class="banner_text">
          <ul>
            <li> <a href="../../../">home</a> </li>
            <li> <a href="../../../books.html">books</a> </li>
            <li> <a href="../../../software.html">software</a> </li>
            <li> <a href="../../../courses.html">courses</a> </li>
            <li> <a href="../../../area4author.html">contact</a> </li>

          </ul>
        </div>
    </div>
  </div>
BANNER
end

if $config['standalone']==0 then
print "<table style=\"width:#{$ad_width_pixels}px;\"><tr><td>" + boilerplate('disclaimer_html',$format) + "</td></tr></table>\n"
  # ... people are probably more likely to read ad if it looks same width as this block of text, looks like part of page
end

end # if not wiki

if $wiki then
  print <<HEAD
{{Chapter_header|book_title=#{$config['title']}|ch=#{$ch.to_i}|title=#{$chapter_title}}}
HEAD
end # if wiki

# print generate_ad_if_appropriate # ... google only allows 3 per page, so don't waste one here

if $want_chapter_toc then print $chapter_toc + "</div>" end
end

#------------------------------------------------------------------------------------------------------------------------------------
def warn_about_macros_not_handled(tex)
macros_not_handled = {}
# Look for macros that weren't handled.
# We do get raw tex in alt tags and html comments, and that's ok.
chipmunk = tex.clone
chipmunk.gsub!(/alt=\"[^"]*\"/,'')
chipmunk.gsub!(/\<\!\-\-([^\-]|(\-(?!\-)))*\-\-\>/,'') # not really generally correct, but works for the comments I generate that might have html inside
math_macros = $tex_math_trivial.clone
math_macros = math_macros.concat($tex_math_nontrivial.keys)
math_macros = math_macros.concat($tex_math_trivial_not_entities)
math_macros = math_macros.concat(['text','frac','shoveright','sqrt','left','right','mathbf','ensuremath','hat','mathbf','mathrm','triangleright'])
chipmunk.scan(/(\\\w+({[^}]*})?)/) {
  whole = $1 # e.g.,  \frac{ke^2}
  macro = whole
  if whole=~/^\\([a-zA-Z]+)/ then macro=$1 end
  math_ok = false
  if $mathjax then
    math_macros.each { |m| if m==macro then math_ok=true end }
    if macro=='begin' || macro=='end' then
      ['align','equation','multline','gather'].each { |e| if whole=~/^\\(begin|end){#{e}\*?}/ then math_ok=true end}
    end
  end
  whole.gsub!(/\n.*/,'') # if it inadvertently eats thousands of lines and thinks it's one macro, don't print it all
  if !math_ok then macros_not_handled[whole]=1 end
}
unless macros_not_handled.keys.empty? then 
  File.open("macros_not_handled",'a') { |f|
    f.print "Warning: the following macros were not handled in chapter #{$ch}: "+macros_not_handled.keys.join(' ')+"\n" 
  }
  $stderr.print "Warning: some macros were not handled. See list in the file macros_not_handled.\n"
end
end
#------------------------------------------------------------------------------------------------------------------------------------
def print_footnotes_and_append_to_index(tex)
if $footnote_ctr>0 then
  print <<-FOOTNOTES
    <h5>Footnotes</h5>
  FOOTNOTES
  $footnote_stack.each {|f|
    n = f[0]
    label = f[1]
    text = f[2]
    a = ($config['forbid_anchors_and_links']==0 ? "<a #{$anchor}=\"#{label}\"></a>" : '')
    print "<div>#{a}[#{n}] #{text}</div>\n"
  }
end

if !$wiki then print "</body></html>\n" end

#---------
#   Note:
#     The index is always html, even if we're generating xhtml.
#     Also, translate_to_html.rb generates links to chapter files named .html, not .xhtml,
#     even when we're generating xhtml output. This is because mod_rewrite is intended to
#     redirect users to the .xhtml only if they can handle it.
#   In the following, we don't write the index.html file if we're doing wiki output, for two
#   reasons: (1) it's not necessary, and (2) there's a bug that causes the TOC to get output multiple
#   times if we're doing wiki output.
#---------
  if ! $wiki && ! $no_write then
    File.open("#{$config['html_dir']}/index.html",'a') { |f|
      ext = ".html" # ------->!!!! Link to .html, even if we're generating a file that will be called .xhtml. Mod_rewrite will redirect them if it's appropriate.
      if $config['standalone']==1 && $config['html_file_extension']=~/\w/ then ext=$config['html_file_extension'] end
      f.print "<p><a href=\"ch#{$ch}/ch#{$ch}#{ext}\">#{$ch.to_i.to_s + '.'} #{$chapter_title}</a></p>\n"
    }
  end
end
#------------------------------------------------------------------------------------------------------------------------------------
def get_refs()
# Code similar to this is duplicated in eruby_util.rb.
refs_file = 'save.ref'
unless File.exist?(refs_file) then
  $stderr.print "File #{refs_file} doesn't exist. Do a 'make book' to create it."
  exit(-1)
end
File.open(refs_file,'r') do |f|
  # lines look like this:
  #    fig:entropygraphb,h,255
  t = f.gets(nil) # nil means read whole file
  t.scan(/(.*),(.*),(.*)/) { |label,number,page|
    $ref[label] = [number,page.to_i]
  }
end
end
#===============================================================================================================================
#===============================================================================================================================
#===============================================================================================================================
#                                                main
#===============================================================================================================================
#===============================================================================================================================
#===============================================================================================================================

$ch = ENV['CHAPTER']

if $test_mode then  $stderr.print "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< test mode >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n" end

get_refs()

tex = $stdin.gets(nil) # nil means read whole file

# FIXME -- filename hardcoded, kludge...
sty = "lmmath.sty"
if !File.exist?(sty) then sty="../lmmath.sty" end

tex = preprocess(tex,get_command_data(),[sty])
tex = process(tex,get_environment_data()) # has the side-effect of creating $chapter_toc
tex = postprocess(tex)

print_head() # uses $chapter_toc
print tex
print boilerplate('copyright_footer_html',$format)
print_footnotes_and_append_to_index(tex) # has the side-effect of writing to index.html

warn_about_macros_not_handled(tex)
