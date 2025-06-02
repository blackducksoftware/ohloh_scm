# frozen_string_literal: true

require 'rexml/document'
require 'rexml/streamlistener'
require 'time'

module OhlohScm
  class BazaarListener
    include REXML::StreamListener
    attr_accessor :callback, :commit, :diff
    attr_writer :text

    def initialize(callback)
      @callback = callback
      @merge_commit = []
      @state = :none
      @authors = []
    end

    # rubocop:disable Metrics/MethodLength
    def tag_start(name, attrs)
      case name
      when 'log'
        @commit = OhlohScm::Commit.new
        @commit.diffs = []
      when 'affected-files'
        @diffs = []
      when 'added', 'modified', 'removed', 'renamed'
        @action = name
        @state = :collect_files
      when 'file'
        @before_path = attrs['oldpath']
      when 'merge'
        # This is a merge commit, save it and pop it after all branch commits
        @merge_commit.push(@commit)
      when 'authors'
        @state = :collect_authors
        @authors = []
      end
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
    def tag_end(name)
      case name
      when 'log'
        @callback.call(@commit)
      when 'revisionid'
        @commit.token = @text
      when 'message'
        @commit.message = @cdata
      when 'committer'
        committer = BzrXmlParser.capture_name(@text)
        @commit.committer_name = committer[0]
        @commit.committer_email = committer[1]
      when 'author'
        author = BzrXmlParser.capture_name(@text)
        @authors << { author_name: author[0], author_email: author[1] }
      when 'timestamp'
        @commit.committer_date = Time.parse(@text)
      when 'file'
        @diffs.concat(parse_diff(@action, @text, @before_path)) if @state == :collect_files
        @before_path = nil
        @text = nil
      when 'added', 'modified', 'removed', 'renamed'
        @state = :none
      when 'affected-files'
        @commit.diffs = remove_dupes(@diffs)
      when 'merge'
        @commit = @merge_commit.pop
      when 'authors'
        @commit.author_name = @authors[0][:author_name]
        @commit.author_email = @authors[0][:author_email]
        @authors.clear
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity

    # rubocop:disable Style/TrivialAccessors # Cannot use attr_writer; we need cdata not cdata=.
    def cdata(data)
      @cdata = data
    end

    def text(text)
      @text = text
    end
    # rubocop:enable Style/TrivialAccessors

    private

    # rubocop:disable Metrics/MethodLength
    # Parse one single diff
    def parse_diff(action, path, before_path)
      diffs = []
      case action
        # A rename action requires two diffs: one to remove the old filename,
        # another to add the new filename.
        #
        # Note that is possible to be renamed to the empty string!
        # This happens when a subdirectory is moved to become the root.
      when 'renamed'
        diffs = [OhlohScm::Diff.new(action: 'D', path: before_path),
                 OhlohScm::Diff.new(action: 'A', path: path || '')]
      when 'added'
        diffs = [OhlohScm::Diff.new(action: 'A', path: path)]
      when 'modified'
        diffs = [OhlohScm::Diff.new(action: 'M', path: path)]
      when 'removed'
        diffs = [OhlohScm::Diff.new(action: 'D', path: path)]
      end
      diffs.each do |d|
        d.path = strip_trailing_asterisk(d.path)
      end
      diffs
    end
    # rubocop:enable Metrics/MethodLength

    def strip_trailing_asterisk(path)
      path[-1..] == '*' ? path[0..-2] : path
    end

    def remove_dupes(diffs)
      BzrXmlParser.remove_dupes(diffs)
    end
  end

  class BzrXmlParser < Parser
    NAME_REGEX = /^(.+?)(\s+<(.+)>\s*)?$/.freeze
    def self.internal_parse(buffer, _)
      buffer = '<?xml?>' if buffer.is_a?(StringIO) && buffer.length < 2
      REXML::Document.parse_stream(buffer,
                                   BazaarListener.new(proc { |c| yield c if block_given? }))
    rescue EOFError => e
      puts e.message
    end

    def self.scm
      'bzr'
    end

    def self.remove_dupes(diffs)
      remove_modified_after_added!(diffs)
      # Bazaar may report that a file was both deleted and added in a single commit.
      # Reduce these cases to a single 'M' action.
      diffs.each do |d|
        d.action = 'M' if diffs.count { |x| x.path == d.path } > 1
      end.uniq
    end

    # Bazaar may report that a file was added and modified in a single commit.
    # Reduce these cases to a single 'A' action.
    def self.remove_modified_after_added!(diffs)
      diffs.delete_if do |d|
        d.action == 'M' && diffs.any? { |x| x.path == d.path && x.action == 'A' }
      end
    end

    # Bazaar expects committer/author to be specified in this format
    # Name <email>, or John Doe <jdoe@example.com>
    # However, we find many variations in the real world including
    # ones where only email is specified as name.
    def self.capture_name(text)
      parts = text.match(NAME_REGEX).to_a
      name = parts[1] || parts[0]
      email = parts[3]
      [name, email]
    end
  end
end
