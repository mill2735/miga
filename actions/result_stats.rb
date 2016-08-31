#!/usr/bin/env ruby

# @package MiGA
# @license Artistic-2.0

o = {q:true}
opts = OptionParser.new do |opt|
  opt_banner(opt)
  opt_object(opt, o, [:project, :dataset_opt, :result])
  opt.on("--compute-and-save",
    "Computes and saves the statistics."){ |v| o[:compute] = v }
  opt_common(opt, o)
end.parse!

##=> Main <=
opts.parse!
opt_require(o, project:"-P", name:"-r")

$stderr.puts "Loading project." unless o[:q]
p = MiGA::Project.load(o[:project])
raise "Impossible to load project: #{o[:project]}" if p.nil?

$stderr.puts "Loading result." unless o[:q]
if o[:dataset].nil?
  r = p.add_result(o[:name], false)
else
  d = p.dataset(o[:dataset])
  r = d.add_result(o[:name], false)
end
raise "Cannot load result." if r.nil?

if o[:compute]
  $stderr.puts "Computing statistics." unless o[:q]
  stats = {}
  case o[:name]
  when :raw_reads
    scr = "awk 'NR%4==2{L+=length($0)} END{print NR/4, L*4/NR}'"
    if r[:files][:pair1].nil?
      s = `#{scr} '#{r.file_path :single}'`.chomp.split(" ")
      stats = {reads: s[0].to_i, average_length: [s[1].to_f, "bp"]}
    else
      s1 = `#{scr} '#{r.file_path :pair1}'`.chomp.split(" ")
      s2 = `#{scr} '#{r.file_path :pair2}'`.chomp.split(" ")
      stats = {read_pairs: s1[0].to_i,
        average_length_forward: [s1[1].to_f, "bp"],
        average_length_reverse: [s2[1].to_f, "bp"]}
    end
  when :trimmed_fasta
    scr = "awk '{L+=$2} END{print NR, L/NR}'"
    f = r[:files][:coupled].nil? ? r.file_path(:single) : r.file_path(:coupled)
    s = `FastA.length.pl '#{f}' | #{scr}`.chomp.split(" ")
    stats = {reads: s[0].to_i, average_length: [s[1].to_f, "bp"]}
  when :assembly
    f = r.file_path :largecontigs
    s = `FastA.N50.pl '#{f}'`.chomp.split("\n").map{|i| i.gsub(/.*: /,'').to_i}
    stats = {contigs: s[1], n50: [s[0], "bp"], total_length: [s[2], "bp"]}
  when :cds
    scr = "awk '{L+=$2} END{print NR, L/NR}'"
    f = r.file_path :proteins
    s = `FastA.length.pl '#{f}' | #{scr}`.chomp.split(" ")
    stats = {predicted_proteins: s[0].to_i, average_length: [s[1].to_f, "aa"]}
  else
    stats = nil
  end
  unless stats.nil?
    r[:stats] = stats
    r.save
  end
end

r[:stats].each do |k,v|
  puts "#{k.to_s.unmiga_name.capitalize}: #{v.is_a?(Array) ? v.join(" ") : v}."
end

$stderr.puts "Done." unless o[:q]