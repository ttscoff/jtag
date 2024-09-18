#!/usr/bin/env ruby
# encoding: utf-8

require "minitest/autorun"
require "open3"

require "test_helper"

class TestJtagSearch < Minitest::Test
  def test_search_command
    stdout, stderr, status = jtag("search", "product")
    assert_equal 0, status.exitstatus
    assert_match /- productivity/, stdout
  end

  def test_search_command_with_fuzzy_search
    stdout, stderr, status = jtag("search", "-m", "fuzzy", "rn")
    assert_equal 0, status.exitstatus
    assert_match /- conference/, stdout
  end

  def test_search_command_with_exact_search
    stdout, stderr, status = jtag("search", "-m", "exact", "productivity")
    assert_equal 0, status.exitstatus
    assert_match /- productivity/, stdout
  end

  def test_search_command_with_case_sensitive_search
    stdout, stderr, status = jtag("search", "-I", "Product")
    assert_equal 1, status.exitstatus
    assert_match /No matching/, stderr
  end

  def test_search_command_with_piped_filename
    # Test with piped filename
    File.open("test_post.md", "w") { |f| f.puts("---\ntags: [test]\n---\n") }
    stdout, stderr, status = jtag("search", stdin: "test_post.md")
    assert_equal 0, status.exitstatus
    assert_match /- test/, stdout

    # Clean up
    FileUtils.rm("test_post.md")
  end

  def test_search_with_piped_content
    # Test with piped content
    stdout, stderr, status = jtag("search", stdin: "---\ntags: [test]\n---\n")
    assert_equal 0, status.exitstatus
    assert_match /- test/, stdout
  end

  def test_search_with_invalid_file
    # Test with an invalid file
    stdout, stderr, status = jtag("search", "invalid_file.md")
    assert_equal 1, status.exitstatus
    assert_match /No matching tags/, stderr
  end
end
