# frozen_string_literal: true

require 'logger'
require 'open3'

module OhlohScm
  module System
    protected

    def run(cmd)
      out, err, status = Open3.capture3(cmd)
      raise "#{cmd} failed: #{out}\n#{err}" unless status.success?

      out
    end

    def run_with_err(cmd)
      logger.debug { cmd }
      out, err, status = Open3.capture3(cmd)
      [out, err, status]
    end

    def string_encoder_path
      File.expand_path('../../.bin/string_encoder', __dir__)
    end

    def logger
      System.logger
    end

    def temp_folder
      ENV['OHLOH_SCM_TEMP_FOLDER_PATH'] || Dir.tmpdir
    end

    class << self
      # Use a single logger instance.
      def logger
        @logger ||= Logger.new($stderr).tap do |log_obj|
          log_obj.level = ENV['SCM_LOG_LEVEL'].to_i
        end
      end
    end
  end
end
