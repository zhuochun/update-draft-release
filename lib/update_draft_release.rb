require 'Logger'
require 'Octokit'

module UpdateDraftRelease
  LOGGER = Logger.new(STDOUT)
  LOGGER.level = Logger::INFO

  class Runner
    DEFAULT_OPTIONS = { skip_confirmation: false,
                        open_url_after_update: false }

    attr_reader :client, :user, :repo, :opts

    def initialize(repo, opts = {})
      @client = Octokit::Client.new(netrc: true)

      @user = client.user
      LOGGER.info "Logged in as: #{@user.login}"

      @repo = repo
      LOGGER.info "Repository used: #{@repo}"

      @opts = DEFAULT_OPTIONS.merge opts
    end

    def update_draft_release
      body = Content.new(draft_release.body)

      lines = latest_user_commit_lines(body)
      if lines.empty?
        LOGGER.error "All commits are already added in release"
        exit
      end

      if body.headings.empty?
        body.append(lines)
      else
        line_num = ask_where_to_insert_line(body)
        body.insert(line_num, lines)
      end

      if ask_confirmation(body) == false
        LOGGER.warn('Update cancelled')
        exit
      end

      LOGGER.info("Update to URL: #{draft_release.url}")
      @client.update_release(draft_release.url, body: body.to_s)

      LOGGER.info("Update draft release completed!")
      `open #{draft_release.html_url}` if @opts[:open_url_after_update]
    end

    private

    def draft_release
      return @draft_release if defined?(@draft_release)

      latest_release = @client.releases(@repo).take(9).find do |release|
        release.draft
      end

      if latest_release.nil?
        LOGGER.error "Unable to find any release or draft release in '#{@repo}'"
        exit
      end

      @draft_release = latest_release
    end

    def latest_user_commit_lines(body)
      latest_user_commits.map do |commit|
        if body.include?(commit.sha)
          LOGGER.warn "Commit SHA '#{commit.sha}' already exists"
          next nil
        end

        line = "#{Content.new(commit.commit.message).title} #{commit.sha}"
        LOGGER.info "Prepare to insert line: #{line}"
        line
      end.compact
    end

    def latest_user_commits
      return @latest_user_commits if defined?(@latest_user_commits)

      latest_commits = @client.commits(@repo).take(9).select do |commit|
        commit.committer && commit.committer.login == @user.login
      end

      if latest_commits.empty?
        LOGGER.error "No recent commit from '#{@user.login}' is found in '#{@repo}'"
        exit
      end

      @latest_user_commits = latest_commits
    end

    def ask_where_to_insert_line(body)
      headings = body.headings.map { |heading| body.lines.index(heading) }
      headings = [0, *headings, body.lines.size - 1].uniq

      puts '##################################################'
      puts 'Please select insert position: '
      puts '##################################################'
      headings.each do |heading|
        start_line_num = [heading - 3, 0].max
        end_line_num   = [heading + 3, body.lines.size - 1].min

        (start_line_num..end_line_num).each do |l|
          puts "[#{l.to_s.rjust(2)}] #{body.lines[l]}" unless body.lines[l].empty?
        end

        puts "=================================================="
      end

      print 'Enter line number: '
      $stdin.gets.chomp.to_i + 1
    end

    def ask_confirmation(body)
      return true if @opts[:skip_confirmation]

      puts '##################################################'
      puts draft_release.name
      puts '=================================================='
      puts body.to_s
      puts '##################################################'

      print 'Ok? (Y/N): '
      $stdin.gets.chomp.upcase == 'Y'
    end
  end

  class Content
    attr_reader :body, :line_separator, :lines

    def initialize(body)
      @body = body
      @line_separator = if body =~ /(\r\n|\n)/ then $1 else %(\r\n) end
      @lines = body.split @line_separator
    end

    def title
      @lines.first[0].upcase + @lines.first[1..-1]
    end

    def headings
      @lines.select { |line| line.match(/^#+\s+.+/) }
    end

    def append(lines)
      Array(lines).each { |line| @lines << '' << line }
    end

    def insert(line_num, lines)
      if line_num == 0
        @lines[line_num,0] = Array(lines)
      else
        @lines[line_num,0] = ['', *Array(lines)]
      end
    end

    def include? sha
      @body.include? sha
    end

    def to_s
      @lines.join @line_separator
    end
  end
end
