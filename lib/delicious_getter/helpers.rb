module DeliciousGetter
  module Helpers

    def url_to_slug(url)
      url = url.sub(/http:\/\//, "")
      url = url.gsub(/[\/?&]/, "_")
      url
    end

    def file_for(url)
      "cache/" + url_to_slug(url)
    end

  end
end
