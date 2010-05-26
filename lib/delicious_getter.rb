require 'trollop'
require 'open-uri'
require 'forkoff'
require 'delicious_getter/helpers'

# Installation:
#
#     gem install magic_xml trollop forkoff
#
# Get your delicious bookmark backup with:
#
#     curl -k --user `my_user_name:my_password` -o backup.xml -O 'https://api.del.icio.us/v1/posts/all'

opts = Trollop::options do
  version "Nate Murray 2010"
  banner <<-EOS
Download the files in your delicious backup.xml

Usage:
       #{$0} [options] <backup.xml>
where [options] are:
EOS

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

urls = []
XML.parse_as_twigs(File.new(filename)) do |node|
 next unless node.name == :post
 node.complete!
 urls << node[:href]
end

urls.forkoff! :processes => 4 do |url|
  download url
end

