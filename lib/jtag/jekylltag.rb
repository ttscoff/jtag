class JTag

  def initialize(support_dir, config)
    @support = support_dir
    @min_matches = config["min_matches"] || 2
    @tags_loc = config["tags_location"]
    @blacklistfile = File.join(@support,"blacklist.txt")
    @blacklist = IO.read(@blacklistfile).split("\n") || []
    @skipwords = IO.read(File.join(support_dir,"stopwords.txt")).split("\n") || []
    remote_tags = get_tags
    @tags = {}
    remote_tags.each {|tag| @tags[Text::PorterStemming.stem(tag).downcase] = tag if tag}
    synonyms.each { |k,v|
      @tags[k.to_s.downcase] = v unless @blacklist.include?(k.to_s.downcase)
    }
  end

  def get_tags(options={})
    blacklisted = options[:blacklisted] || false
    counts = options[:counts] || false
    host, path = @tags_loc.match(/^([^\/]+)(\/.*)/)[1,2]
    tags = ""
    http = Net::HTTP.new(host, 80)
    http.start do |http|
      request = Net::HTTP::Get.new(path)
      response = http.request(request)
      response.value
      tags = response.body
    end
    tags = JSON.parse(tags)
    if tags && tags.key?("tags")
      if counts
        return tags["tags_count"]
      else
        unless blacklisted
          tags["tags"].delete_if {|tag| !tag || @blacklist.include?(tag.downcase) }
        end
        return tags["tags"]
      end
    else
      return false
    end
  end

  def synonyms
    if File.exists?(File.join(@support,"synonyms.yml"))
      syn = YAML::load(File.open(File.join(@support,"synonyms.yml")))
      compiled = {}
      syn.each {|k,v|
        v.each {|synonym|
          compiled[synonym] = k
        }
      }
    else
      return false
    end
    compiled
  end

  def split_post(file)
    input = IO.read(file)
    # Check to see if it's a full post with YAML headers
    post_parts = input.split(/^---\s*$/)
    raise "File has improper YAML header" unless post_parts.length == 3
    after = post_parts[2].strip
    yaml = YAML::load(input)
    [yaml, after]
  end

  def post_tags(file)
    if File.exists?(file)
      input = IO.read(file)
      yaml = YAML::load(input) || false
      exit_now! "Invalid post header" unless yaml
      return yaml["tags"] || []
    else
      raise "File #{file} does not exist"
    end
  end

  def merge_tags(tags, merged, file)
    current_tags = post_tags(file)
    post_has_tag = false
    tags.each {|tag|
      if current_tags.include?(tag)
        current_tags.delete(tag)
        post_has_tag = true
      end
    }
    return false unless post_has_tag
    current_tags.push(merged)
    current_tags.uniq!
    current_tags.sort
  end


  def suggest(input)
    yaml = YAML::load(input) || false
    exit_now! "Invalid post header" unless yaml
    current_tags = yaml["tags"] || []
    title = yaml["title"] || ""
    @content = (title + after).strip_all.strip_urls rescue input.strip_all.strip_urls
    @words = split_words
    @auto_tags = []
    populate_auto_tags
    @auto_tags.concat(current_tags).uniq!
  end

  def split_words
    @content.gsub(/([\/\\]|\s+)/,' ').gsub(/[^A-Za-z0-9\s-]/,'').split(" ").delete_if { |word|
      word =~ /^[^a-z]+$/ || word.length < 4
    }.map! { |word|
      Text::PorterStemming.stem(word).downcase
    }.delete_if{ |word|
      @skipwords.include?(word) && !@tags.keys.include?(word)
    }
  end

  def populate_auto_tags
    freqs = Hash.new(0)
    @words.each { |word| freqs[word] += 1 }
    freqs.delete_if {|k,v| v < @min_matches }

    exit_with_message "No high frequency words", 1 if freqs.empty?

    freqs.sort_by {|k,v| [v * -1, k] }.each {|word|
      index = @tags.keys.index(word[0])
      unless index.nil? || @blacklist.include?(@tags.keys[index])
        @auto_tags.push(@tags[@tags.keys[index]]) unless index.nil?
      end
    }

    @tags.each{|k,v|
      occurrences = @content.scan(/\b#{k}\b/i)
      if occurrences.count >= @min_matches
        @auto_tags.push(v)
      end
    }
  end

  def blacklist(tags)
    tags.each {|word|
      @blacklist.push(word.downcase)
    }
    File.open(@blacklistfile,'w+') do |f|
      f.puts @blacklist.uniq.sort.join("\n")
    end
  end

  def unblacklist(tags)
    tags.each {|word|
      @blacklist.delete_if { |x| x == word }
    }
    File.open(@blacklistfile,'w+') do |f|
      f.puts @blacklist.uniq.sort.join("\n")
    end
  end

  def update_file_tags(file, tags)
    begin
      if File.exists?(file)
        yaml, after = split_post(file)
        yaml["tags"] = tags
        File.open(file,'w+') do |f|
          f.puts yaml.to_yaml
          f.puts "---"
          f.puts after
        end
      else
        raise "File does not exist: #{file}"
      end
      return true
    rescue Exception => e
      raise e
      return false
    end
  end
end

