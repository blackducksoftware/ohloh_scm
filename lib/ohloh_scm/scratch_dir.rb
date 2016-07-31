require 'fileutils'

# A utility class to manage the creation and automatic cleanup of temporary directories.
module OhlohScm
  class ScratchDir
    attr_reader :path

    # Creates a uniquely named directory in the system tmp directory.
    #
    # If a block is passed to the constructor, the path to the created directory
    # will be yielded to the block. The directory will then be deleted
    # when this block returns.
    #
    # Sample usage:
    #
    #   ScratchDir.new do |path|
    #     # Do some work in the new directory
    #     File.new( path + '/foobaz', 'w' ) do
    #       # ...
    #     end
    #   end # Scratch directory is deleted here
    #
    def initialize
      @path = `mktemp -d /tmp/ohloh_scm_XXXXXX`.strip
      if block_given?
        begin
          return yield(@path)
        ensure
          FileUtils.rm_rf(@path)
        end
      end
    end
  end

  if $0 == __FILE__
    path = nil

    ScratchDir.new do |d|
      path = d
      filename = File.join(d,"test")
      File.open(filename, "w") do |io|
        io.write "test"
      end
    end
    raise RuntimeError.new("Directory wasn't cleaned up") if FileTest.directory?(path)

    begin
      ScratchDir.new do |d|
        path = d
        STDOUT.puts "Created scratch direcory #{d}"
        raise RuntimeError.new("This error should not prevent cleanup")
      end
    rescue
    end
    raise RuntimeError.new("Directory wasn't cleaned up") if FileTest.directory?(path)

    STDOUT.puts "Tests passed."
  end
end
