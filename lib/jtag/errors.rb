# frozen_string_literal: true

class FileNotFound < StandardError
  def initialize(msg = "File not found")
    super(msg)
  end
end

class NoTagsFound < StandardError
  def initialize(msg = "No tags found in input")
    super(msg)
  end
end

class NoResults < StandardError
  def initialize(msg = "No results")
    super(msg)
  end
end

class NoValidFile < StandardError
  def initialize(msg = "No valid filename in arguments")
    super(msg)
  end
end

class InvalidTagsFile < StandardError
  def initialize(msg = "Invalid tags file")
    super(msg)
  end
end
