#!/usr/bin/env ruby

require "#{Dir.pwd}/app/models/work.rb"

def do_usage()
  puts "Usage: alto_doc [flags] server /path/to/directory"
  puts "Import all pages in the given document directory into specified TypeWright server."
  puts "Pages must be in ALTO format."
  puts "If the book does not exist, issue error."
  puts " -v  Verbose output"
  puts " -t  Test only -- don't actually upload files"
end

# start by reading our input parameters

VALID_OPTION_FLAGS = %w( v t )
VALID_OPTIONS = %w( )

if ARGV.size < 2
  do_usage()
  exit(1)
end

server = ''
directory = ''
option_flags = []
options = {}

ARGV.each do |arg|
  if arg[0..0] == '-'  # if I don't do [0..0] I get an int rather than a string
    if arg =~ /=/
      arg_name = arg[1..99].split("=")[0]
      if VALID_OPTIONS.index(arg_name) == nil
        puts "WARNING: Ignoring unknown parameter: #{arg_name} (#{arg})"
      else
        options[arg_name] = arg[arg_name.size+2..999]
      end
    else
      arg_name = arg[1..99]
      if VALID_OPTION_FLAGS.index(arg_name) == nil
        puts "WARNING: Ignoring unknown parameter: #{arg}"
      else
        option_flags << arg_name
      end
    end
  elsif server.empty?
    server = arg
  elsif directory.empty?
    directory = arg
  else
    puts "WARNING: Ignoring unknown parameter: #{arg}"
  end
end

verbose_output = !option_flags.index('v').nil?
test_only = !option_flags.index('t').nil?
cmd_flags = "#{verbose_output ? '-v':''} #{test_only ? '-t':''}"

# attempt to find batch directories...
original_dir = Dir.pwd
Dir.chdir(directory)
dir_list = []
Dir.glob("*") { |f|
  dir_list << f if File.directory?( f )
}

# find the maximum batch number in the directory
max_batch = 0
dir_list.each { |dir|
  max_batch = dir.to_i if dir.to_i > max_batch
}

# if we did not find a batch directory, assume it was already supplied as a parameter
if max_batch == 0
   max_batch = File.basename( directory )
   directory = File.dirname( directory )
else
  # we found a batch directory, move to it
  Dir.chdir( max_batch.to_s)
end

page_list = []
Dir.glob("*") { |f|
  page_list << f if f.end_with?( "_ALTO.XML", "_alto.xml", "_ALTO.xml", "_alto.XML" )
}

Dir.chdir(original_dir)

if page_list.empty?
  puts "WARNING: no alto pages located here #{directory}"
  exit( 1 )
end

# resolve the eMOP work Id to an ecco Id
work_id = File.basename( directory )
ecco_id = Work.getEccoNumber( work_id )

if ecco_id.nil?
  puts "WARNING: cannot locate document ECCO identifier"
  exit( 1 )
end

# process each page we have identified
page_list.sort!
page_list.each { |page|

   xml_file = File.join("#{max_batch}", "#{page}")
   cmd = "script/import/alto_page #{cmd_flags} #{server} #{File.join(directory,xml_file)} #{ecco_id}"
   puts "" if verbose_output
   puts "" if verbose_output
   puts cmd
   result = `#{cmd}`
   puts result
}

exit 0