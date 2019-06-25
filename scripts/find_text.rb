#!/usr/bin/ruby

s = ARGV[0]

if s.nil? || s=='' then $stderr.print "please supply a search string (optionally quoted) on the command line" end

if s=~/\A"(.*)"\Z/ then s=$1 end
if s=~/\A'(.*)'\Z/ then s=$1 end

scripts_dir = File.dirname(__FILE__)
main_dir = File.expand_path("..",scripts_dir)
Dir.glob("#{main_dir}/*/*/*tex").concat(Dir.glob("#{main_dir}/*/*/*/*tex")).each {|tex|
  unless tex=~/temp\.tex\Z/ then
    File.open(tex,'r') { |f|
      t = f.gets(nil) # slurp whole file
      if t=~/((.*)#{Regexp::quote(s)}(.*))/ then
        print tex,"\n","  #{$1}\n"
      end
    }
  end
}
