#!/usr/bin/env ruby

# @package MiGA
# @license Artistic-2.0

o = {q:true, info:false, force:false, method: :hardlink }
OptionParser.new do |opt|
   opt.banner = <<BAN
Link datasets (including results) from one project to another.

Usage: #{$0} #{File.basename(__FILE__)} [options]
BAN
   opt.separator ""
   opt.on("-P", "--project-source PATH",
      "(Mandatory) Path to the project that contains the dataset."
      ){ |v| o[:project1]=v }
   opt.on("-Q", "--project-target PATH",
      "(Mandatory) Path to the project where to link the dataset."
      ){ |v| o[:project2]=v }
   opt.on("-D", "--dataset STRING",
      "ID of the dataset to link."){ |v| o[:dataset]=v.miga_name }
   opt.on("-f", "--force",
      "Forces linking, even if dataset's preprocessing is incomplete."
      ){ |v| o[:force]=v }
   opt.on("-s", "--symlink",
      "Creates symlinks instead of the default hard links."
      ){ o[:method] = :symlink }
   opt.on("-c", "--copy",
      "Creates copies instead of the default hard links."){ o[:method] = :copy }
   opt.on("--[no-]ref",
      "If set, links only reference (or only non-reference) datasets."
      ){ |v| o[:ref]=v }
   opt.on("--[no-]multi",
      "If set, links only multi-species (or only single-species) datasets."
      ){ |v| o[:multi]=v }
   opt.on("-t", "--taxonomy RANK:TAXON",
      "Filter by taxonomy."){ |v| o[:taxonomy]=MiGA::Taxonomy.new v }
   opt.on("-v", "--verbose",
      "Print additional information to STDERR."){ o[:q]=false }
   opt.on("-d", "--debug INT", "Print debugging information to STDERR.") do |v|
      v.to_i>1 ? MiGA::MiGA.DEBUG_TRACE_ON : MiGA::MiGA.DEBUG_ON
   end
   opt.on("-h", "--help", "Display this screen.") do
      puts opt
      exit
   end
   opt.separator ""
end.parse!


### MAIN
raise "-P is mandatory." if o[:project1].nil?
raise "-Q is mandatory." if o[:project2].nil?

$stderr.puts "Loading project." unless o[:q]
p = MiGA::Project.load(o[:project1])
raise "Impossible to load project: #{o[:project1]}" if p.nil?
q = MiGA::Project.load(o[:project2])
raise "Impossible to load project: #{o[:project2]}" if q.nil?

$stderr.puts "Listing dataset." unless o[:q]
if o[:dataset].nil?
   ds = p.datasets
else
   ds = [p.dataset(o[:dataset])]
end
ds.select!{|d| d.name == o[:dataset]} unless o[:dataset].nil?
ds.select!{|d| d.is_ref? == o[:ref] } unless o[:ref].nil?
ds.select! do |d|
   (not d.metadata[:type].nil?) and
      (MiGA::Dataset.KNOWN_TYPES[d.metadata[:type]][:multi] == o[:multi])
end unless o[:multi].nil?
ds.select! do |d|
   (not d.metadata[:tax].nil?) and d.metadata[:tax].is_in?(o[:taxonomy])
end unless o[:taxonomy].nil?
ds.each do |d|
   next unless o[:force] or d.done_preprocessing?
   puts d.name
   q.import_dataset(d, o[:method])
end

$stderr.puts "Done." unless o[:q]
