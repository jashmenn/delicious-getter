$:.unshift(File.dirname(__FILE__))
require 'trollop'
require 'open-uri'
require 'magic_xml'
require 'andand'
require 'fileutils'
#require 'forkoff'
require 'delicious_getter/helpers'

# Installation:
#
#     gem install hpricot andand magic_xml trollop forkoff
#
# Get your delicious bookmark backup with:
#
#     curl -k --user my_user_name:my_password -o backup.xml -O 'https://api.del.icio.us/v1/posts/all'

opts = Trollop::options do
  version "Nate Murray 2010"
  banner <<-EOS
Download the files in your delicious backup.xml

Example:

    ruby #{$0} --snapshot --tag kickstarter ~/programming/dotfiles/delicious/pinboard-backup.xml 

Usage:
       #{$0} [options] <backup.xml>
where [options] are:
EOS
  opt :snapshot, "take a snapshot"
  opt :tag, "only look at urls which match a tag", :type => String
  opt :threads, "number of threads", :type => Integer, :default => 1
end

filename = ARGV[0]

include DeliciousGetter::Helpers

def download(url)
  FileUtils.mkdir "cache" unless File.exists?("cache")
  filename = "cache/" + url_to_slug(url)
  return if File.exists?(filename)
  $stderr.puts "Downloading #{url}"
  begin
  File.open(filename, "w") do |f| 
    open(url) do |u|
      f.print u.read
    end
  end
  rescue Exception => e
    $stderr.puts "Error downloading: #{url}"
    $stderr.puts e.to_s
    FileUtils.rm_f filename
  end
end

def snapshot(url)
  FileUtils.mkdir "cache" unless File.exists?("cache")
  filename = "cache/" + url_to_slug(url)
  return if File.exists?(filename)
  $stderr.puts "Snapshot #{url}"
  cmd = "phantomjs lib/delicious_getter/javascript/rasterize.js #{url} #{filename}.pdf Letter"
  begin
    puts cmd
    `#{cmd}`
  rescue Exception => e
    puts "error downloading #{url}. cmd:"
    puts cmd
    puts e
  end
end

urls = []
XML.parse_as_twigs(File.new(filename)) do |node|
 next unless node.name == :post
 node.complete!
 if opts[:tag]
   urls << node[:href] if node[:tag] =~ /\b#{opts[:tag]}\b/
 else
   urls << node[:href]
 end
end

#urls.forkoff! :processes => opts[:threads] do |url|
urls.each do |url|
  if opts[:snapshot]
    snapshot url
  else
    download url
  end
end


