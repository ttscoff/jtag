# frozen_string_literal: true

module JekyllTag
  # JTag utilities
  class Util
    attr_writer :debug_level
    attr_writer :silent
    attr_accessor :log
    attr_accessor :config_target

    DEBUG_LEVELS = {
      :error => 0,
      :warn => 1,
      :info => 2,
      :debug => 3,
    }

    CONFIG_FILES = %w{blacklist.txt config.yml stopwords.txt synonyms.yml}

    ##
    ## Output tags in the specified format
    ##
    ## @param tags [Array] array of tags
    ## @param options [Hash] hash of options
    ##
    ## @option options :format [String] format to output tags in
    ## @option options :print0 [Boolean] print tags with null delimiter
    ## @option options :filename [String] filename to output
    ## @option options :content [String] content to output for complete format
    ## @option options :grouping [String] grouping key for YAML tags
    ##
    ## @return [void]
    ##
    def output_tags(tags, options)
      # Determine the format for output, defaulting to "yaml" if not specified
      format = options[:format]&.to_format || :yaml
      # Determine if tags should be printed with a null delimiter
      print0 = options[:print0] || false
      # Determine the filename for output, if specified
      filename = options[:filename] || false
      # Content that was piped in
      content = options[:content] || false

      tags.sort!
      tags.uniq!

      case format
      when "complete"
        if filename || content
          content = filename ? IO.read(File.expand_path(filename)) : content
          parts = content.split(/---\s*\n/)
          if parts.count < 2
            console_log "No front matter found in #{filename}", level: :error, err: true
            yaml = {}
            body = content
          else
            yaml = YAML.load(parts[1])
            body = parts[2..-1].join("\n")
          end
          options[:grouping] ||= "tags"
          yaml[options[:grouping]] = tags
          console_log "#{filename}", level: :info, err: true if filename
          console_log yaml.to_yaml + "---\n" + body, level: :error, err: false
        else
          console_log tags.join("\n"), level: :error, err: false
        end
      when "list"
        # Join tags with a null character delimiter
        console_log tags.map(&:strip).join(print0 ? "\x00" : "\n"), level: :error, err: false, file: filename
      when "csv"
        # Log the tags in CSV format
        console_log tags.to_csv
      when "json"
        # Create a hash with tags and optional filename, then log as JSON
        out = {}
        out["tags"] = tags
        out["path"] = filename if filename
        console_log out.to_json
      when "plist"
        # Create a hash with optional filename, then log as plist
        out = {}
        out["path"] = filename if filename
        out["tags"] = tags
        console_log out.to_plist
      else
        # Default to YAML format, create a hash with grouping and tags, then log as YAML
        out = {}
        options[:grouping] ||= "tags"
        out[options[:grouping]] = tags
        console_log out.to_yaml
      end
    end

    ##
    ## Logging
    ##
    ### Log levels
    ## 0 = error
    ## 1 = warn
    ## 2 = info
    ## 3 = debug
    ##
    ### Debug levels
    ## 1 = errors only
    ## 2 = errors and warnings
    ## 3 = errors, warnings and info
    ## 4 = errors, warnings, info and debug
    ##
    ### Test level < debug level (true = return, false = continue)
    ## true = continue
    ## false = return
    ##
    ### Examples
    ## send info (2) and debug is errors and warnings (2) (2 < 2 = return)
    ## send error (0) and debug is errors and warnings (2) (0 < 2 = continue)
    ## send warning (1) and debug is errors only (1) (1 < 1 = return)
    ## send error (0) and debug level is silent (0) (0 < 0 = return)
    ## send debug (3) and debug level is info (3) (3 < 4 = return)
    ## send debug (3) and debug level is debug (4) (3 < 4 = continue)
    ##
    ## @example Log an info message
    ##   console_log("This is an info message", level: :info)
    ##
    ## @example Log a warning message and output to STDERR
    ##   console_log("This is a warning message", level: :warn, err: true)
    ##
    ## @param msg [String] message to log
    ## @param options [Hash] hash of options
    ##
    ## @option options :level [Symbol] level of message (info, warn, error, debug)
    ## @option options :err [Boolean] print to STDERR
    ## @option options :log [Boolean] write to log file
    ## @option options :filename [String] write to file
    ##
    ## @return [void]
    ##
    def console_log(msg = "", options = {})
      level = options[:level] || :info
      err = options[:err] || false
      options[:log] ||= false

      return unless DEBUG_LEVELS[level.to_sym] < @debug_level

      if options[:log]
        if err
          @log.warn(msg)
        else
          @log.info(msg)
        end
      end

      if options[:filename]
        File.open(options[:filename], "w") do |f|
          f.puts msg
        end
      end

      return if @silent

      unless err
        $stdout.puts msg
      else
        $stderr.puts msg
      end
    end

    #
    ## Write configuration files
    ##
    ## @param atomic [Boolean] force write of config files
    ##
    ## @example Write configuration files
    ##   write_config
    ##
    ## @return [void]
    ##
    def write_config(atomic = false)
      # Get the root path of the gem
      jtag_gem = Gem.loaded_specs["jtag"]
      gem_root = jtag_gem.full_gem_path || File.expand_path("../../", __dir__)
      # Get the lib directory within the gem
      gem_lib = File.join(gem_root, "lib")
      # Define the source directory for the configuration files
      config_source = File.join(gem_lib, "/jtag/config_files/")

      FileUtils.rm_rf(@config_target) if File.directory?(@config_target) && atomic

      # If the config target directory does not exist or atomic is true, copy the config files
      if !File.directory?(@config_target)
        # Ensure the target directory exists
        FileUtils.mkdir_p(@config_target)
        CONFIG_FILES.each do |file|
          FileUtils.cp(File.join(config_source, file), @config_target)
        end
        # console_log "Configuration files written to #{@config_target}", level: :warn
      end

      # Iterate over each config file
      CONFIG_FILES.each do |file|
        # If the config file does not exist in the target directory, copy it from the source
        unless File.exist?(File.join(@config_target, file))
          # Define the source and target file paths
          source_file = File.join(config_source, file)
          target_file = File.join(@config_target, file)
          # Copy the source file to the target location
          FileUtils.cp(source_file, target_file)
          # Log that the config file has been added
          console_log "Config file #{file} added."
        end
      end

      # Output the final location of the configuration files
      console_log
      console_log "Configuration files are located in the folder: " + @config_target
      # Output a reminder to set the tags_location in the config.yml file
      console_log %Q{Make sure that "tags_location" in the config.yml file is set to your tags json file.}
    end

    ## Check if all config files are present
    ##
    ## @example Check if all config files are present
    ##   config_files_complete?
    ##   # => true
    ##
    ## @return [Boolean]
    def config_files_complete?
      # Move ~/.jtag if needed
      update_deprecated_config

      # Check if all config files are present
      CONFIG_FILES.each do |file|
        return false unless File.exist?(File.join(@config_target, file))
      end
      true
    end
  end
end
