#!/usr/bin/env ruby
# encoding: utf-8

require "minitest/autorun"
require "fileutils"
require "yaml"
require_relative "jekylltag"

class TestJekyllTag < Minitest::Test
  # def setup
  #   @support_dir = "/tmp/jekylltag_support"
  #   FileUtils.mkdir_p(@support_dir)
  #   File.write(File.join(@support_dir, "blacklist.txt"), "")
  #   File.write(File.join(@support_dir, "stopwords.txt"), "")
  #   @config = {
  #     tags_location: "auto",
  #     default_post_location: "/tmp/posts",
  #     post_extension: "md",
  #     tags_key: "tags",
  #   }
  #   @jekyll_tag = JekyllTag::JTag.new(@support_dir, @config)
  # end

  # def teardown
  #   FileUtils.rm_rf(@support_dir)
  # end

  # def test_tags_with_files_option
  #   file_path = "/tmp/posts/test_post.md"
  #   FileUtils.mkdir_p(File.dirname(file_path))
  #   File.write(file_path, "---\ntags: [test, example]\n---\nContent")

  #   options = { files: [file_path] }
  #   tags = @jekyll_tag.tags(options)

  #   assert_equal ["test", "example"], tags
  # end

  # def test_tags_with_blacklisted_option
  #   file_path = "/tmp/posts/test_post.md"
  #   FileUtils.mkdir_p(File.dirname(file_path))
  #   File.write(file_path, "---\ntags: [test, example]\n---\nContent")
  #   File.write(File.join(@support_dir, "blacklist.txt"), "test\n")

  #   options = { files: [file_path], blacklisted: false }
  #   tags = @jekyll_tag.tags(options)

  #   assert_equal ["example"], tags
  # end

  # def test_tags_with_counts_option
  #   file_path = "/tmp/posts/test_post.md"
  #   FileUtils.mkdir_p(File.dirname(file_path))
  #   File.write(file_path, "---\ntags: [test, example]\n---\nContent")

  #   options = { files: [file_path], counts: true }
  #   tags = @jekyll_tag.tags(options)

  #   expected = [{ "name" => "test", "count" => 1 }, { "name" => "example", "count" => 1 }]
  #   assert_equal expected, tags
  # end

  # def test_tags_with_invalid_file_format
  #   file_path = "/tmp/posts/test_post.md"
  #   FileUtils.mkdir_p(File.dirname(file_path))
  #   File.write(file_path, "Invalid content")

  #   options = { files: [file_path] }
  #   tags = @jekyll_tag.tags(options)

  #   assert_equal [], tags
  # end
end
