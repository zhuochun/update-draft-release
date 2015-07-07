require 'Logger'

require 'content'
require 'github'

module UpdateDraftRelease
  LOGGER = Logger.new(STDOUT)
  LOGGER.level = Logger::INFO

  class Runner
    DEFAULT_OPTIONS = { skip_confirmation: false,
                        open_url_after_update: false }

    def initialize(repo, opts = {})
      @github = Github.open(repo)
      @opts = DEFAULT_OPTIONS.merge opts

      LOGGER.info "Logged in as: #{@github.user.login}"
      LOGGER.info "Repository used: #{repo}"
    end

    def update_draft_release
      draft_release = get_draft_release
      lines = get_user_commit_lines

      body = Content.new(draft_release.body)

      if body.headings.empty?
        body.append(lines)
      else
        line_num = ask_where_to_insert_line(body)
        body.insert(line_num, lines)
      end

      unless ask_confirmation(draft_release.name, body)
        LOGGER.warn('Update cancelled')
        exit
      end

      LOGGER.info("Updating to URL: #{draft_release.url}")
      @github.update_release(draft_release, body)

      LOGGER.info("Release '#{draft_release.name}' updated!")
      `open #{draft_release.html_url}` if @opts[:open_url_after_update]
    end

    private

    def get_draft_release
      draft_releases = @github.draft_releases

      if draft_releases.empty?
        LOGGER.error "Unable to find any drafts/releases in '#{@github.repo}'"
        exit
      end

      ask_which_release(draft_releases)
    end

    def get_user_commit_lines
      if @github.user_commits.empty?
        LOGGER.error "No recent commit from '#{@github.user.login}' is found in '#{@github.repo}'"
        exit
      end

      release_bodies = @github.releases.map(&:body).join

      lines = @github.user_commits.map do |commit|
        line = "#{Content.new(commit.commit.message).title} #{commit.sha}"

        if release_bodies.include?(commit.sha[0..6])
          LOGGER.warn "Commit '#{line}' exists"
          next nil
        end

        LOGGER.info "Prepare to insert line: #{line}"
        line
      end.compact

      if lines.empty?
        LOGGER.error "All commits already added in releases"
        exit
      end

      lines
    end

    def ask_which_release(releases)
      return releases.first if releases.size == 1

      puts '##################################################'
      puts 'Please select insert position: '
      puts '##################################################'
      releases.each_with_index do |release, i|
        puts "#{i} -> #{release.name}"
      end

      print 'Enter number: '
      releases[$stdin.gets.chomp.to_i]
    end

    def ask_where_to_insert_line(body)
      return body.lines.size if @opts[:insert_at_the_end]

      if @opts.has_key?(:insert_into)
        heading_line_numbers = []
        next_heading_index = 0
        heading_found = @opts[:insert_into] == 'top-level' || false

        for i in 0...body.lines.size
          if body.lines[i] =~ /^## /
            heading_line_numbers.push(i)
            if body.lines[i] =~ /#{@opts[:insert_into]}/i
              next_heading_index = heading_line_numbers.size
              heading_found = true
            end
          end
        end

        if heading_found
          if heading_line_numbers.size > next_heading_index
            return heading_line_numbers[next_heading_index] - 1
          else
            return body.lines.size
          end
        elsif @opts[:create_heading]
          body.append(["## #{@opts[:insert_into].capitalize} ##"])
          return body.lines.size
        end
      end

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

    def ask_confirmation(name, body)
      puts '##################################################'
      puts name
      puts '=================================================='
      puts body.to_s
      puts '##################################################'

      return true if @opts[:skip_confirmation]

      print 'Ok? (Y/N): '
      $stdin.gets.chomp.upcase == 'Y'
    end
  end
end
