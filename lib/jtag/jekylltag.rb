# encoding: utf-8

class JTag
  attr_reader :default_post_location
  attr_accessor :tags_key

  def initialize(support_dir, config)
    @support = support_dir
    begin
      @tags_loc = config['tags_location']
      @tags_loc.sub!(/^https?:\/\//,'')
    rescue
      raise "No tags location in configuration."
    end
    @min_matches = config['min_matches'] || 2
    @tags_key = config['tags_key'] || 'tags'

    if config.has_key? 'default_post_location'
      @default_post_location = File.expand_path(config['default_post_location']) || false
    else
      console_log "#{color('yellow')}No #{color('boldyellow')}default_post_location#{color('yellow')} set.", :err => true
      console_log "If you commonly work on the same posts you can add the path and *.ext", :err => true
      console_log "to this key in ~/.jtag/config.yml. Then, if you don't specify files", :err => true
      console_log "to act on in a command, it will fall back to those. Nice!#{color('default')}", :err => true
      @default_post_location = false
    end
    @blacklistfile = File.join(@support,'blacklist.txt')
    @blacklist = IO.read(@blacklistfile).split("\n") || []
    @skipwords = IO.read(File.join(support_dir,'stopwords.txt')).split("\n") || []
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
    # http = Net::HTTP.new(host, 80)
    # http.start do |http|
    #   request = Net::HTTP::Get.new(path)
    #   response = http.request(request)
    #   response.value
    #   tags = response.body
    # end
    tags = `curl -sSL "#{@tags_loc}"`
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
    if File.exist?(File.join(@support,"synonyms.yml"))
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

  def split_post(file, piped = false)
    input = piped ? file : IO.read(file)
    # Check to see if it's a full post with YAML headers
    post_parts = input.split(/^[\.\-]{3}\s*$/)
    if post_parts.length >= 3
      after = post_parts[2].strip
      yaml = YAML::load(input)
    else
      after = input
      yaml = YAML::load("--- title: #{File.basename(file)}")
    end
    [yaml, after]
  end

  def post_tags(file, piped=false)
    begin
      input = piped ? file.strip : IO.read(file)
      yaml = YAML::load(input)
      return yaml[@tags_key] || []
    rescue
      return []
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
    parts = input.split(/^[\.\-]{3}\s*$/)
    if parts.length >= 2
      begin
        yaml = YAML::load(parts[1])
        current_tags = yaml[@tags_key] || []
        title = yaml["title"] || ""
      rescue
        current_tags = []
        title = ""
      end
    else
      current_tags = []
      title = ""
    end
    @content = (title + parts[2..-1].join(" ")).strip_all.strip_urls rescue input.strip_all.strip_urls
    @words = split_words
    @auto_tags = []
    populate_auto_tags

    @auto_tags.concat(current_tags).uniq
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

    return [] if freqs.empty?

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

  def update_file_tags(file, tags, piped = false)
    begin
      if File.exist?(file) || piped
        yaml, after = split_post(file, piped)
        yaml[@tags_key] = tags
        if piped
          puts yaml.to_yaml
          puts "---"
          puts after
        else
          File.open(file,'w+') do |f|
            f.puts yaml.to_yaml
            f.puts "---"
            f.puts after
          end
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

  private

  def color(name)
      color = {}
      color['black'] = "\033[0;30m"
      color['red'] = "\033[0;31m"
      color['green'] = "\033[0;32m"
      color['yellow'] = "\033[0;33m"
      color['blue'] = "\033[0;34m"
      color['magenta'] = "\033[0;35m"
      color['cyan'] = "\033[0;36m"
      color['white'] = "\033[0;37m"
      color['bgblack'] = "\033[0;40m"
      color['bgred'] = "\033[0;41m"
      color['bggreen'] = "\033[0;42m"
      color['bgyellow'] = "\033[0;43m"
      color['bgblue'] = "\033[0;44m"
      color['bgmagenta'] = "\033[0;45m"
      color['bgcyan'] = "\033[0;46m"
      color['bgwhite'] = "\033[0;47m"
      color['boldblack'] = "\033[1;30m"
      color['boldred'] = "\033[1;31m"
      color['boldgreen'] = "\033[1;32m"
      color['boldyellow'] = "\033[1;33m"
      color['boldblue'] = "\033[1;34m"
      color['boldmagenta'] = "\033[1;35m"
      color['boldcyan'] = "\033[1;36m"
      color['boldwhite'] = "\033[1;37m"
      color['boldbgblack'] = "\033[1;40m"
      color['boldbgred'] = "\033[1;41m"
      color['boldbggreen'] = "\033[1;42m"
      color['boldbgyellow'] = "\033[1;43m"
      color['boldbgblue'] = "\033[1;44m"
      color['boldbgmagenta'] = "\033[1;45m"
      color['boldbgcyan'] = "\033[1;46m"
      color['boldbgwhite'] = "\033[1;47m"
      color['default'] = "\033[0;39m"
      color['warning'] = color['yellow']
      color['warningb'] = color['boldyellow']
      color['success'] = color['green']
      color['successb'] = color['boldgreen']
      color['neutral'] = color['white']
      color['neutralb'] = color['boldwhite']
      color['info'] = color['cyan']
      color['infob'] = color['boldcyan']
      color[name]
  end
end
