#!/usr/bin/ruby

# harvest_aux.rb data_dir

$data_dir = ARGV[0]

$big_problems_csv = "#{$data_dir}/problems.csv"

# returns [contents,nil] normally [nil,error message] otherwise
def slurp_file_with_detailed_error_reporting(file)
  begin
    File.open(file,'r') { |f|
      t = f.gets(nil) # nil means read whole file
      if t.nil? then t='' end # gets returns nil at EOF, which means it returns nil if file is empty
      return [t,nil]
    }
  rescue
    return [nil,"Error opening file #{file} for input, cwd=#{Dir.pwd}: #{$!}."]
  end
end

# returns contents or nil on error; for more detailed error reporting, see slurp_file_with_detailed_error_reporting()
def slurp_file(file)
  x = slurp_file_with_detailed_error_reporting(file)
  return x[0]
end

# Here we're using data from other books, which have this info embedded in eruby.
def get_problems_data(problems_csv) # used in order to determine which problems have publicly available solutions
  # return value is a hash like {"mg-to-kg"=>true,...}
  # lm,0,1,calculator,0
  # book,chapter,number,label,solution
  result = {}
  csv = slurp_file(problems_csv)
  csv.split(/\n/).each { |line|
    if line=~/\A([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)\Z/ then
      book,chapter,number,label,solution = [$1,$2.to_i,$3,$4,$5]     
      if solution!='' then
        result[label] = solution.to_i
      end
    else
      fatal_error("can't parse this line in #{infile}: #{line}")
    end
  }
  return result
end

solutions = get_problems_data($big_problems_csv)
if File.exist?("own_problems_solns.csv") then
  solutions.merge!(get_problems_data("own_problems_solns.csv"))
end

problems = []
File.readlines('problems.aux').each { |line|
  # \newlabel{hw:martini}{{1-j4}{8}}
  if line=~/\\newlabel{hw:([^}]+)}{{(\d+)-([^}]+)}{.*}}/ then
    label,chapter,number = $1,$2,$3
    solution = '0'
    if solutions.key?(label) then solution=solutions[label] end
    problems.push("problems,#{chapter},#{number},#{label},#{solution}\n")
  end
}

File.open('problems.csv','w') { |f|
  problems.each { |line| f.print line }
}
