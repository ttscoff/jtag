#!/usr/bin/env ruby
# encoding: utf-8
require "minitest/autorun"
require "gli"
require "jtag"
require "fcntl"

require_relative "../lib/jtag/jtag.rb"

class TestJTagTag < Minitest::Test
  JTAG_BIN = File.expand_path("../bin/jtag", __FILE__)
  TEST_CONFIG_DIR = File.expand_path("test_config")

  def setup
    configfile = File.join(TEST_CONFIG_DIR, "config.yml")
    JekyllTag::Util.new.write_config(true)
    FileUtils.cp(File.expand_path("test_files/*.md"), ".")
    config = YAML::load_file(configfile)
    @jt = JekyllTag::JTag.new(TEST_CONFIG_DIR, config)
  end

  def test_suggestions_with_piped_content
    post = Dir.glob("2021-08-26*.md").first
    piped_content = IO.read(post)
    expected_suggestions = @jt.suggest(piped_content)

    IO.popen("echo '#{piped_content}' | #{JTAG_BIN} tag", "r") do |output|
      result = output.read
      assert_includes result, expected_suggestions.join("\n")
    end
  end

  def test_suggestions_with_file
    test_file = Dir.glob("2021-08-26*.md").first
    expected_suggestions = @jt.suggest(File.read(test_file))

    IO.popen("#{JTAG_BIN} -t tag #{test_file}", "r") do |output|
      result = output.read
      assert_includes result, expected_suggestions.to_yaml
    end

    File.delete(test_file)
  end

  def test_suggestions_with_invalid_file
    invalid_file = "/tmp/invalid_post.md"

    IO.popen("#{JTAG_BIN} -t tag #{invalid_file}", "r") do |output|
      result = output.read
      assert_includes result, "No such file: #{invalid_file}"
    end
  end
end
