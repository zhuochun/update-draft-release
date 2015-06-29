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

    def draft_release
      return @draft_release if defined?(@draft_release)

      latest_release = @client.releases(@repo).take(9).find { |release| release.draft }

      if latest_release.nil?
        LOGGER.error "Unable to find any release in '#{@repo}'"
        exit
      end

      unless latest_release.draft
        LOGGER.error "Latest release '#{latest_release.name}' is not a draft release"
        exit
      end

      @draft_release = latest_release
    end

    def latest_user_commit
      return @latest_user_commit if defined?(@latest_user_commit)

      latest_commit = @client.commits(@repo).take(9).find do |commit|
        commit.committer && commit.committer.login == @user.login
      end

      if latest_commit.nil?
        LOGGER.error "No commit from '#{@user.login}' is found in '#{@repo}'"
        exit
      end

      @latest_user_commit = latest_commit
    end

    def update_draft_release
      commit_message = Content.new(latest_user_commit.commit.message).title

      line = "#{commit_message} #{latest_user_commit.sha}"
      LOGGER.info "Prepare to insert line: #{line}"

      body = Content.new(draft_release.body)

      if body.include? latest_user_commit.sha
        LOGGER.warn "Commit SHA '#{latest_user_commit.sha}' already exists"
        exit
      end

      if body.headings.empty?
        body.append(line)
      else
        line_num = ask_where_to_insert_line(body)
        body.insert(line_num, line)
      end

      puts '##################################################'
      puts draft_release.name
      puts '=================================================='
      puts body.to_s
      puts '##################################################'

      if ask_confirmation == false
        LOGGER.warn('Update cancelled')
        exit
      end

      LOGGER.info("Update to URL: #{draft_release.url}")
      @client.update_release(draft_release.url, body: body.to_s)

      LOGGER.info("Update draft release completed!")
      `open #{draft_release.html_url}` if @opts[:open_url_after_update]
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

    def ask_confirmation
      return true if @opts[:skip_confirmation]

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

    def append(line)
      @lines << '' << line
    end

    def insert(line_num, line)
      if line_num == 0
        @lines[line_num,0] = line
      else
        @lines[line_num,0] = ['', line]
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
