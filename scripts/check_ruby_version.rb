#!/usr/bin/ruby

begin
  Regexp.new("(?<=foo)bar")
rescue Exception => exc
  puts <<BARF
  The version of ruby you're running is too old. Please upgrade to at least ruby 1.9.
  To see what version you're running, do ruby --version. You may have more than one
  version installed, e.g., /usr/bin/ruby may be a symlink to /usr/bin/ruby1.8 , when 
  /usr/bin/ruby1.9.1 also exists.
BARF
  exit(-1)
end
