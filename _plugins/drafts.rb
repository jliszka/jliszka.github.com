module Jekyll

  class DraftPage < Draft
    def html?
      return false
    end
    def uses_relative_permalinks
      return false
    end
    def template
      "drafts/:basename.html"
    end
    def date
      return Date.new()
    end
  end

  class DraftGenerator < Generator
    safe true

    def generate(site)
      entries = Dir.chdir("_drafts") { Dir["*.md"] }
      entries.each do |entry|
        site.pages << DraftPage.new(site, site.source, "_drafts", entry)
      end
    end
  end
end
