#!/usr/bin/env ruby
# encoding: utf-8
require "minitest/autorun"
require "gli"
require "jtag"
require "fcntl"

require "test_helper"

class TestJTagTag < Minitest::Test
  def setup
    configfile = File.join(TEST_CONFIG_DIR, "config.yml")
    jtag("config", "--reset", "--yes")
    config = YAML::load_file(configfile)
    @jt = JekyllTag::JTag.new(TEST_CONFIG_DIR, config)
  end

  def test_suggestions_with_piped_content
    post = Dir.glob(File.join(TEST_POST_DIR, "2021-08-26*.md")).first
    piped_content = IO.read(post)
    expected_suggestions = @jt.suggest(piped_content).sort_by { |tag| tag.downcase }

    stderr, stdout, status = jtag("-t", "tag", stdin: piped_content)
    res = YAML::load(stderr)
    assert_equal res["tags"], expected_suggestions
  end

  def test_suggestions_with_file
    post = Dir.glob(File.join(TEST_POST_DIR, "2021-08-26*.md")).first
    expected_suggestions = @jt.suggest(File.read(post)).sort_by { |tag| tag.downcase }

    stderr, stdout, status = jtag("-t", "tag", post)
    res = YAML::load(stderr)
    assert_equal res["tags"], expected_suggestions
  end
end
