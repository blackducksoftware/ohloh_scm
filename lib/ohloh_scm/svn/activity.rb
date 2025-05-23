# frozen_string_literal: true

module OhlohScm
  module Svn
    class Activity < OhlohScm::Activity
      def_delegators :scm, :url

      def root
        Regexp.last_match(1) if info =~ /^Repository Root: (.+)$/
      end

      def username_and_password_opts(source_scm = scm)
        username = source_scm.username.to_s.empty? ? '' : "--username #{source_scm.username}"
        password = source_scm.password.to_s.empty? ? '' : "--password='#{source_scm.password}'"
        "#{username} #{password}"
      end

      def ls(path = nil, revision = 'HEAD')
        stdout = run "svn ls --trust-server-cert --non-interactive -r #{revision} "\
          "#{username_and_password_opts} "\
          "'#{uri_encode(File.join(root.to_s, scm.branch_name.to_s, path.to_s))}@#{revision}'"
        collect_files(stdout)
      rescue StandardError => e
        logger.error(e.message) && nil
      end

      def export(dest_dir, commit_id = 'HEAD')
        FileUtils.mkdir_p(File.dirname(dest_dir)) unless File.exist?(File.dirname(dest_dir))
        run 'svn export --trust-server-cert --non-interactive --ignore-externals --force '\
          "-r #{commit_id} '#{uri_encode(File.join(root.to_s, scm.branch_name.to_s))}'"\
          " '#{dest_dir}'"
      end

      def export_tag(dest_dir, tag_name)
        tag_url = "#{base_path}/tags/#{tag_name}"
        run 'svn export --trust-server-cert --non-interactive --ignore-externals --force'\
              " '#{tag_url}' '#{dest_dir}'"
      end

      # Svn root is not usable here since several projects are nested in subfolders.
      # e.g. https://svn.apache.org/repos/asf/openoffice/ooo-site/trunk/
      #      http://svn.apache.org/repos/asf/httpd/httpd/trunk
      #      http://svn.apache.org/repos/asf/maven/plugin-testing/trunk
      #      all have the same root value(https://svn.apache.org/repos/asf)
      def tags
        doc = Nokogiri::XML(`svn ls --xml #{base_path}/tags`)
        doc.xpath('//lists/list/entry').map do |entry|
          tag_name = entry.xpath('name').text
          revision = entry.xpath('commit').attr('revision').text
          commit_time = entry.xpath('commit/date').text
          date_string = Time.parse(commit_time) unless commit_time.to_s.strip.empty?
          [tag_name, revision, date_string]
        end
      end

      def head_token
        return unless info =~ /^Revision: (\d+)$/

        Regexp.last_match(1).to_i
      end

      private

      def collect_files(stdout)
        stdout.split("\n").map do |line|
          # CVSROOT/ is found in cvs repos converted to svn.
          line.chomp unless line.chomp.empty? || line == 'CVSROOT/'
        end.compact.sort
      end

      def info(path = nil, revision = 'HEAD')
        @info ||= {}
        uri = path ? File.join(root, scm.branch_name.to_s, path) : url
        @info[[path, revision]] ||= run 'svn info --trust-server-cert --non-interactive -r '\
          "#{revision} #{username_and_password_opts} '#{uri_encode(uri)}@#{revision}'"
      end

      # Because uri(with branch) may have characters(e.g. space) that break the shell command.
      def uri_encode(uri)
        # URI.encode is declared obsolete, however we couldn't find an alternative.
        # URI.encode('foo bar') => foo%20bar # `svn log svn://...foo%20bar` works.
        # CGI.escape('foo bar') => foo+bar   # `svn log svn://...foo+bar` won't work.
        # rubocop:disable Lint/UriEscapeUnescape
        URI.encode(uri)
        # rubocop:enable Lint/UriEscapeUnescape
      end

      def base_path
        url.sub(/(.*)(branches|trunk|tags)(.*)/, '\1').chomp('/')
      end
    end
  end
end
