# frozen_string_literal: true

class ::Hash
  ## Turn all keys into string
  ##
  ## @return     [Hash] copy of the hash where all its keys are strings
  ##
  def stringify_keys
    each_with_object({}) do |(k, v), hsh|
      hsh[k.to_s] = if v.is_a?(Hash) || v.is_a?(Array)
          v.stringify_keys
        else
          v
        end
    end
  end

  ##
  ## Turn all keys into symbols
  ##
  ## @return [Hash] hash with symbolized keys
  ##
  def symbolize_keys
    each_with_object({}) do |(k, v), hsh|
      hsh[k.to_sym] = if v.is_a?(Hash) || v.is_a?(Array)
          v.symbolize_keys
        else
          v
        end
    end
  end

  ##
  ## Merge two hashes recursively (destructive)
  ##
  ## @see Hash#deep_merge
  ##
  ## @param [Hash] other hash to merge
  ##
  ## @return [Hash] merged hash
  ##
  def deep_merge!(other)
    replace dup.deep_merge(other)
  end

  ##
  ## Merge two hashes recursively
  ##
  ## @param [Hash] other hash to merge
  ##
  ## @return [Hash] merged hash
  ##
  ## @note This method is not the same as Hash#merge! because it merges recursively
  ##
  ## @example Merge two hashes
  ##   { a: 1, b: { c: 2 } }.deep_merge({ b: { d: 3 } })
  ##   # => { a: 1, b: { c: 2, d: 3 } }
  ##
  ## @example Merge two hashes with arrays
  ##   { a: [1, 2] }.deep_merge({ a: [3] })
  ##   # => { a: [1, 2, 3] }
  ##
  ## @example Merge two hashes with arrays and hashes
  ##   { a: [1, 2], b: { c: 3 } }.deep_merge({ a: [3], b: { d: 4 } })
  ##   # => { a: [1, 2, 3], b: { c: 3, d: 4 } }
  ##
  ## @example Merge two hashes with arrays and hashes and strings
  ##   { a: [1, 2], b: { c: 3 } }.deep_merge({ a: [3], b: { d: 4 }, e: "string" })
  ##   # => { a: [1, 2, 3], b: { c: 3, d: 4 }, e: "string" }
  ##
  ## @example Merge two hashes with arrays and hashes and strings and nil
  ##   { a: [1, 2], b: { c: 3 } }.deep_merge({ a: [3], b: { d: 4 }, e: "string", f: nil })
  ##   # => { a: [1, 2, 3], b: { c: 3, d: 4 }, e: "string", f: nil }
  ##
  ## @return [Hash]
  ##
  def deep_merge(other)
    other.each_pair do |k, v|
      tv = self[k]
      self[k] = if tv.is_a?(Hash) && v.is_a?(Hash)
          tv.deep_merge(v)
        else
          v
        end
    end
    self
  end

  ##
  ## Convert hash to array with parenthetical counts
  ##
  ## @return [Array] array of tags with parenthetical counts
  ##
  def to_counts
    if key?("tag_counts")
      self["tag_counts"]
    elsif key?("tags")
      self["tags"].map(&:to_count)
    end
  end
end
