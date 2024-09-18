#!/usr/bin/env ruby
# encoding: utf-8

require "minitest/autorun"
require "fileutils"
require "open3"
require_relative "../lib/jtag/jtag.rb"

class TestJtagConfig < Minitest::Test
  JTAG_BIN = File.expand_path("../bin/jtag", __FILE__)
  TEST_CONFIG_DIR = File.expand_path("test_config")

  def setup
    FileUtils.mkdir_p(TEST_CONFIG_DIR)
    FileUtils.touch(File.join(TEST_CONFIG_DIR, "config.yml"))
  end

  def teardown
    FileUtils.rm_rf(TEST_CONFIG_DIR)
  end

  def test_config_set
    key = "test_key"
    value = "test_value"
    command = "#{JTAG_BIN} config --config_dir=#{TEST_CONFIG_DIR} --set=#{key} --value=#{value}"
    stdout, stderr, status = Open3.capture3(command)

    assert status.success?, "Command failed: #{stderr}"
    config = YAML.load_file(File.join(TEST_CONFIG_DIR, "config.yml"))
    assert_equal value, config[key], "Expected #{key} to be set to #{value}"
  end

  def test_config_reset
    command = "#{JTAG_BIN} config --config_dir=#{TEST_CONFIG_DIR} --reset"
    stdout, stderr, status = Open3.capture3(command)

    assert status.success?, "Command failed: #{stderr}"
    assert File.exist?(File.join(TEST_CONFIG_DIR, "config.yml")), "Config file should exist after reset"
  end
end
