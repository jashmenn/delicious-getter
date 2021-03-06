$:.unshift(File.dirname(__FILE__))
require 'trollop'
require 'open-uri'
require 'forkoff'
require 'hpricot'
require 'delicious_getter/helpers'
require 'magic_xml'
require 'andand'
require 'fileutils'

opts = Trollop::options do
  version "Nate Murray 2010"
  banner <<-EOS
Extracts labeled content from your backup.xml and the downloaded files in cache

Usage:
       #{$0} [options] <backup.xml> <kea-folder>
where [options] are:
EOS

end

filename,out_folder = ARGV[0],ARGV[1]

include DeliciousGetter::Helpers

posts = []
XML.parse_as_twigs(File.new(filename)) do |node|
 next unless node.name == :post
 node.complete!
 posts << [node[:href], node[:tag]]
end

[out_folder, out_folder + "/test/manual_keyphrases", out_folder + "/train"].each do |f| 
  FileUtils.mkdir_p(f) unless File.exists?(f)
end

posts.each_with_index do |post,i|
  url, tags = post[0], post[1]
  if i % 100 == 0
    $stderr.puts("%d/%d" % [i, posts.size])
  end

  begin
    if File.exists?(file_for(url))
      # html = Hpricot.parse(IO.read(file_for(url)))

      hpricot = Hpricot(IO.read(file_for(url)))
      hpricot.search("script").remove
      hpricot.search("link").remove
      hpricot.search("meta").remove
      hpricot.search("style").remove

      text = hpricot.inner_text
      text.gsub!(/[^a-zA-Z1-9\s]/, " ") # remove all non- letter/number/space 
      text.gsub!(/\b\d+\b/, "") # remove all numeric tokens
      # text = text.gsub(/&nbsp;/, " ") # todo, maybe use htmlentities
      text = text.gsub(/\s+/m, " ").strip
      text = text.downcase
      # todo, this is far from perfect, the nbsp's get expanded to something non-ascii and make a *bunch* of words squeezed together. that said, it is fine for now
      next unless tags.length > 0
      next unless text.length > 0

      raise "bad news - there are tabs in the content" if tags =~ /\t/ || text =~ /\t/
      # puts "%s\t%s" % [tags.andand.downcase, text]
      fprefix = out_folder + "/train/#{url_to_slug(url)}"
      File.open(fprefix + ".txt",  "w") { |f| f.puts text}
      File.open(fprefix + ".tags", "w") { |f| tags.split(/\s+/).each {|tag| f.puts tag.upcase}}
    end
  rescue NoMethodError => e 
    $stderr.puts "Error on #{file_for(url)}"
    # $stderr.puts "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
    $stderr.puts "Exception: #{e.class}: #{e.message}}"
  end

end

