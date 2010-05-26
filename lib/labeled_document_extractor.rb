$:.unshift(File.dirname(__FILE__))
require 'trollop'
require 'open-uri'
require 'forkoff'
require 'hpricot'
require 'delicious_getter/helpers'

opts = Trollop::options do
  version "Nate Murray 2010"
  banner <<-EOS
Extracts labeled content from your backup.xml and the downloaded files in cache

Usage:
       #{$0} [options] <backup.xml>
where [options] are:
EOS

end

filename = ARGV[0]

include DeliciousGetter::Helpers

posts = []
XML.parse_as_twigs(File.new(filename)) do |node|
 next unless node.name == :post
 node.complete!
 posts << [node[:href], node[:tag]]
end

posts.each do |post|
  url, tags = post[0], post[1]

  if File.exists?(file_for(url))
    html = Hpricot.parse(IO.read(file_for(url)))
    text = html.inner_text.gsub(/\s+/m, " ").strip
    raise "bad news" if tags =~ /\t/ || text =~ /\t/
    puts "%s\t%s" % [tags, text]
  end
end

