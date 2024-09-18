require "test/unit"
require "fileutils"

$:.unshift File.dirname(__FILE__)
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require "jtag"

TEST_CONFIG_DIR = File.expand_path("test_config", __dir__)
TEST_POST_DIR = File.expand_path("test_posts", __dir__)
JTAG_BIN = ["bundle", "exec", File.expand_path("../bin/jtag", __dir__), "-c", TEST_CONFIG_DIR]

# Add test libraries you want to use here, e.g. mocha

class Test::Unit::TestCase

  # Add global extensions to the test case class here

end

def pread(env, *cmd, stdin: nil)
  out, err, status = Open3.capture3(env, *cmd, stdin_data: stdin)
  # unless status.success?
  #   raise [
  #           "Error (#{status}): #{cmd.inspect} failed", "STDOUT:", out.inspect, "STDERR:", err.inspect,
  #         ].join("\n")
  # end
  [out, err, status]
end

def jtag_with_env(env, *args, stdin: nil)
  pread(env, *JTAG_BIN, *args, stdin: stdin)
end

def jtag(*args, stdin: nil)
  pread({}, *JTAG_BIN, *args, stdin: stdin)
end
