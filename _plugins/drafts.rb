module Jekyll

  class DraftPage < Draft
    def html?
      return false
    end
    def uses_relative_permalinks
      return false
    end
    def template
      "drafts/:title.html"
    end
  end

  class DraftGenerator < Generator
    safe true

    def generate(site)
      entries = Dir.chdir("_drafts") { Dir["*.md"] }
      entries.each do |entry|
        site.pages << DraftPage.new(site, site.source, "", entry)
      end
    end
  end
end
