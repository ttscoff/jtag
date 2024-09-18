# frozen_string_literal: true

## String helpers
class String
  ##
  ## normalize bool string to symbo
  ##
  ## @return [Symbol] :and :or :not
  ##
  def to_bool
    case self.downcase
    when /^a/i
      :and
    when /^o/i
      :or
    when /^n/i
      :not
    else
      raise ArgumentError, "Invalid boolean string: #{self}"
    end
  end

  ## Check if a string is a list of files
  ##
  ## @param null [Boolean] check for null-delimited list
  ##
  ## @example Check if a string is a list of files
  ##   "file1\nfile2\nfile3".file_list?
  ##   # => true
  ##
  ## @return [Boolean]
  def file_list?(null = false)
    self.strip.split(null ? "\x00" : "\n").each do |line|
      return false unless File.exist?(line)
    end
    true
  end

  ##
  ## Check if string is YAML
  ##
  ## @example Check if a string is YAML
  ##   "tags:\n  - tag1\n  - tag2".yaml?
  ##   # => true
  ##
  ## @example Check if a string is not YAML
  ##   "test string".yaml?
  ##   # => false
  ##
  ## @return [Boolean]
  ##
  def yaml?
    begin
      YAML.load(self)
    rescue
      return false
    end
    true
  end

  ##
  ## Matches the string against a given keyword based on various options.
  ##
  ## @param keyword [String] the keyword to match against the string.
  ## @param options [Hash] a hash of options to customize the matching behavior.
  ## @option options [Boolean] :case_sensitive (false) whether the match should be case-sensitive.
  ## @option options [Boolean] :starts_with (false) whether the match should check if the string starts with the keyword.
  ## @option options [Boolean] :exact (false) whether the match should be exact.
  ## @option options [Boolean] :fuzzy (true) whether the match should be fuzzy.
  ## @option options [Integer] :distance (2) the maximum distance between characters for a fuzzy match.
  ##
  ## @return [Boolean] true if the string matches the keyword based on the given options, false otherwise.
  ##
  def match_keyword(keyword, options = {})
    options = {
      case_sensitive: false,
      starts_with: false,
      exact: false,
      fuzzy: false,
      contains: false,
      distance: 2,
    }.merge(options)

    keyword = Regexp.escape(keyword)

    if options[:exact]
      re = "^#{keyword}$"
    elsif options[:starts_with]
      re = "^#{keyword}"
    elsif options[:fuzzy]
      re = ".*#{keyword.split(//).join(".{,#{options[:distance] - 1}}")}.*"
    else
      re = ".*#{keyword}.*"
    end

    if options[:case_sensitive]
      self.match?(/#{re}/)
    else
      self.match?(/#{re}/i)
    end
  end

  ##
  ## Check if a string is JSON
  ##
  ## @example Check if a string is JSON
  ##   '{"tags": ["tag1", "tag2"]}'.json?
  ##   # => true
  ##
  ## @example Check if a string is not JSON
  ##   "test string".json?
  ##   # => false
  ##
  ## @return [Boolean]
  ##
  ## @note JSON must be a hash or array
  ##
  def json?
    begin
      JSON.parse(self).is_a?(Hash) || JSON.parse(self).is_a?(Array)
    rescue
      return false
    end
    true
  end

  ##
  ## Convert parenthetical count to hash
  ##
  ## @example Convert a string to a hash
  ##   "tag (5)".to_count
  ##   # => { "name" => "tag", "count" => 5 }
  ##
  ## @example Convert a string to a hash with no count
  ##   "tag".to_count
  ##   # => { "name" => "tag", "count" => 0 }
  ##
  ## @return [Hash] hash with name and count
  ##
  def to_count
    tag = dup.strip.sub(/^[[:punct:]] /, "")
    if tag =~ /(.*) \((\d+)\)/
      { "name" => $1, "count" => $2.to_i }
    else
      { "name" => tag, "count" => 0 }
    end
  end

  ##
  ## Check if a string is a list of tags
  ##
  ## @example Check if a string is a list of tags
  ##   "tag1\ntag2".tag_list?
  ##   # => true
  ##
  ## @return [Boolean]
  ##
  ## @note One tag per line
  ##   Tags are assumed to be alphanumeric and lowercase
  ##   (spaces, underscores, and dashes allowed) with no
  ##   leading or preceding or trailing punctuation
  ##
  def tag_list?
    self.strip.split("\n").each do |tag|
      return false unless tag.match?(/^(?![[:punct:]] )[a-z0-9 -_]+(?<![[:punct:]]) *$/)
    end
    true
  end

  def root_words
    words = break_camel.split("[\s-]")
    words.delete_if { |word| word =~ /^[^a-z]+$/i || word.length < 4 }
    words.map { |word| word = Text::PorterStemming.stem(word).downcase }.join(" ")
  end

  # convert "WikiLink" to "Wiki link"
  def break_camel
    return downcase if match(/\A[A-Z]+\z/)
    gsub(/([A-Z]+)([A-Z][a-z])/, '\1 \2').
      gsub(/([a-z])([A-Z])/, '\1 \2').
      downcase
  end

  def strip_markdown
    # strip all Markdown and Liquid tags
    gsub(/\{%.*?%\}/, "").
      gsub(/\[\^.+?\](\: .*?$)?/, "").
      gsub(/\s{0,2}\[.*?\]: .*?$/, "").
      gsub(/\!\[.*?\][\[\(].*?[\]\)]/, "").
      gsub(/\[(.*?)\][\[\(].*?[\]\)]/, "\\1").
      gsub(/^\s{1,2}\[(.*?)\]: (\S+)( ".*?")?\s*$/, "").
      gsub(/^\#{1,6}\s*/, "").
      gsub(/(\*{1,2})(\S.*?\S)\1/, "\\2").
      gsub(/(`{3,})(.*?)\1/m, "\\2").
      gsub(/^-{3,}\s*$/, "").
      gsub(/`(.+)`/, "\\1").
      gsub(/\n{2,}/, "\n\n")
  end

  def strip_tags
    return CGI.unescapeHTML(
             gsub(/<(script|style|pre|code|figure).*?>.*?<\/\1>/im, "").
               gsub(/<!--.*?-->/m, "").
               gsub(/<(img|hr|br).*?>/i, " ").
               gsub(/<(dd|a|h\d|p|small|b|i|blockquote|li)( [^>]*?)?>(.*?)<\/\1>/i, " \\3 ").
               gsub(/<\/?(dt|a|ul|ol)( [^>]+)?>/i, " ").
               gsub(/<[^>]+?>/, "").
               gsub(/\[\d+\]/, "").
               gsub(/&#8217;/, "'").gsub(/&.*?;/, " ").gsub(/;/, " ")
           ).lstrip.gsub("\xE2\x80\x98", "'").gsub("\xE2\x80\x99", "'").gsub("\xCA\xBC", "'").gsub("\xE2\x80\x9C", '"').gsub("\xE2\x80\x9D", '"').gsub("\xCB\xAE", '"').squeeze(" ")
  end

  def strip_urls
    gsub(/(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?/i, "")
  end

  def strip_all
    strip_tags.strip_markdown.strip
  end
end
