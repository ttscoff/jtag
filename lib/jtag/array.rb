# frozen_string_literal: true

class ::Array
  #
  # Stringify keys in an array of hashes or arrays
  #
  # @return [Array] Array with nested hash keys stringified
  #
  def stringify_keys
    each_with_object([]) do |v, arr|
      arr << if v.is_a?(Hash)
        v.stringify_keys
      elsif v.is_a?(Array)
        v.map { |x| x.is_a?(Hash) || x.is_a?(Array) ? x.stringify_keys : x }
      else
        v
      end
    end
  end

  #
  # Symbolize keys in an array of hashes or arrays
  #
  # @return [Array] Array with nested hash keys symbolized
  #
  def symbolize_keys
    each_with_object([]) do |v, arr|
      arr << if v.is_a?(Hash)
        v.symbolize_keys
      elsif v.is_a?(Array)
        v.map { |x| x.is_a?(Hash) || x.is_a?(Array) ? x.symbolize_keys : x }
      else
        v
      end
    end
  end

  def to_counts
    map do |tag|
      if tag.is_a?(String)
        tag.to_count
      else
        tag
      end
    end
  end
end
