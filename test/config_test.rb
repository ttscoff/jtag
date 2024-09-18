#!/usr/bin/env ruby
# encoding: utf-8

require "minitest/autorun"
require "fileutils"
require "open3"
require "test_helper"

class TestJtagConfig < Minitest::Test
  def setup
    FileUtils.mkdir_p(TEST_CONFIG_DIR)
    FileUtils.touch(File.join(TEST_CONFIG_DIR, "config.yml"))
  end

  # def teardown
  #   FileUtils.rm_rf(TEST_CONFIG_DIR)
  # end

  def test_config_set
    key = "test_key"
    value = "test_value"
    value2 = "test_value2"

    stdout, stderr, status = jtag("config", "--set", key, "--value", value)
    assert_equal 0, status.exitstatus
    config = YAML.load_file(File.join(TEST_CONFIG_DIR, "config.yml"))
    assert_equal value, config[key], "Expected #{key} to be set to #{value}"

    stdout, stderr, status = jtag("config", "--set", key, "--value", value2)
    assert_equal 0, status.exitstatus
    config = YAML.load_file(File.join(TEST_CONFIG_DIR, "config.yml"))
    assert_equal value2, config[key], "Expected #{key} to be set to #{value2}"
  end

  def test_config_reset
    jtag("config", "--set", "test_key", "--value", "test value")
    stdout, stderr, status = jtag("config", "--reset", "--yes")
    assert_equal 0, status.exitstatus
    config = YAML.load_file(File.join(TEST_CONFIG_DIR, "config.yml"))
    assert_nil config["test_key"], "Expected test_key not exist"
  end
end
