require "test_helper"
require "tmpdir"

class PostLocationTest < Test::Unit::TestCase
  def setup
    @dir = Dir.mktmpdir
    @support = File.join(@dir, "support")
    @posts = File.join(@dir, "posts")
    FileUtils.mkdir_p(@support)
    FileUtils.mkdir_p(@posts)
    File.write(File.join(@support, "blacklist.txt"), "")
    File.write(File.join(@support, "stopwords.txt"), "")
    File.write(File.join(@support, "synonyms.yml"), "{}\n")
    File.write(File.join(@posts, "one.md"), "---\ntags:\n- blogbook\n---\nHello\n")
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir
  end

  def test_legacy_glob_becomes_a_directory
    jt = JekyllTag::JTag.new(@support, {
      tags_location: "auto",
      default_post_location: File.join(@posts, "*.md"),
      tags_key: "tags",
    })

    assert_equal File.expand_path(@posts), jt.default_post_location
    assert_equal "md", jt.post_extension
    assert_equal ["blogbook"], jt.post_tags(File.join(@posts, "one.md"))
  end

  def test_directory_post_location_is_unchanged
    jt = JekyllTag::JTag.new(@support, {
      tags_location: "auto",
      default_post_location: @posts,
      post_extension: "md",
      tags_key: "tags",
    })

    assert_equal File.expand_path(@posts), jt.default_post_location
    assert_equal "md", jt.post_extension
  end

  def test_console_log_tolerates_a_missing_debug_level
    util = JekyllTag::Util.new
    util.debug_level = nil
    util.silent = true
    util.console_log("hidden", level: :error)
  end

  def test_list_is_a_valid_output_format
    assert_equal :list, "list".to_format
  end
end
