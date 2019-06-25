#!/usr/bin/ruby

$tex_points_to_mm = (25.4)/(65536.*72.27)

# If the interval (a,b) overlaps the interval (c,d) then return the amount by which they overlap.
# Otherwise return false.
def overlap(a,b,c,d)
  if a>c then return overlap(c,d,a,b) end
  # ab should lie strictly underneath cd
  if b<c then return false end
  return b-c
end

def mm(x)
  return sprintf((x+0.5).to_i.to_s,"%d")
end

found_some = false
Dir["*.pos"].each { |filename|
  found_some = true
  filename=~/(.*)\.pos/
  ch = $1 # interpret as string, not integer, e.g., in NP 001 is not the same as 01
  #print "ch. #{ch}\n"
  lo_y = {}
  hi_y = {}
  lo_x = {}
  hi_x = {}
  page = {}
  index_by_page = []
  File.open(filename,'r') do |f|
    f.each_line { |line|
      if line=~/^fig,label=fig:(.*),page=(.*),x=(.*),y=(.*),at=(.*)/ then
        fig,pg,x,y = $1,$2.to_i,$3.to_i,$4.to_i
        x = x*$tex_points_to_mm
        y = y*$tex_points_to_mm
        if page.has_key?(fig) then
          if page[fig]!=pg then print "figure #{fig} occurs on both page #{page[fig]} and page #{pg} -- maybe the second one needs a suffix\n" end
          if x<lo_x[fig] then lo_x[fig]=x end
          if x>hi_x[fig] then hi_x[fig]=x end
          if y<lo_y[fig] then lo_y[fig]=y end
          if y>hi_y[fig] then hi_y[fig]=y end
        else
          page[fig]=pg
          lo_x[fig]=x
          hi_x[fig]=x
          lo_y[fig]=y
          hi_y[fig]=y
        end
        if index_by_page[pg]==nil then
          index_by_page[pg] = {fig=>'1'}
        else
          index_by_page[pg][fig] = 1
        end
      end
    }
    index_by_page.each_index { |pg|
      figs = index_by_page[pg]
      if figs!=nil then
        figs.keys.each { |f|
          figs.keys.each { |g|
            if f<g and overlap(lo_y[f],hi_y[f],lo_y[g],hi_y[g]) and overlap(lo_x[f],hi_x[f],lo_x[g],hi_x[g]) then
              print "***** colliding figs, ch. #{ch}, p. #{pg}, #{f} and #{g}, overlapping by #{mm(overlap(lo_x[f],hi_x[f],lo_x[g],hi_x[g]))} mm horiz, #{mm(overlap(lo_y[f],hi_y[f],lo_y[g],hi_y[g]))} mm vert\n"
              #print "    #{f} extends from #{mm(lo_y[f])} to #{mm(hi_y[f])} mm, #{g} from #{mm(lo_y[g])} to #{mm(hi_y[g])} mm \n"
            end
          }
        }
      end
    }  
  end
}

if !found_some then
  print "no .pos files found\n"
end
