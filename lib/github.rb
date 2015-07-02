require 'Octokit'

module UpdateDraftRelease
  class Github
    attr_reader :client, :repo

    def self.open(repository)
      Github.new(repository)
    end

    def initialize(repository)
      @client = Octokit::Client.new(netrc: true)
      @repo = repository
    end

    def user
      @user ||= @client.user
    end

    def releases
      return @releases if defined?(@releases)
      @releases = @client.releases(@repo)
    end

    def draft_releases
      releases.select { |release| release.draft }
    end

    def update_release(release, body)
      @client.update_release(release.url, body: body.to_s)
    end

    def commits
      return @commits if defined?(@commits)
      @commits = @client.commits(@repo)
    end

    def user_commits
      commits.select do |commit|
        commit.committer && commit.committer.login == user.login
      end
    end
  end
end
