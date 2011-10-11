module DeliciousGetter
  module Helpers

    def url_to_slug(url)
      url = url.sub(/http:\/\//, "")
      url = url.gsub(/[\/?&=]/, "_")
      url
    end

    def file_for(url)
      "cache/" + url_to_slug(url)
    end

  end
end


# re: http://stackoverflow.com/questions/930742/segmentation-fault-in-hpricot
# https://github.com/rgrove/sanitize/blob/1e1dc9681de99e32dc166f591343dfa60fc1f648/lib/sanitize/monkeypatch/hpricot.rb
module Hpricot

  # Monkeypatch to fix an Hpricot bug that causes HTML entities to be decoded
  # incorrectly.
  def self.uxs(str)
    str.to_s.
      gsub(/&(\w+);/) { [Hpricot::NamedCharacters[$1] || ??].pack("U*") }.
      gsub(/\&\#(\d+);/) { [$1.to_i].pack("U*") }
  end

end
