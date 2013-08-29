#
# Author: Brett Terpstra
# Page generator for /data/tags.json, a list of all the tags on your blog and a list of the top 50 tags.
# Part of the AutoTag tool for Jekyll, but usable in other applications
#
# Looks for a tags_json.html template in your _layouts folder, see the example provided.
# Provides page.json_tags and page.json_tags_count as arrays for looping
#
# Config options for _config.yml
# tag_excludes: array of tags to exclude from all listings
# tags_json_dir: alternate of folder for the data.json file. Set to blank for root, defaults to 'data'
#
# If using tags.json with a javascript application, be sure you have the proper headers defined in .htaccess:
# AddType application/json               json
# ExpiresByType application/json         "access plus 0 seconds"

require 'json'

module Jekyll

  class AutoTag < Page
    def initialize(site, base, dir)
      @site = site
      @base = base
      @dir = dir
      @name = 'tags.json'
      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tags_json.html')
      tags_with_counts = site.tags.delete_if {|k,v|
        site.config['tag_excludes'].include?(k) unless site.config['tag_excludes'].nil?
      }.sort_by { |k,v| v.count }.reverse

      self.data['json_tags'] = tags_with_counts.sort {|a,b| a[0].downcase <=> b[0].downcase }.map {|k,v| k }
      self.data['json_tags_count'] = []
      tags_with_counts.each { |k,v|
        self.data['json_tags_count'] << {
          "name" => k,
          "count" => v.count
        }
      }
    end
  end
  class AutoTagGenerator < Generator
    safe true
    def generate(site)
      if site.layouts.key? 'tags_json'
        dir = site.config['tag_json_dir'] || 'data'
        write_tag_json(site, dir)
      end
    end
    def write_tag_json(site, dir)
      index = AutoTag.new(site, site.source, dir)
      index.render(site.layouts, site.site_payload)
      index.write(site.dest)
      site.pages << index
    end
  end
end
