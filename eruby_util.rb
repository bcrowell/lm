# (c) 2006-2013 Benjamin Crowell, GPL licensed
# 
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
#
#         Always edit the version of this file in /home/bcrowell/Documents/programming/eruby_util_for_books/eruby_util.rb --
#         it will automatically get copied over into the various projects the next time I do a "make" or a
#         "make preflight".
#
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# This script is used in everything except for Brief Calculus, which has a different layout.

# See INTERNALS for documentation on all the files: geom.pos, marg.pos, chNN.pos,
# figfeedbackNN, all.pos.

require 'tempfile'
require 'json'

$label_counter = 0 # for generating labels when the user doesn't supply one
$n_code_listing = 0
$hw_number = 0
$hw_number_in_block = 0
$store_hw_label = []
$hw_block = 0 # for style used in Fundamentals of Calculus
$hw = []
$hw_has_solution = []
$hw_trailing = []
$hw_names_referred_to = []
$hw_freeze = 0
$tex_points_to_mm = (25.4)/(65536.*72.27)
$n_marg = 0
$in_marg = false
$geom_file = "geom.pos"
$checked_geom = false
$geom_exists = nil
$geom = [ 11.40 ,  63.40 ,  154.40 , 206.40 , 28.00 , 258.00]
  # See geom() for the definitions of these numbers.
  # These are just meant to be sane defaults to use if the geom.pos file hasn't been created yet.
  # If they turn out to be wrong, or not even sane, that doesn't matter, because we'll be getting
  # the right values on the next iteration. Actually it makes very little difference, because on the
  # first iteration, we don't even know whether a particular figure is on a left page or a right page,
  # so we don't even try to position it very well.
$checked_pos = false
$pos_exists = nil
$marg_file = "marg.pos"
$feedback = []
  # ... an array of hashes
$read_feedback = false
$feedback_exists = nil
  #... can't check for existence until the first marg() call, because we don't know $ch yet
$page_invoked_from = []
$reuse = {}
  # a hash for keeping track of how many times a figure has been reused within the same chapter
$web_command_marker = 'ZZZWEB:'

$count_section_commands = 0
$section_level = -1
$section_label_stack = [] # see begin_sec() and end_sec(); unlabeled sections have ''
$section_title_stack = []
$section_most_recently_begun = nil # title of the section that was the most recent one successfully processed
$conditional_stack = []

def fatal_error(message)
  $stderr.print "eruby_util.rb: #{message}\n"
  $stderr.print stack_dump()
  exit(-1)
end

def stack_dump
  result = "section title stack = "+$section_title_stack.join(',')+"\n"
  if !$section_most_recently_begun.nil? then
    result = result + "most recent begin_sec successfully processed was for #{$section_most_recently_begun}\n"
  end
  return result
end

def save_complaint(message)
  File.open('eruby_complaints','a') { |f| 
    f.print "eruby_util.rb: ",message,"\n"
  }
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


#--------------------------------------------------------------------------
config_file = 'book.config'
if ! File.exist?(config_file) then fatal_error("error, file #{config_file} does not exist") end
$config = {
  # In the following, nil means that there is no default and it's an error if it's not given explicitly.
  # If adding a new config variable here, then also add it below (why did I do this?).
  'titlecase_above'=>nil, # e.g., 1 means titlecase for chapters but not for sections or subsections
  'hw_block_style'=>0, # 1 means hw numbered like a7, as in Fundamentals of Calculus
  'allow_renumbering'=>0 # if a homework problem gets renumbered, is it ok in merge_problems_data.rb ?
}
File.open(config_file,'r') { |f|
  c = f.gets(nil) # nil means read whole file
  c.scan(/(\w+),(.*)/) { |var,value|
    if ! $config.has_key?(var) then fatal_error("Error in config file #{config_file}, illegal variable '#{var}'") end
    if {'titlecase_above'=>nil,'hw_block_style'=>nil,'allow_renumbering'=>nil}.has_key?(var) then
      value = value.to_i
    end
    $config[var] = value
  }
}
$config.keys.each { |k|
  if $config[k].nil? then fatal_error("error, variable #{k} not given in #{config_file}") end
}

#--------------------------------------------------------------------------
# The following code is a workaround for a bug in latex. The symptom is that I get
# "Missing \endcsname inserted" in a few isolated cases where I use a pageref inside
# the caption of a figure. See meki latex notes for more details. In these cases, I
# can get the refs using eruby instead of latex. See pageref_workaround() and ref_workaround() below.
# I also use this in LM, problems 3-2, 3-3, and 3-4, where they need to refer to the page where the blank form is given for sketching graphs;
# that doesn't work if I try to use the label associated with the floating figure, which points to the page from which it was invoked.

# Code similar to this is duplicated in translate_to_html.rb:
refs_file = 'save.ref'
$ref = {}
n_defs = {}
if File.exist?(refs_file) then # It's not an error if the file doesn't exist yet; references are just not defined yet, and that's normal for the first time on a fresh file.
  # lines look like this:
  #    fig:entropygraphb,h,255
  t = slurp_file(refs_file)
  t.scan(/(.*),(.*),(.*)/) { |label,number,page|
    if $ref[label]!=nil then
      if $last_chapter==true && $ref[label][0]!=number && $ref[label][1]!=page.to_i && label=~/\Afig:/ then 
        save_complaint("******* warning: figure #{label} defined both as figure #{$ref[label][0]} on p. #{$ref[label][1]} and as figure #{number} on p. #{page.to_i}, eruby_util.rb reading #{refs_file}")
      end
    end
    $ref[label] = [number,page.to_i]
    if n_defs[label]==nil then n_defs[label]=0 end
    n_defs[label] = n_defs[label]+1
  }
end
avg = 0
n = 0
n_defs.keys.each {|fig|
  n = n+1
  avg = avg + n_defs[fig]
}
avg = avg.to_f / n
n_defs.keys.each {|fig|
  #if n_defs[fig] > avg then $stderr.print "****** warning: figure #{fig} defined #{n_defs[fig]} times in save.ref, which is more than the average of #{avg}\n" end
}

def ref_workaround(label)
  if $ref[label]==nil then return 'nn' end # The first time through, won't have a save.ref. Put in a placeholder that's about the right width.
  return $ref[label][0]
end

def pageref_workaround(label)
  if $ref[label]==nil then return 'nnn' end # The first time through, won't have a save.ref. Put in a placeholder that's about the right width.
  return $ref[label][1].to_s
end

#--------------------------------------------------------------------------

# set by run_eruby.pl
# tells whether the book is calculus-based
# if set, ignore markers on hw and section in L&M for optional calc-based material
def calc
  return ENV['CALC']=='1'
end

# set by run_eruby.pl
# for use when generating screen-resolution figures
# e.g., ../9share/optics
def shared_figs
  return [ENV['SHARED_FIGS'],ENV['SHARED_FIGS2'],ENV['SHARED_FIGS3']]
end

def is_print
  return ENV['BOOK_OUTPUT_FORMAT']!='web'
end

def is_web
  return ENV['BOOK_OUTPUT_FORMAT']=='web'
end

def dir
  return ENV['DIR']
end

# argument can be 0, 1, true, or false; don't do, e.g., !__sn, because in ruby !0 is false
def begin_if(condition)
  if condition.class() == 1.class then
    if condition==1 then condition=true else condition=false end
  end
  if condition.class()!=TrueClass && condition.class()!=FalseClass then
    die('(begin_if)',"begin_if called with argument of class #{condition.class()}, should be Fixnum, true, or false")
  end
  $conditional_stack.push(condition)
  if !condition then
    print "\n\\begin{comment}\n" # requires comment package; newlines before and after are required by that package
  end
end

def end_if
  condition = $conditional_stack.pop
  if !condition then
    print "\n\\end{comment}\n" # requires comment package; newlines before and after are required by that package
  end
end

def pos_file
  return "ch#{$ch}.pos"
end

def strip_leading_zero_from_ch(ch)
  if ch=~/\A(([a-z]?)(\d+))\Z/ then
    whole,prefix,num = $1,$2,$3
    return prefix+num.to_i.to_s
  end
  save_complaint("warning: in strip_leading_zero_from_ch(), illegal chapter number #{ch}")
  return nil
end

def decrement_ch_num(n) # don't use directly, use previous_pos_file(), which calls this
  p = n.to_i-1
  if p<0 then return nil end
  if p<10 then p = '0'+p.to_s end
  return p
end

def previous_pos_file
  if $ch=~/\A\d+\Z/ then
    p = decrement_ch_num($ch)
    return "ch#{p}.pos"
  end
  # can have, e.g., 'a01' in fp
  if $ch=~/\A(([a-z]?)(\d+))\Z/ then
    whole,prefix,num = $1,$2,$3
    return "ch"+prefix+decrement_ch_num(num)+".pos"
  end
  save_complaint("warning: in previous_pos_file(), illegal chapter number #{$ch}")
  return nil
end

# returns data in units of mm, in the coordinate system used by pdfsavepos (positive y up)
def geom(what)
  if ! $checked_geom then
    $geom_exists = File.exist?($geom_file)
    if $geom_exists then
      File.open($geom_file,'r') do |f|
        line = f.gets
        if !(line=~/pt/) then # make sure it's already been parsed into millimeters
          $geom = line.split
        end
      end
    end
    $checked_geom = true
  end
  index = {'evenfigminx'=>0,'evenfigmaxx'=>1,'oddfigminx'=>2,'oddfigmaxx'=>3,'figminy'=>4,'figmaxy'=>5}[what]
  result = $geom[index].to_f
  if what=='figmaxy' then result=result-2.5 end
  return result
end

def end_marg
  if !$in_marg then die('(end_marg)',"end_marg, not in a marg in the first place, chapter #{$ch}") end
  if is_print then print "\\end{textblock*}\\end{margin}%\n\\vspace{1.5mm}" end
  if is_web then print "#{$web_command_marker}end_marg\n" end
  $in_marg = false
end

def marg(delta_y=0)
  # positive is up
  if $in_marg then die('(marg)','marg, but already in a marg') end
  $n_marg = $n_marg+1
  $in_marg = true
  if is_print then marg_print(delta_y) end
  if is_web   then print "#{$web_command_marker}marg\n" end
end

# sets $page_invoked_from[] as a side-effect
def marg_print(delta_y)
    print "\\begin{margin}{#{$n_marg}}{#{delta_y}}{#{$ch}}%\n";
    # (x,y) are in coordinate system used by pdfsavepos, with positive y up
    miny = geom('figminy')
    maxy = geom('figmaxy')
    x=geom('oddfigminx')
    y=maxy
    fig_file = "figfeedback#{$ch}"
    if $feedback_exists==nil then $feedback_exists=File.exist?(fig_file) end
    if $feedback_exists and !$read_feedback then
      $read_feedback = true
      File.open(fig_file,'r') do |f|
        f.each_line { |line|
          # line looks like this: 1,page=15,refx=6041561,refy=46929091,deltay=12
          if line =~ /(\d+),page=(\d+),refx=(\-?\d+),refy=(\-?\d+),deltay=(\-?\d+)/ then
            n,page,refx,refy,deltay=$1.to_i,$2.to_i,$3.to_i,$4.to_i,$5.to_i
            $feedback[n] = {'n'=>n,'page'=>page,'refx'=>refx,'refy'=>refy,'deltay'=>deltay}
            $page_invoked_from[n] = page
          else
            die(name,"syntax error in file #{fig_file}, line=#{line}")
          end
        }
      end
      File.delete(fig_file) # otherwise it grows by being appended to every time we run tex
    end
    if $feedback_exists then
      feed = $feedback[$n_marg]
      page = feed['page']
      refy = feed['refy']
      deltay = feed['deltay']
      y = refy*$tex_points_to_mm+deltay
      y_raw = y
      debug = false
      $stderr.print "miny=#{miny}\n" if debug
      ht = height_of_marg
      maxht = maxy-miny
      if page%2==0 then
        x=geom('evenfigminx') # left page
      else
        x=geom('oddfigminx') # right page
      end
      # The following are all in units of millimeters.
      tol_out =   50     # if a figure is outside its allowed region by less than this, we fix it silently; if it's more than that, we give a warning
      tol_in  =    5     # if a figure is this close to the top or bottom, we silently snap it exactly to the top or bottom
      max_fudge =  3     # amount by which a tall stack of figures can stick up over the top, if it's just plain too big to fit
      min_ht =    15     # even if we don't know ht, all figures are assumed to be at least this high
      if y>maxy+tol_out then warn_marg(1,$n_marg,page,"figure too high by #{mm(y-maxy)} mm, which is greater than #{mm(tol_out)} mm, ht=#{mm(ht)}") end
      if y>maxy-tol_in then y=maxy end
      if !(ht==nil) then
        $stderr.print "ht=#{ht}\n" if debug
        if y-ht<miny-tol_out then warn_marg(1,$n_marg,page,"figure too low by #{mm(miny-(y-ht))} mm, which is greater than #{tol_out} mm, ht=#{mm(ht)}") end
        if ht>maxht then
          # The stack of figures is simply too tall to fit. The user will get warned about this later, and may be doing it
          # on purpose, as a last resort. Typically in this situation, what looks least bad is to align it at the top, or a tiny bit above.
          fudge = ht-maxht
          if fudge>max_fudge then fudge=max_fudge end
          y=maxy+fudge
        else
          if y-ht<miny+tol_in then y=miny+ht end
        end
      end
      # A final sanity check, which has to work whether or not we know ht.
      if y>maxy+max_fudge then y=maxy+tol_insane end
      if y<miny+min_ht then y=miny+min_ht end
    end # if fig_file exists
    # In the following, I'm converting from pdfsavepos's coordinate system to textpos's; assumes calc package is available.
    print "\\begin{textblock*}{\\marginfigwidth}(#{x}mm,\\paperheight-#{y}mm)%\n"
end

# options is normally {}
# Used in Fundamentals of Calulus, looks like a shaded box with >Box 2.2  Title.
# Won't work in physics books, which don't have the necessary macros. For them, do a fig() with a 'text' option.
def marginbox(delta_y,name,caption,options,text)
  options['text'] = text
  options['textbox'] = true
  marg(delta_y)
  fig(name,caption,options)
  end_marg
end

def mm(x)
  if x==nil then return '' end
  return sprintf((x+0.5).to_i.to_s,"%d")
end

# severities:
#   1 = figure too low or high by more than 50 mm
# I currently have no other types of warnings with higher severities.
# I currently only report severity>1, so the calls to warn_marg() with severity=1 are noops.
# The warnings with severity=1 were too copious, had too many false positives, and were
# obscuring other, more important errors. They seldom if ever succeeded in locating anything
# that was actually a problem.
# Checks for colliding figures, which are a serious error, happen in a separate
# script, check_for_colliding_figures.rb.
def warn_marg(severity,nmarg,page,message)
  # First, figure out what figures are associated with the current margin block.
  mine = {}
  if File.exist?($marg_file) then
    File.open($marg_file,'r') do |f|
      f.each_line { |line|
        if line=~/fig:(.*),nmarg=(\d+),ch=([a-z]?\d+)/ then
          fig,gr,ch = $1,$2.to_i,$3
          mine[fig]=1 if (gr==nmarg.to_i && ch==$ch)
        else
          $stderr.print "error in #{$marg_file}, no match?? #{line}\n"
        end
      }
    end
  end
  if severity>1 then
    $stderr.print "warning, severity #{severity} nmarg=#{nmarg}, ch. #{$ch}, p. #{page}, #{mine.keys.join(',')}: #{message}\n"
  end
end

def pos_file_exists
  if ! $checked_pos then
    $pos_exists = File.exist?(pos_file())
    $checked_pos = true
  end
  return $pos_exists
end

# returns height in mm, or nil if the all.pos file doesn't exist yet, or figure not listed in it
def height_of_marg
  #debug = ($ch.to_i==0 and $n_marg==6)
  debug = false
  if debug then 
    $stderr.print "debug is on, pos_file_exists=#{pos_file_exists()}, pos_file=#{pos_file()}, cwd=#{Dir.getwd()}\n" 
    $stderr.print "listing of *.pos = "+`ls *.pos`
  end
  if !(File.exist?($marg_file)) then return nil end
  if !pos_file_exists() then return nil end
  # First, figure out what figures are associated with the current margin block.
  mine = Hash.new
  File.open($marg_file,'r') do |f|
    # The file grows by appending with each iteration. If the user isn't modifying the tex file (drastically) between
    # runs, then it should all just be exact repetition. If not, then we just use the freshest available data. At any given
    # time, the latest chunk of the file will be incomplete, and the freshest data for some margin blocks could be either
    # in the final chunk or in the penultimate one. There's some risk that something goofy could happen if the user
    # does rearrange blocks between iterations. The file also mixes data from different chapters.
    # ************ Bug: if the same figure is used in two different chapters, I think this will mess up **************************
    # ************ It's inefficient to call this many times. ********************
    f.each_line { |line|
      if !line.nil? && line=~/(.*),nmarg=(\d+),ch=([a-z]?\d+)/ then
        fig,gr,ch = $1,$2.to_i,$3
        mine[fig] = 1 if (gr==$n_marg.to_i and ch==$ch)
        $stderr.print "#{fig} is mine!\n" if debug and mine[fig]
      end
    }
  end
  $stderr.print "keys=" + (mine.keys.join(',')) + "\n" if debug
  # Read the chNN.pos file, which typically looks like this:
  #   fig,label=fig:mass-on-spring,page=15,x=28790655,y=45437345,at=begin
  #   fig,label=fig:mass-on-spring,page=15,x=38486990,y=27308866,at=endgraphic
  #   fig,label=fig:mass-on-spring,page=15,x=38195719,y=22590274,at=endcaption
  huge = 999/$tex_points_to_mm # 999 mm, expressed in units of tex points

  lo_y = huge
  hi_y = -huge
  found = false
  found,lo_y,hi_y = get_low_and_hi!(found,lo_y,hi_y,pos_file(),mine)

  # Very rarely (ch. 4 of genrel), I have a figure on the first page of a chapter, which gets written to the chNN.pos for the previous chapter.
  # I think this happens because the write18 that renames all.pos isn't executed until after the first page of the new chapter is output.
  # I don't know why this never happens in SN or LM; possibly because they have chapter opener photos that are big enough to cause buffers to get flushed?
  # Checking previous_pos_file() seems to take care of this on the very rare occasions when it happens.
  if !found and File.exist?(previous_pos_file()) then
    found,lo_y,hi_y = get_low_and_hi!(found,lo_y,hi_y,previous_pos_file(),mine)
  end
  if !found then
    #warn_marg(1,$n_marg,0,"figure not found in height_of_marg, $n_marg=#{$n_marg} $ch=#{$ch}; see comment in eruby_util for more about this")
    # This happens and is normal for wide figures, which are not in the margin. They appear in chNN.pos, but not in marg.pos.
  end

  if !found then return nil end
  height = (hi_y - lo_y)*$tex_points_to_mm
  #if height<1 then die('(height_of_marg)',"height #{height} is too small, lo=#{lo_y}, hi=#{hi_y}") end
  if height<1 then return nil end #???????????????????????????????????????
  $stderr.print "height=#{height}\n" if debug
  return height
end

def get_low_and_hi!(found,lo_y,hi_y,filename,mine)
  File.open(filename,'r') do |f|
    f.each_line { |line|
      if line=~/^fig,label=(.*),page=(.*),x=(.*),y=(.*),at=(.*)/ then
        fig,page,y=$1,$2.to_i,$4.to_i
        if mine.has_key?(fig) then
          if y<lo_y then lo_y = y end
          if y>hi_y then hi_y = y end
          found = true
        end
      end
    }
  end
  [found,lo_y,hi_y]
end

def figure_exists_in_my_own_dir?(name)
  return figure_exists_in_this_dir?(name,dir()+"/figs")
end

def figure_exists_in_this_dir?(name,d)
  return (File.exist?("#{d}/#{name}.pdf") or File.exist?("#{d}/#{name}.jpg") or File.exist?("#{d}/#{name}.png"))
end

# returns a directory (possibly with LaTeX macros in it) or nil if we can't find the figure
def find_directory_where_figure_is(name)
  if figure_exists_in_my_own_dir?(name) then return dir = "\\figprefix\\chapdir/figs" end
  # bug: doesn't support \figprefix
  s = shared_figs()
  s.each { |ss|
    if figure_exists_in_this_dir?(name,ss) then return ss end
  }
  return nil
end

def figure_in_toc(name,options={})
  default_options = {
    'scootx'=>0,
    'scooty'=>0,
    'noresize'=>false
  }
  default_options.each { 
    |option,default|
    if options[option]==nil then
      options[option]=default
    end
  }
  d = 'ch00/figs'
  if !(File.exist?(d)) then d='front/figs' end
  if !(File.exist?("#{d}/toc-#{name}.pdf") or File.exist?("#{d}/toc-#{name}.jpg") or File.exist?("#{d}/toc-#{name}.png")) then
    d='../share/toc' 
  end
  if options['noresize'] then
    print "\\addtocontents{toc}{\\protect\\figureintocnoresize{#{d}/toc-#{name}}}"
  else
    if options['scootx']==0 then
      if options['scooty']==0 then
        print "\\addtocontents{toc}{\\protect\\figureintoc{#{d}/toc-#{name}}}"
      else
        print "\\addtocontents{toc}{\\protect\\figureintocscooty{#{d}/toc-#{name}}{#{options['scooty']}mm}}"
      end
    else
      print "\\addtocontents{toc}{\\protect\\figureintocscootx{#{d}/toc-#{name}}{#{options['scootx']}mm}}"
    end
  end
end

def x_mark
  raw_fig('x-mark')
end

def raw_fig(name)
  fig(name,'',{'raw'=>true})
end

def eqn_image(name,hardcoded_dir=nil)
  # Embed an image inside an equation.
  # Used in SN 14 and FAC ac/b.
  dir = hardcoded_dir
  if hardcoded_dir.nil? then
    dir = find_directory_where_figure_is(name)
    if dir.nil? then fatal_error("figure #{name} not found in #{dir()}/figs or #{shared_figs()}, ch=#{$ch}") end
  end
  file = "#{dir}/#{name}"
  file_with_extension = file+".png"
  # used to have \includegraphics[resolution=300], but that now causes an error:
  #       https://tex.stackexchange.com/questions/301494/how-to-use-includegraphics
  resolution = `identify -units PixelsPerInch -format "%x" #{file_with_extension}`.to_i
  # ... generates an exception if this fails, e.g., if imagemagick isn't installed
  if (resolution.nil? || resolution<299) then
    do_system_command("mogrify -units PixelsPerInch -density 300 #{file_with_extension}")
  end
  print "\\raisebox{-.2\\height}{\\includegraphics{#{file}}}"
end

def do_system_command(c)
  result = system(c)
  if !($?.success?) then
    die('do_system_command',"failed on command #{c}, error is #{$?}")
  end
end

def fig(name,caption=nil,options={})
  default_options = {
    'anonymous'=>'default',# true means figure has no figure number, but still gets labeled (which is, e.g., 
                           #      necessary for photo credits)
                           # default is false, except if caption is a null string, in which case it defaults to true
    'width'=>'narrow',     # 'native'=whatever the figure says it is, 'narrow'=52 mm, 'column'=76.5 mm,
                           #   'wide'=113 mm, 'fullpage'=171 mm
                           #   refers to graphic, not graphic plus caption (which is greater for sidecaption option)
    'sidecaption'=>false,
    'sidepos'=>'t',        # positioning of the side caption relative to the figure; can also be b, c
    'float'=>'default',    # defaults to false for narrow, true for wide or fullpage (because I couldn't get odd-even to work reliably for those if not floating)
    'floatpos'=>'h',       # standard latex positioning parameter for floating figures
    'narrowfigwidecaption'=>false, # currently only supported with float and !anonymous
    'suffix'=>'',          # for use when a figure is used in more than one place, and we need to make the label unique;
                           #   typically 'suffix'=>'2'; don't need this option on the first fig, only the second
    'text'=>nil,           # if it exists, puts the text in the figure rather than a graphic (name is still required for labeling)
                           #      see macros \starttextfig and \finishtextfig
                           # For an example of how to do this, see SN ch. 3, "Gory details of the proof..."
                           # Tables and align* don't work in text, nor does \\, but paragraph breaks work;
                           # may be able to get around this with minipage.
    'title'=>nil,          # for use with 'text', goes above the text
    'raw'=>false,          # used for anonymous inline figures, e.g., check marks; generates a raw call to includegraphics
    'textbox'=>false       # marginbox(), as used in Fund.; won't work in other books, which don't have the macros in their cls files
    # not yet implemeted: 
    #    translated=false
    #      or just have the script autodetect whether a translated version exists!
    #    toc=false
    #      figure is to be used in table of contents
    #      see macros \figureintoc, \figureintocnoresize
    #    midtoc=false
    #      figure in toc is to be used in the middle of a chapter (only allowed with toc=true)
    #      see macro figureintocscootx
    #    scootdown=0
    #      distance by which to scoot it down (only allowed with toc=true)
    #      see macro figureintocscooty
    #    gray=false
    #      automagically add a gray background
    #    gray2=false
    #      automagically add a gray background if it's 2-column
    #    resize=true
    #      see macros \fignoresize, \inlinefignocaptionnoresize
  }
  unless caption.nil? then caption.gsub!(/\A\s+/,'') end # blank lines on the front make latex freak out
  if caption=='' then caption=nil end
  default_options.each { 
    |option,default|
    if options[option]==nil then
      options[option]=default
    end
  }
  width=options['width']
  if options['narrowfigwidecaption'] then
    options['width']='wide'; options['sidecaption']=true; options['float']=false; options['anonymous']=false
  end

  # Generate fig_widths. To regenerate these, change false to true below, and then follow
  # directions in ~/Documents/writing/books/physics/data/README. This data file is used by problems book.
  if false && width!='narrow' then
    File.open('/home/bcrowell/fig_widths','a') { |f|
      f.print "\"#{name}\":\"#{width}\",\n"
    }
  end

  if options['float']=='default' then
    options['float']=(width=='wide' or width=='fullpage')
  end
  has_caption = !(caption.nil?)
  if options['anonymous']=='default' then
    options['anonymous']=!has_caption
  end
  dir = find_directory_where_figure_is(name)
  if dir.nil? && options['text'].nil? then fatal_error("figure #{name} not found in #{dir()}/figs or #{shared_figs()}, ch=#{$ch}") end
  #------------------------------------------------------------
  if is_print then fig_print(name,caption,options,dir) end
  #------------------------------------------------------------
  if is_web then process_fig_web(name,caption,options) end
end

def process_fig_web(name,caption,options)
  if options['raw'] then print "\\anonymousinlinefig{#{dir}/#{name}}"; return end
  if caption==nil then caption='' end
  # remove comments now, will be too late to do it later; can't use lookbehind because eruby compiled with ruby 1.8
  caption.gsub!(/\\%/,'PROTECTPERCENT') 
  caption.gsub!(/%[^\n]*\n?/,' ')
  caption.gsub!(/PROTECTPERCENT/,"\\%") 
  caption.gsub!(/\n/,' ')
  text = options['text']
  anon = '0'
  anon = '1' if options['anonymous']
  if text==nil then
    if options['width']=='wide' then print "\n" end # kludgy fix for problem with html translator
    print "#{$web_command_marker}fig,#{name},#{options['width']},#{anon},#{caption}END_CAPTION\n"
  else
    text.gsub!(/\n/,' ')
    print "#{text}\n\n#{caption}\n\n" # bug ------------- not really correct
  end
end

# sets $page_rendered_on as a side-effect (or sets it to nil if all.pos isn't available yet)
def fig_print(name,caption,options,dir)
  has_caption = !(caption.nil?)
  if options['raw'] then spit("\\includegraphics{#{dir}/#{name}}"); return end
  width=options['width']
  $fig_handled = false
  sidepos = options['sidepos']
  floatpos = options['floatpos']
  suffix = options['suffix']
  if (!(suffix=='')) and width=='wide' and ! options['float'] then die(name,"suffix not implemented for wide, !float") end
  if (!(suffix=='')) and width=='narrow' and options['anonymous'] then die(name,"suffix not implemented for narrow, anonymous") end
  print "\\noindent"
  #============================================================================
  if $reuse.has_key?(name)
    $reuse[name]+=1
  else
    $reuse[name]=0
  end
  if $in_marg then
    File.open($marg_file,'a') do |f|
      f.print "fig:#{name},nmarg=#{$n_marg},ch=#{$ch}\n"
    end
  end
  # Warn about figures that aren't floating, but that occur on a different page than the one on which they were invoked.
  # Since the bug I'm trying to track down is a bug with marginal figures, only check if it's a marginal figure.
  # This is somewhat inefficient.
  if $in_marg and ! options['float'] then
    invoked = $page_invoked_from[$n_marg]
    $page_rendered_on=nil
    last_l,last_page = nil,nil
    if File.exist?(pos_file()) and !(invoked==nil) then
      File.open(pos_file(),'r') do |f|
        reuse = 0
        f.each_line { |line|
          if line=~/^fig,label=fig:(.*),page=(.*),x=(.*),y=(.*),at=(.*)/ then
            l,page=$1,$2.to_i
            if l==name and !(last_l==l and last_page==page) then # second clause is because we get several lines in a row for each fig
              $page_rendered_on=page if reuse==$reuse[name]
              reuse+=1
            end
            last_l,last_page = l,page
          end
        }
      end
    end
    if !($page_rendered_on==nil) and !(invoked==nil) and !(invoked==$page_rendered_on) then
      $stderr.print "***** warning: invoked on page #{invoked}, but rendered on page #{$page_rendered_on}, off by #{$page_rendered_on-invoked}, #{name}, ch.=#{$ch}\n" +
                    "      This typically happens when the last few lines of the paragraph above the figure fall at the top of a page.\n"
    end
  end
  #============================================================================
  #----------------------- text ----------------------
  if options['text']!=nil then
    text = options['text']
    if options['title'] then text="\\noindent\\textit{#{options['title']}}\\\\"+text end
    if options['textbox'] then
      spit("\\startmargintextbox{#{name}}{#{caption}}\n#{text}\n\\finishmargintextbox{#{name}}\n")
    else
      if has_caption then m = "finishtextfig" else m = "finishtextfignocaption" end
      spit("\\starttextfig{#{name}}#{text}\n\\#{m}{#{name}}{%\n#{caption}}\n")
    end
  end
  #----------------------- native ----------------------
  if width=='native' then
    spit("\\fignocaptionnativewidth{#{name}}{#{dir}}\n")
  end
  #----------------------- narrow ----------------------
  if width=='narrow' and options['text']==nil then
    if options['anonymous'] then
      if has_caption then
        spit("\\anonymousfig{#{name}}{%\n#{caption}}{#{dir}}\n")
      else
        spit("\\fignocaption{#{name}}{#{dir}}\n")
      end
    else # not anonymous
      if has_caption then
        spit("\\fig{#{name}}{%\n#{caption}}{#{suffix}}{#{dir}}\n")
      else
        die(name,"no caption, but not anonymous")
      end
    end
  end
  #----------------------- column ------------------------
  if width=='column' and options['text']==nil then
    if options['sidecaption'] then
      die(name,"width is column but sidecaption is true")
    end
    if options['narrowfigwidecaption'] then
      die(name,"width is column but narrowfigwidecaption is true")
    end
    if !has_caption && !options['anonymous']
      die(name,"no caption, but not anonymous")
    end
    if options['anonymous'] then
      if options['float']  then
        spit("\\columnfig[#{floatpos}]{#{name}}{%\n#{caption}}{#{suffix}}{anonymous}{#{dir}}\n")
      else # not floating
        if has_caption then
          spit("\\columnfignofloatanon[#{dir}]{#{name}}{#{caption}}")
        else
          spit("\\columnfignocaptionnofloat[#{dir}]{#{name}}\n")
        end
      end
    else # not anonymous
      if options['float'] then
        spit("\\columnfig[#{floatpos}]{#{name}}{%\n#{caption}}{#{suffix}}{labeled}{#{dir}}\n") # tested
      else # not floating
        spit("\\columnfignofloat{#{name}}{%\n#{caption}}\n") # tested
      end # not floating
    end # not anonymous
  end
  #----------------------- wide ------------------------
  if width=='wide' and options['text']==nil then
    if options['anonymous'] then
      if options['narrowfigwidecaption'] then die(name,'narrowfigwidecaption requires anonymous=false, and float=false') end
      if options['float']  then
        if has_caption || true then # see einstein-train
          if options['sidecaption'] then
            spit("\\widefigsidecaption{#{sidepos}}{#{name}}{%\n#{caption}}{anonymous}{#{floatpos}}{float}{#{suffix}}{#{dir}}\n")
          else
            spit("\\widefig[#{floatpos}]{#{name}}{%\n#{caption}}{#{suffix}}{anonymous}{#{dir}}\n")
          end
        else
          die(name,"widefignocaption is currently only implemented as a nonfloating figure")
        end
      else # not floating
        if has_caption then
          #die(name,"widefig is currently only implemented as a floating figure, because I couldn't get it to work right unless it was floating (see comments in lmcommon.sty)")
        else
          spit("\\widefignocaptionnofloat[#{dir}]{#{name}}\n")
        end
      end
    else # not anonymous
      if options['float'] then
        if options['narrowfigwidecaption'] then die(name,'narrowfigwidecaption requires anonymous=false, and float=false') end
        if has_caption then
          if options['sidecaption'] then
            spit("\\widefigsidecaption{#{sidepos}}{#{name}}{%\n#{caption}}{labeled}{#{floatpos}}{float}{#{suffix}}{#{dir}}\n")
          else
            spit("\\widefig[#{floatpos}]{#{name}}{%\n#{caption}}{#{suffix}}{labeled}{#{dir}}\n")
          end
        else
          die(name,"no caption, but not anonymous")
        end
      else # not floating
        if options['narrowfigwidecaption'] then
          spit("\\narrowfigwidecaptionnofloat{#{name}}{%\n#{caption}}{#{dir}}\n")
        else
          die(name,"The only wide figure that's implemented the option of not floating is narrowfigwidecaption. See comments in lmcommon.sty for explanation.")
        end
      end # not floating
    end # not anonymous
  end # if wide
  #----------------------- fullpage ----------------------
  if width=='fullpage' and options['text']==nil then
    if options['anonymous'] then
      if has_caption then
        die(name,"the combination of options fullpage+anonymous+caption is not currently supported")
      else
        spit("\\fullpagewidthfignocaption[#{dir}]{#{name}}\n")
      end
    else # not anonymous
      if has_caption then
        spit("\\fullpagewidthfig[#{dir}]{#{name}}{%\n#{caption}}\n")
      else
        die(name,"no caption, but not anonymous")
      end
    end
  end
  #============================================================================
  if $fig_handled then
    # Kludge: when figure is like ../../../foo/bar/baz, label includes the .. stuff; make a valid label.
    # A better way to do this would be to have the macros never generate a label, and have the following
    # be the only way a label is ever generated.
    if name=~/\/([^\/]+)$/ then
      spit("\\label{fig:#{$1}}")
    end
  else
    die(name,"not handled")
  end
end

def spit(tex)
  print tex
  $fig_handled = true
end

# use fatal_error if not directly related to a figure
def die(name,message)
  $stderr.print "eruby_util: figure #{name}, #{message}\n"
  exit(-1)
end

def self_check(label,text)
  text.gsub!(/\n+\Z/) {""} # strip excess newlines at the end
  text.gsub!(/\\\\/) {"\\"} # double backslashes to single; this is just a shortcut because I screwed up and unnecessarily changed a bunch of \ to \\
  print "\\begin{selfcheck}{#{label}}\n#{text}\n\\end{selfcheck}\n"
  write_to_answer_data('self_check',label)
end

def read_whole_file(file)
  x = ''
  File.open(file,'r') { |f|
    x = f.gets(nil) # nil means read whole file
  }
  return x
end

#--------------------------------------------------
# code for numbering style used in Fundamentals of Calculus
#--------------------------------------------------

def hw_block_style
  return $config['hw_block_style']==1 # set in book.config
end

# first block is 0<->a
def integer_to_base24(i)
  if i<0 then fatal_error("negative i in integer_to_base24") end
  if i<24 then return "abcdefghijkmnpqrstuvwxyz"[i] end
  return integer_to_base24(i/24)+integer_to_base24(i%24)
end

def base24_to_integer(s)
  if s.length==0 then fatal_error("null string in base24_to_integer") end
  if s.length==1 then
    i = "abcdefghijkmnpqrstuvwxyz".index(s)
    if i.nil? then fatal_error("illegal character #{s} in base24_to_integer") end
    return i
  end
  return base24_to_integer(s[0,s.length-1])*24+base24_to_integer(s[s.length-1])
end

# test integer_to_base24() and base24_to_integer()
if false then
  [[0,'a'],[1,'b'],[23,'z'],[24,'ba']].each { |x|
    i = x[0]
    s = x[1]
    unless integer_to_base24(i)==s then 
      $stderr.print "integer_to_base24("+i.to_s+") gives "+integer_to_base24(i)+", should have given "+s+"\n"
      exit(-1)
    end
    unless base24_to_integer(s)==i then 
      $stderr.print "base24_to_integer("+s+") gives "+base24_to_integer(s).to_s+", should have given "+i+"\n"
      exit(-1)
    end
  }
end

def hw_freeze
  if $hw_freeze<0 then fatal_error("hw_freeze invoked, and $hw_freeze already less than 0? ") end
  $hw_freeze = $hw_freeze+1
end

def hw_end_freeze
  $hw_freeze = $hw_freeze-1
  if $hw_freeze<0 then fatal_error("hw_end_freeze invoked, and $hw_freeze already 0? ") end
end

def get_hw_block
  return integer_to_base24($hw_block)
end

def hw_label
  label = $hw_number.to_s
  if hw_block_style() then label = get_hw_block+$hw_number_in_block.to_s end 
  return label
end

# control of letter that labels block
# hw_block ... bumps by 3
# hw_block(1) ... bumps by 1
# hw_block('b') ... sets it to 'b'
# 2nd arg = 0 means no extra vfill between blocks
def hw_block(*arg)
  x = arg[0]
  stretch = arg[1]
  if stretch.nil? then stretch=1 end
  $hw_number_in_block = 0
  if stretch==1 then print %Q~\\vspace{\\stretch{2}}~ end
     # ... twice as big as what's at the end of homeworkforcelabel in lmcommon.sty
  if x.nil? then $hw_block = $hw_block+3; return end
  if x.class() == Fixnum then $hw_block = $hw_block+x; return end
  if x.class() == String then $hw_block = base24_to_integer(x); return end
  fatal_error("error in hw_block, arg has class=#{x.class()}")
end

#--------------------------------------------------

def hw(name,options={},difficulty=1) # used in Fundamentals of Calculus, which has all hw in chNN/hw; other books use begin_hw
  if difficulty==nil then difficulty=1 end
  begin_hw(name,difficulty,options)
  x = read_whole_file("ch#{$ch}/hw/#{name}.tex")
  print x.sub(/\n+\Z/,'')+"\n" # exactly one newline at end before \end{homework}
  if options['solution'] then hw_solution() end
  end_hw
end

def begin_hw(name,difficulty=1,options={})
  if difficulty==nil then difficulty=1 end
  if calc() then options['calc']=false end
  calc = ''
  if options['calc'] then calc='1' end
  $hw_number += 1
  $hw_number_in_block += 1
  $hw[$hw_number] = name
  $hw_has_solution[$hw_number] = false
  label = hw_label()
  $store_hw_label[$hw_number] = label
  print "\\begin{homeworkforcelabel}{#{name}}{#{difficulty}}{#{calc}}{#{label}}"
  $hw_trailing[$hw_number] = ''
  if !(options['credit'].nil?) then 
     $hw_trailing[$hw_number] =  $hw_trailing[$hw_number] + "\\hwaddtrailingstuff{\\hwcredit{#{options['credit']}}}"
  end
end

def hw_solution()
  $hw_has_solution[$hw_number] = true # for problems.csv
  print "\\hwsoln"
  write_to_answer_data('answer')
end

def hw_hint(label)
  print "\\hwhint{hwhint:#{label}}"
  write_to_answer_data('hint')
  #debug = (label=='nestedsolenoids' || label=='erbium')
  #if debug then $stderr.print "hw_hint: wrote to answer data, label=#{label}\n" end
end

def hw_answer()
  print "\\hwans{hwans:#{$hw[$hw_number]}}"
  write_to_answer_data('bare_answer')
end

$answer_data_file = 'answers.csv'
$answer_data = []
$answer_text = {'answer'=>{},'hint'=>{},'self_check'=>{},'bare_answer'=>{}}
$answer_long_label_to_short = {}

def clear_answer_data
  File.open($answer_data_file,'w') { |f| }
end

def write_to_answer_data(type,label=nil)
  if label==nil then label = $hw[$hw_number] end
  File.open($answer_data_file,'a') { |f|
    f.print "#{strip_leading_zero_from_ch($ch)},#{label},#{type}\n"
  }
end

def read_answer_data()
  $answer_data = []
  if ! File.exist?($answer_data_file) then return end
  File.open($answer_data_file,'r') { |f|
    a = f.gets(nil) # nil means read whole file
    a.scan(/(\d+),(.*),(.*)/) { |ch,name,type|
      $answer_data.push([ch.to_i,name,type])
    }
  }
end

def print_general_answer_section_header(header)
  print_end_matter_section_header(header)
end

def print_photo_credits_section_header(header)
  print_end_matter_section_header(header)
end

def print_end_matter_section_header(header)
  header = alter_titlecase(header,0)
  print "\\addcontentsline{toc}{section}{#{header}}\\formatlikechapter{#{header}}\\\\*\n\n"
end

def print_answers_of_one_type(lo_ch,hi_ch,type,header)
  #$stderr.print "print_answers_of_one_type, type=#{type}\n"
  read_answer_data()
  print "\\hwanssection{#{header}}\n\n"
  last_ch = -1
  for ch in lo_ch..hi_ch do
    $answer_data.each { |a|
      #$stderr.print "type=",type,' ',a.join(','),"\n" if ch==0 && a[0]==0
      #debug = (a[1]=='nestedsolenoids' || a[1]=='erbium')
      #if debug then $stderr.print "debugging, ch=#{ch}, a=#{a}\n" end
      name = a[1]
      if ch==a[0] && type==a[2] then
        if last_ch!=ch then
          describe_them = {'answer'=>'Solutions','hint'=>'Hints','self_check'=>'Answers to self-checks','bare_answer'=>'Answers'}[type]
          print '\par\pagebreak[3]\vspace{2mm}\noindent\formatlikesubsection{'+describe_them+' for chapter '+ch.to_s+'}\\\\*'
        end
        last_ch = ch
        long = answer_short_label_to_long(name,type)
        if long==nil then
          save_complaint("No answer text available for problem #{name}, type #{type}; this may be because you didn't put an appropriate line in hwans.rbtex")
        else
          print answer_header(long,type)+$answer_text[type][long]
        end
      end
    }
  end
end

def answer_short_label_to_long(short,type)
  $answer_long_label_to_short.each { |long,s|
    if s==short and !$answer_text[type][long].nil? then return long end
  }
  return nil
end

def answer_header(label,type)
  macro = {'answer'=>'hwsolnhdr','hint'=>'hinthdr','self_check'=>'scanshdr','bare_answer'=>'hwanshdr'}[type]
  if macro==nil then fatal_error("error in eruby_util.rb, answer_header(), illegal type: #{type}") end
  short_label = $answer_long_label_to_short[label]
  return "\\#{macro}{#{short_label}}\\\\*\n"
end

def list_some_problems(names)
  a = []
  names.each { |name|
    a.push("p.~\\pageref{hw:#{name}}, \\#\\ref{hw:#{name}}")
  }
  print a.join("; ")
end

def hw_ref(name)
  print "\\ref{hw:#{name}}"
  $hw_names_referred_to.push(name)
end

def end_hw()
  print $hw_trailing[$hw_number]
  print "\\end{homeworkforcelabel}"
end

def hint_text(label,text=nil)
  set_answer_text(label,"hint-"+label,text,'hint')
end

def self_check_answer(label,text=nil)
  set_answer_text(label,nil,text,'self_check')
end

def bare_answer(label,text=nil)
  set_answer_text(label,nil,text,'bare_answer')
end

def answer(label,text=nil) # don't call this directly
  set_answer_text(label,nil,text,'answer')
end

def set_answer_text(label,long_label,text,type)
  # long_label is because some problems may have both hint and answer, etc.
  # short label is used only for latex references
  if long_label==nil then long_label = label end
  text = handle_answer_text_caching(long_label,text,type)
  text = handle_m4_in_answer_file(text)
  $answer_text[type][long_label] = text
  $answer_long_label_to_short[long_label] = label 
  #debug = (label=~/nestedsolenoids/ || label=~/erbium/)
  #if debug then $stderr.print "set_answer_text: label=#{label}\n" end
end

def handle_m4_in_answer_file(text)
  # This happens in lowering-climber.
  return text unless text=~/m4_/;
  run_m4 = whichever_file_exists(["../scripts/run_m4.pl","scripts/run_m4.pl"])
  if run_m4.nil? then save_complaint("couldn't find scripts/run_m4.pl in handle_m4_in_answer_file"); return text end
  result = text
  temp_file_name = "handle_m4_in_answer_file.temp"
  File.open(temp_file_name,'w') { |f|
    f.print text
  }
  cmd = "#{run_m4} #{temp_file_name} #{ENV['BK']} ."
  result = `#{cmd}`
  if result=='' then $stderr.print "error in handle_m4_in_answer_file, result is null string" end
  File.delete(temp_file_name)
  return result
end

def handle_answer_text_caching(label,text,type)
  file = File.expand_path("../share/answers") + "/" + label + ".tex"
  have_file = FileTest.exist?(file)
  gave_text = text!=nil
  if gave_text && ! have_file then
    File.open(file,'w') { |f|
      f.print text+"\n\n"
    }
  end
  if gave_text && have_file then
    # so I can cut and paste to replace the old version that includes the text with the new version that doesn't
    func = {'answer'=>"answer",'hint'=>'hint_text','self_check'=>'self_check_answer','bare_answer'=>'bare_answer'}[type]
    $stderr.print "<% #{func}(\"#{label}\") %>\n" 
  end
  if !gave_text && ! have_file then
    $stderr.print "error in eruby_util.rb, handle_answer_text_caching: file #{file} doesn't exist\n"
    text = ''
  end
  if !gave_text then
    File.open(file,'r') { |f|
      text = f.gets(nil) # nil means slurp whole file
    }
    text.gsub!(/\n+\Z/) {"\n\n"} # exactly two newlines at the end
  end
  return text
end

def part_title(title)
  title = alter_titlecase(title,-1)
  print "\\mypart{#{title}}"
end

def begin_ex(title,label='',columns=1)
  title = alter_titlecase(title,1)
  column_command = (columns==1 ? "\\onecolumn" : "\\twocolumn");
  print "\\begin{handson}{#{label}}{#{title}}{#{column_command}}"
end

def end_ex
  print "\\end{handson}"
end

# The following are used in FAC:
def begin_lab(title,columns:2,suffix:'',type:'mini',number:'')
  # suffix is, e.g., B for ex. 3B in ch. 3
  title = alter_titlecase(title,1)
  typename = 'Lab'
  if type=='mini' then typename = 'Minilab' end
  if type=='ex'   then typename = 'Exercise' end
  if number==''
    number = "\\thechapter{}"
  end
  column_command = (columns==1 ? "\\onecolumn" : "\\twocolumn")
  label = number+suffix
  full_label = "activity-#{type}:"+label
  t = "\\begin{activity}{#{suffix}}{#{title}}{#{column_command}}{#{typename} #{number}#{suffix}: }"
  if not is_prepress then t = t + "\\anchor{anchor-#{full_label}}" end
  t = t+"\\normalcaptions\\zapcounters"
  if is_prepress then
    t = t + "\\addcontentsline{toc}{section}{#{title}}"
  else
    t = t + "\\addcontentsline{toc}{section}{\\protect\\link{#{full_label}}{#{typename} #{number}#{suffix}: #{title}}}"
  end
  print t
end

def end_lab
  print "\\end{activity}"
end

def begin_notes(columns=2)
  full_label = "notes:#{$ch}"
  title = "Notes for chapter \\thechapter"
  column_command = (columns==1 ? "\\onecolumn" : "\\twocolumn");
  t = "\\begin{activity}{}{#{title}}{#{column_command}}{}"
  if is_prepress then t = t + "\\anchor{anchor-#{full_label}}" end
  if is_prepress then
    t = t + "\\addcontentsline{toc}{section}{#{title}}"
  else
    t = t + "\\addcontentsline{toc}{section}{\\protect\\link{#{full_label}}{#{title}}}"
  end
  print t
end

def end_notes
  print "\\end{activity}"
end

# Examples:
#   end_sec()
#   end_sec('spacetime-interval') ... try to use this form, which acts as a check on whether the hierarchy
#             of sections is out of whack
# It's OK if begin_sec() gives a label but end_sec() doesn't.
def end_sec(label='')
  debug = false
  $count_section_commands += 1
  $section_level -= 1
  if debug then $stderr.print ('  '*$section_level)+"end_sec('#{label}')\n" end
  began_sec = $section_label_stack.pop # is '' if the section was unlabeled, nil if the stack was empty
  began_title = $section_title_stack.pop
  if began_sec.nil? then fatal_error("end_sec('#{label}') occurs without any begin_sec") end
  if label!=began_sec and !(began_sec!='' and label=='') then
    fatal_error("mismatch between labels, begin_sec(\"#{began_title}\",...,'#{began_sec}') and end_sec('#{label}')") 
  end
end

# example of use: begin_sec("The spacetime interval",nil,'spacetime-interval',{'optional'=>true})
# In this example, the LaTeX label  might be sec:spacetime-interval in LM, subsec:spacetime-interval in SN.
# The corresponding end_sec could use an optional arg, end_sec('spacetime-interval'), which helps to make
# sure the hierarchical structure doesn't get out of whack. The structure tends to get out of whack when
# different books share text, using m4 conditionals.
def begin_sec(title,pagebreak=nil,label='',options={})
  debug = false
  $count_section_commands += 1
  if debug then $stderr.print ('  '*$section_level)+"begin_sec(\"#{title}\",#{pagebreak},\"#{label}\")\n" end
  $section_level += 1
  $section_label_stack.push(label) # if not labeled, then label is ''
  $section_title_stack.push(title)
  # In LM, section level 1=section, 2=subsection, 3=subsubsection; 0 would be chapter, but chapters aren't done with begin_sec()
  if $section_level==0 || $section_level>4 then
    e=''
    if $section_level==0 then e='zero section level (happens in NP Preface)' end
    if $section_level>3 then e='section level is too deep' end
    $stderr.print "warning, at #{$count_section_commands}th section command, ch #{$ch}, section #{title}, section level=#{$section_level}, #{e}\n"
    $section_level = 1
  end
  # Guard against the easy error of writing begin_sec("title","label"), leaving out pagebreak.
  unless pagebreak.nil? or pagebreak.kind_of?(Integer) then fatal_error("begin_sec(\"#{title}\",\"#{pagebreak}\",...) has non-integer second argument; did you leave out the pagebreak parameter?") end
  if pagebreak==nil then pagebreak=4-$section_level end
  if pagebreak>4 then pagebreak=4 end
  if pagebreak<0 then pagebreak=0 end
  pagebreak = '['+pagebreak.to_s+']'
  if $section_level>=3 then pagebreak = '' end
  macro = ''
  label_level = ''
  if calc() then options['calc']=false end
  if $section_level==1 then
    if options['calc'] and options['optional'] then macro='myoptionalcalcsection' end
    if options['calc'] and !options['optional'] then macro='mycalcsection' end
    if !options['calc'] and options['optional'] then macro='myoptionalsection' end
    if !options['calc'] and !options['optional'] then macro='mysection' end
    label_level = 'sec'
  end
  if $section_level==2 then
    if options['toc']==false then
      macro = 'mysubsectionnotoc'
    else
      if options['optional'] then macro='myoptionalsubsection' else macro = 'mysubsection' end
    end
    label_level = 'subsec'
  end
  if $section_level==3 then
    macro = 'subsubsection'
    label_level = 'subsubsec'
  end
  if $section_level==4 then
    macro = 'myssssection'
    label_level = 'subsubsubsec'
  end
  title = alter_titlecase(title,$section_level)
  cmd = "\\#{macro}#{pagebreak}{#{title}}"
  t = sectioning_command_with_href(cmd,$section_level,label,label_level,title,options['optional'])
  #$stderr.print t
  print t
  $section_most_recently_begun = title
  #$stderr.print "in begin_sec(), eruby_util.rb: level=#{$section_level}, title=#{title}, macro=#{macro}\n"
end

def begin_hw_sec(title='Problems')
  label = "hw-#{$ch}-#{title.downcase.gsub(/\s+/,'_')}"
  t = <<-TEX
    \\anchor{anchor-#{label}}% navigator_package
    \\begin{hwsection}[#{title}]
    TEX
  if is_prepress then
    t = t + "\\addcontentsline{toc}{section}{#{title}}"
  else
    t = t + "\\addcontentsline{toc}{section}{\\protect\\link{#{label}}{#{title}}}"
  end
  print t
  $inside_hw_sec = true
end

def end_hw_sec
  $inside_hw_sec = false
  print '\end{hwsection}'
end

def sectioning_command_with_href(cmd,section_level,label,label_level,title,optional)
  # http://tex.stackexchange.com/a/200940/6853
  name_level = {0=>'chapter',1=>'section',2=>'subsection',3=>'subsubsection',4=>'subsubsubsection'}[section_level]
  label_command = ''
  complete_label = ''
  anchor_command = ''
  if label=='' then
    #label = ("ch-"+$ch.to_s+"-"+name_level+"-"+title).downcase.gsub(/[^a-z]/,'-').gsub(/\-\-+/,'-')
    #label = label + rand(10000).to_s + (Time::new.to_i % 10000).to_s # otherwise I get some non-unique ones
    label = "ch-#{$ch}-#{$label_counter}"
    $label_counter += 1
  end
  if label != '' then # shouldn't happen, since we construct one above if need be
    complete_label = "#{label_level}:#{label}"
    label_command="\\label{#{complete_label}}"
    anchor_command = "\\anchor{anchor-#{complete_label}}" # navigator_package
  end
  anchor_command_1 = ''
  anchor_command_2 = ''
  if section_level==0 then anchor_command_2=anchor_command else anchor_command_1=anchor_command end
  if is_prepress then toc_macro="toclinewithoutlink" else toc_macro="toclinewithlink" end
  # In the following, I had been using begingroup/endgroup to temporarily disable \addcontentsline,
  # but that had the side-effect of causing a \label{} that came after
  # begin_sec to have a null string as the label instead of the section number.
  # - 
  # similar code in begin_hw_sec
  # -
  t1 = <<-TEX
    \\let\\oldacl\\addcontentsline
    \\renewcommand{\\addcontentsline}[3]{}% temporarily disable \\addcontentsline
    TEX
  t2 = <<-TEX
    #{anchor_command_1}#{cmd}#{label_command}#{anchor_command_2}
    TEX
  t3 = <<-TEX
    \\let\\addcontentsline\\oldacl
    TEX
  if section_level<4 then
    if optional then toc_title = "$\\star$"+title else toc_title=title  end
    t4 = <<-TEX
      \\#{toc_macro}{#{name_level}}{#{complete_label}}{#{toc_title}}{\\the#{name_level}}
      TEX
  else
    t4 = ''
  end
  return mark_to_ignore_for_web(t1)+t2+mark_to_ignore_for_web(t3+t4)
end

def mark_to_ignore_for_web(tex)
  k = rand(1000000000000)
  return <<-TEX
    %begin_ignore_for_web:#{k}
    #{tex}
    %end_ignore_for_web:#{k}
  TEX
end

def is_prepress
  return ENV['PREPRESS']=='1'
end

# The following allows me to control what's titlecase and what's not, simply by changing book.config. Since text can be shared between books,
# and the same title may be a section in LM but a subsection in SN, this needs to be done on the fly.
# As of Dec. 2017, I've switched all books to not using titlecase anywhere. The source-code files now
# all have non-titlecase in all begin_secs. Some chapter titles still have titlecase in the source
# files, but that gets converted to non-titlecase here. We now throw a warning if alter_titlecase
# actually produces a change other than removing titlecase from a chapter title.
def alter_titlecase(title,section_level)
  result = title
  warn = false
  if section_level>=$config['titlecase_above'] then
    # don't warn or try to fix; this happens for any proper noun that isn't in the list
    # result = remove_titlecase(title) 
    # warn = (result != title) && section_level>0
  else
    result = add_titlecase(title)
    warn = (result != title)
  end
  if warn then $stderr.print "warning from alter_titlecase in eruby_util.rb: title #{title} appears to have the wrong case, was automatically fixed ch=#{$ch}\n" end
  return result
end

def add_titlecase(title)
  foo = title.clone
  # Examples:
  #   Current-conducting -> Current-Conducting
  foo.gsub!(/(?<![\w'"`{}\\$])(\w)/) {$1.upcase}              # Change every initial letter to uppercase. Handle Bob's, Schr\"odinger, Amp\`{e}re's
  [ 'a','the','and','or','if','for','of','on','by' ].each { |tiny| # Change specific short words back to lowercase.
    foo.gsub!(/(?<!\w)#{tiny}(?!\w)/i) {tiny} 
  }
  foo = initial_cap(foo)                            # Make sure initial word ends up capitalized.
  acronyms_and_symbols_uppercase(foo)               # E.g., FWHM.
  #if title != foo then $stderr.print "changing title from #{title} to #{foo}\n" end
  return foo  
end

$read_proper_nouns = false
$proper_nouns = {}
def proper_nouns
  if !$read_proper_nouns then
    json_file = whichever_file_exists(["../scripts/proper_nouns.json","scripts/proper_nouns.json"])
    json_data = ''
    File.open(json_file,'r') { |f| json_data = f.gets(nil) }
    if json_data == '' then $stderr.print "Error reading file #{json_file} in eruby_util.rb"; exit(-1) end
    $proper_nouns = JSON.parse(json_data)
    $read_proper_nouns = true
  end
  return $proper_nouns
end

def remove_titlecase(title)
  foo = title.clone
  foo = initial_cap(foo.downcase) # first letter is capital, everything after that lowercase
  # restore caps on proper nouns:
  proper_nouns()["noun"].each { |proper|
    foo.gsub!(/(?<!\w)#{Regexp::quote(proper)}/i) {|x| initial_cap(x)}
           # ... the negative lookbehind prevents, e.g., damped and example from becoming DAmped and ExAmple
           # If I had a word like "amplification" in a title, I'd need to special-case that below and change it back.
  }
  foo.gsub!(/or Machines/,"or machines") # LM 4.4 (Ernst Mach)
  foo.gsub!(/motion Machine/,"motion machine") # LM 10 (Ernst Mach)
  foo.gsub!(/simple Machines/,"simple machines") # LM 8.3 (Ernst Mach)
  foo.gsub!(/e=mc/,"E=mc") # LM 25
  foo.gsub!(/ke=/,"KE=") # Mechanics 12.4
  foo.gsub!(/k=/,"K=") # Mechanics 12.4; in case I switch from KE to K
  foo.gsub!(/l'h/,"L'H") # L'Hopital; software isn't smart enough to handle apostrophe and housetop accent
  foo.gsub!(/L'h/,"L'H")
  foo.gsub!(/ i /," I ")
  # logic above can't handle multi-word patterns
  proper_nouns()["multiword"].each { |proper| # e.g., proper="Big Bang"
    foo.gsub!(/#{Regexp::quote(proper.downcase)}/) {proper} 
  }
  acronyms_and_symbols_uppercase(foo) # e.g., FWHM
  #if title != foo then $stderr.print "changing title from #{title} to #{foo}\n" end
  return foo
end

def acronyms_and_symbols_uppercase(foo)
  # Acronyms and symbols that need to be uppercase no matter what:
  proper_nouns()["acronym"].each { |a| # e.g., a="FWHM"
    foo.gsub!(/(?<!\w)(#{Regexp::quote(a.downcase)})(?!\w)/) {$1.upcase}
  }
end

def initial_cap(x)
  # Note that we have some subsections like "2. The medium is not transported with the wave.", where the initial cap is not the first character.
  # These are handled correctly because it's sub(), not gsub(), so it just changes the first a-zA-Z character.
  # The A-Z case is the one where it's already got an initial cap (e.g., don't want to end up with "HEllo".
  return x.sub(/([a-zA-Z])/) {|x| x.upcase}
end

def end_chapter
  if $inside_hw_sec then
    fatal_error("begin_hw_sec not matched by any end_hw_sec before end_chapter")
  end
  $section_level -= 1
  if $section_level != -1 then
    $stderr.print "warning, at end_chapter, ch #{$ch}, section level at end of chapter is #{$section_level}, should be -1; probably begin_sec's and end_sec's are not properly balanced (happens in NP preface)\n"
  end
  $hw_names_referred_to.each { |name|
    $stderr.print "hwref:#{name}\n"
  }
  File.open("ch#{$ch}_problems.csv",'w') { |f|
    # book,ch,num,name
    book = ENV['BK']
    chnum = strip_leading_zero_from_ch($ch)
    if $ch=='002' then chnum=0 end
    1.upto($hw_number) { |i| # output doesn't always get sorted correctly; see fund/solns/prep_solutions for perl code that sorts it correctly
      name = $hw[i]
      f.print "#{book},#{chnum},#{$store_hw_label[i]},#{name},#{$hw_has_solution[i]?'1':'0'}\n"
    }
  }
  mv = whichever_file_exists(['mv_silent','../mv_silent'])
  print "\n\\write18{#{mv} all.pos ch#{$ch}.pos}\n"
end

def whichever_file_exists(files)
  files.each {|f|
    if File.exist?(f) then return f end
  }
  $stderr.print "Error in eruby_util.rb, whichever_file_exists(#{files.join(',')}): none of these files exist. Current working dir is #{Dir.pwd}\n"
  return nil
end

def code_listing(filename,code)
  print code  
  $n_code_listing = $n_code_listing+1
  File.open("code_listing_ch#{$ch}_#{$n_code_listing}_#{filename}",'w') { |f|
    f.print code
  }
end

def chapter(number,title,label,caption='',options={})
  default_options = {
    'opener'=>'',
    'anonymous'=>'default',# true means figure has no figure number, but still gets labeled (which is, e.g., necessary for photo credits)
                           # default is false, except if caption is a null string, in which case it defaults to true
    'width'=>'wide',       # 'wide'=113 mm, 'fullpage'=171 mm
                           #   refers to graphic, not graphic plus caption (which is greater for sidecaption option)
    'sidecaption'=>false,
    'special_width'=>nil,  # used in CL4, to let part of the figure hang out into the margin
    'short_title'=>nil,      # used in TOC; if omitted, taken from title
    'very_short_title'=>nil,  # used in running headers; if omitted, taken from short_title
    'optional'=>false
  }
  insert_into_chapter_title_list(number.to_i,label,title)
  $section_level += 1
  $ch = number
  $label_counter = 0
  default_options.each { 
    |option,default|
    if options[option]==nil then
      options[option]=default
    end
  }
  if options['short_title']==nil then options['short_title']=title end
  if options['very_short_title']==nil then options['very_short_title']=options['short_title'] end
  opener = options['opener']
  if opener!='' then
    if !figure_exists_in_my_own_dir?(opener) then
      # bug: doesn't support \figprefix
      # ! LaTeX Error: File `ch02/figs/../9share/mechanics/figs/pool' not found.
      s = shared_figs()
      dir = s[0]
      unless (File.exist?("#{dir}/#{opener}.pdf") or File.exist?("#{dir}/#{opener}.jpg") or File.exist?("#{dir}/#{opener}.png")) then
        dir = s[1]
      end
      options['opener']="../../#{dir}/#{opener}"
    end
    if options['anonymous']=='default' then
      options['anonymous']=(caption=='')
    end
  end
  title = alter_titlecase(title,0)
  if is_print then chapter_print(number,title,label,caption,options) end
  if is_web   then   chapter_web(number,title,label,caption,options) end
end

def chapter_web(number,raw_title,label,caption,options)
  if options['optional'] then title="* "+raw_title else title=raw_title  end
  if options['opener']!='' then
    process_fig_web(options['opener'],caption,options)
  end
  print "\\mychapter{#{title}}\n"
end

def chapter_print(number,raw_title,label,caption,options)
  if options['optional'] then title = "$\\star$"+raw_title else title=raw_title end
  opener = options['opener']
  has_opener = (opener!='')
  result = nil
  bare_label = label.clone.gsub!(/ch:/,'')
  #$stderr.print "in chapter_print, bare_label=#{bare_label}\n"
  append = ''
  #append = "\\anchor{anchor-#{label}}" # navigator package
  File.open('brief-toc-new.tex','a') { |f|
    # LM and Me. don't use brief-toc-new.tex
    if is_prepress
      f.print "\\brieftocentry{#{label}}{#{title}} \\\\\n" 
    else
      f.print "\\brieftocentrywithlink{#{label}}{#{title}} \\\\\n" 
    end
  }
  if !has_opener then
    result = "\\mychapter{#{options['short_title']}}{#{options['very_short_title']}}{#{title}}#{append}"
  else
    opener=~/([^\/]+)$/     # opener could be, e.g., ../../../9share/optics/figs/crepuscular-rays
    opener_label = $1
    ol = "\\label{fig:#{opener_label}}" # needs label for figure credits, and TeX isn't smart enough to handle cases where it's got ../.., etc. on the front
                            # not strictly correct, because label refers to chapter, but we only care about page number for photo credits
    if options['width']=='wide' then
      if caption!='' then
        if !options['sidecaption'] then
          if options['special_width']==nil then
            result = "\\mychapterwithopener{#{opener}}{#{caption}}{#{title}}#{ol}#{append}"
          else
            result = "\\specialchapterwithopener{#{options['special_width']}}{#{opener}}{#{caption}}{#{title}}#{ol}#{append}"
          end
        else
          if options['anonymous'] then
            result = "\\mychapterwithopenersidecaptionanon{#{opener}}{#{caption}}{#{title}}#{ol}#{append}"
          else
            result = "\\mychapterwithopenersidecaption{#{opener}}{#{caption}}{#{title}}#{ol}#{append}"
          end
        end
      else
        result = "\\mychapterwithopenernocaption{#{opener}}{#{title}}#{ol}#{append}"
      end
    else
      if options['anonymous'] then
        if caption!='' then
          result = "\\mychapterwithfullpagewidthopener{#{opener}}{#{caption}}{#{title}}#{ol}#{append}"
        else
          result = "\\mychapterwithfullpagewidthopenernocaption{#{opener}}{#{title}}#{ol}#{append}"
        end
      else
        $stderr.print "********************************* ch #{ch}full page width chapter openers are only supported as anonymous figures ************************************\n"
        exit(-1)
      end
    end
  end
  if result=='' then
    $stderr.print "**************************************** Error, ch #{$ch}, processing chapter header. ****************************************\n"
    exit(-1)
  end
  print sectioning_command_with_href(result,0,bare_label,'ch',raw_title,options['optional'])
  #print "#{result}\\label{#{label}}\n"
end

def insert_into_chapter_title_list(number,label,title)
  file = "chapters.json"
  data = []
  if FileTest.exist?(file) then
    json_data = ''
    File.open(file,'r') { |f| json_data = f.gets(nil) }
    if json_data == '' then $stderr.print "Error reading file #{file} in eruby_util.rb"; exit(-1) end
    data = JSON.parse(json_data)
  end
  data[number] = {'label'=>label.sub(/ch:/,''),'title'=>title}
  File.open(file,'w') { |f| f.print JSON.pretty_generate(data) }
end

$photo_credits = []

def photo_credit(label,description,credit)
  $photo_credits.push([label,description,credit,'normal'])
end

def toc_photo_credit(description,credit)
  $photo_credits.push(['',description,credit,'contents'])
end

def cover_photo_credit(description,credit)
  $photo_credits.push(['',description,credit,'cover'])
end

# normally returns real page number; returns 1 for cover, 2 for contents
def pagenum_of_credit(credit)
  label = credit[0]
  type = credit[3]
  if type=='cover' then return 1 end
  if type=='contents' then return 2 end
  if label == '' then return 0 end # shouldn't actually happen
  l = 'fig:'+label
  if $ref[l]==nil then return 0 else return $ref[l][1] end
end

def print_photo_credits
  $photo_credits.sort{ |a,b| pagenum_of_credit(a) <=> pagenum_of_credit(b) }.each { |c|
    label = c[0]
    description = c[1]
    credit = c[2]
    type = c[3]
    if type=='normal' then
      print "\\cred{#{label}}{#{description}}{#{credit}}\n"
    end
    if type=='contents' then
      print "\\docred{Contents}{#{description}}{#{credit}}\n"
    end
    if type=='cover' then
      print "\\docred{Cover}{#{description}}{#{credit}}\n"
    end
  }
end
