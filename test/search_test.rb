#!/usr/bin/env ruby
# encoding: utf-8

require 'minitest/autorun'
require 'open3'

class TestJtagSearch < Minitest::Test
  JTAG_BIN = File.expand_path('../bin/jtag', __dir__)

  def test_files_command
    # Test with no arguments
    stdout, stderr, status = Open3.capture3(JTAG_BIN, 'search', 'test')
    assert_equal 0, status.exitstatus
    assert_match /No valid filename in arguments/, stderr

    # Test with a valid file
    File.write('test_post.md', '---\ntags: [test]\n---\n')
    stdout, stderr, status = Open3.capture3(JTAG_BIN, 'files', 'test_post.md')
    assert_equal 0, status.exitstatus
    assert_match /test_post.md/, stdout

    # Clean up
    File.delete('test_post.md')
  end

  def test_files_with_piped_content
    # Test with piped content
    File.write('test_post.md', '---\ntags: [test]\n---\n')
    stdout, stderr, status = Open3.capture3("echo 'test_post.md' | #{JTAG_BIN} files")
    assert_equal 0, status.exitstatus
    assert_match /test_post.md/, stdout

    # Clean up
    File.delete('test_post.md')
  end

  def test_files_with_invalid_file
    # Test with an invalid file
    stdout, stderr, status = Open3.capture3(JTAG_BIN, 'files', 'non_existent_file.md')
    assert_equal 1, status.exitstatus
    assert_match /File not found: non_existent_file.md/, stderr
  end
end