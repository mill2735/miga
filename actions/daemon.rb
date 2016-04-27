#!/usr/bin/env ruby

# @package MiGA
# @license Artistic-2.0

require "miga/daemon"

task = ARGV.shift unless ["-h","--help"].include? ARGV.first
ARGV << "-h" if ARGV.empty?
o = {q:true, daemon_opts:[]}
OptionParser.new do |opt|
   opt.banner = <<BAN
Controls the daemon of a MiGA project.

Usage: #{$0} #{File.basename(__FILE__)} {task} [options]
BAN
   opt.separator "task:"
   {  start:  "Start an instance of the application.",
      stop:    "Start an instance of the application.",
      restart: "Stop all instances and restart them afterwards.",
      reload:  "Send a SIGHUP to all instances of the application.",
      run:     "Start the application and stay on top.",
      zap:     "Set the application to a stopped state.",
      status:  "Show status (PID) of application instances."
   }.each{ |k,v| opt.separator sprintf "    %*s%s", -33, k, v }
   opt.separator ""
   opt.separator "MiGA options:"
   opt.on("-P", "--project PATH",
      "(Mandatory) Path to the project to use."){ |v| o[:project]=v }
   opt.on("--latency INT",
      "Number of seconds the daemon will be sleeping."
      ){ |v| o[:latency]=v.to_i }
   opt.on("--max-jobs INT",
      "Maximum number of jobs to use simultaneously."){ |v| o[:maxjobs]=v.to_i }
   opt.on("--ppn INT",
      "Maximum number of cores to use in a single job."){ |v| o[:ppn]=v.to_i }
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
   opt.separator "Daemon options:"
   opt.on("-t", "--ontop",
      "Stay on top (does not daemonize)"){ o[:daemon_opts] << '-t' }
   opt.on("-f", "--force", "Force operation"){ o[:daemon_opts] << '-f' }
   opt.on("-n", "--no_wait",
      "Do not wait for processes to stop"){ o[:daemon_opts] << '-n' }
end.parse!

### MAIN
raise "Project is mandatory." if o[:project].nil?

raise "Project doesn't exist, aborting." unless
   MiGA::Project.exist? o[:project]
p = MiGA::Project.new(o[:project])
d = MiGA::Daemon.new(p)
[:latency, :maxjobs, :ppn].each do |k|
   d.runopts(k, o[k]) unless o[k].nil?
end
d.daemon(task, o[:daemon_opts])
