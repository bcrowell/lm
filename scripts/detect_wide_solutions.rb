#!/usr/bin/ruby

# Run this from my home directory. Detects the relatively small number of
# figures I have in solutions that are wider than one column.
# Output is suitable for cutting and pasting into data/fig_widths_by_hand.

def tell_me(file,pixels,resolution)
  mm = (pixels.to_f/resolution.to_f)*(25.4)
  if mm>86 then
    # "jovian-moons":"wide"
    b = File.basename(file,".*")
    print "\"#{b}\":\"wide\",\n"
  end
end

Dir.glob("Documents/teaching/solns/*/figs/*.{jpg,png}").sort.each { |jpg|
  if `identify -format \"%w,%x\" #{jpg}`=~/\A(\d+),(\d+)/ then
    # produces output like this: 398,72 Undefined
    # note that this gives wrong results for pdf files
    tell_me(jpg,$1,$2)
  end
}

Dir.glob("Documents/teaching/solns/*/figs/*.svg").sort.each { |svg|
  if `inkscape --query-width #{svg} 2>/dev/null`=~/\A(\d+)/ then
    tell_me(svg,$1,90.0)
  end
}
