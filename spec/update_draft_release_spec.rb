require 'spec_helper'
require 'update_draft_release'

RSpec.describe UpdateDraftRelease::Runner do
  let(:user) { double(login: 'user') }
  let(:client) { double(user: user) }
  let(:draft) { double(draft: true, name: 'draft', url: 'http://draft/', html_url: 'http://draft/html', body: 'draft') }
  let(:release) { double(draft: false, name: '2015-07-02', body: 'release') }
  let(:commit) do
    double(committer: double(login: 'user'),
           commit: double(message: 'message'),
           sha: 'abc')
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(client)
  end

  context 'when no valid release' do
    let(:runner) { UpdateDraftRelease::Runner.new('repo/repo') }

    it 'exit on no release' do
      allow(client).to receive(:releases).and_return([])
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end

    it 'exit on no draft release' do
      allow(client).to receive(:releases).and_return([double(draft: false)])
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end

    it 'ask which release on multiple draft releases' do
      allow(client).to receive(:releases).and_return([draft, draft])

      expect($stdin).to receive(:gets).and_return('1')
      expect(client).to receive(:commits).and_return([])
      expect { runner.update_draft_release }.to output.to_stdout.and raise_error(SystemExit)
    end
  end

  context 'when no valid commits' do
    let(:runner) { UpdateDraftRelease::Runner.new('repo/repo') }

    before { allow(client).to receive(:releases).and_return([draft, release]) }

    it 'exit on no commits' do
      allow(client).to receive(:commits).and_return([])
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end

    it 'exit on commits already in draft' do
      allow(client).to receive(:commits).and_return([commit])
      allow(draft).to receive(:body).and_return("Message #{commit.sha}")
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end

    it 'exit on commits already in release' do
      allow(client).to receive(:commits).and_return([commit])
      allow(release).to receive(:body).and_return("Message #{commit.sha}")
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end
  end

  describe 'when things go well' do
    before do
      allow(client).to receive(:releases).and_return([release, draft, release])
      allow(client).to receive(:commits).and_return([commit])
    end

    context 'basic usage case' do
      let(:runner) do
        UpdateDraftRelease::Runner.new('repo/repo', { skip_confirmation: true })
      end

      it 'update the release' do
        expect(client).to receive(:update_release)
          .with('http://draft/', body: %(draft\r\n\r\nMessage abc))
          .and_return(true)
        runner.update_draft_release
      end
    end

    context 'with insert-at-top-level' do
      let(:runner) do
        UpdateDraftRelease::Runner.new('repo/repo', {
          skip_confirmation: true,
          insert_at_top_level: true
        })
      end

      before do
        allow(draft).to receive(:body).and_return(%(# h1\r\nCommit A\r\n# h2))
      end

      it 'update the release' do
        expect(client).to receive(:update_release)
          .with('http://draft/', body: %(Message abc\r\n\r\n# h1\r\nCommit A\r\n# h2))
          .and_return(true)
        runner.update_draft_release
      end
    end

    context 'with insert-at section' do
      let(:runner) do
        UpdateDraftRelease::Runner.new('repo/repo', {
          skip_confirmation: true,
          insert_at: 'h2'
        })
      end

      before do
        allow(draft).to receive(:body).and_return(%(# h1\r\nCommit A\r\n# h2))
      end

      it 'update the release' do
        expect(client).to receive(:update_release)
          .with('http://draft/', body: %(# h1\r\nCommit A\r\n# h2\r\n\r\nMessage abc))
          .and_return(true)
        runner.update_draft_release
      end
    end

    context 'with insert-at && create-heading' do
      let(:runner) do
        UpdateDraftRelease::Runner.new('repo/repo', {
          skip_confirmation: true,
          insert_at: 'h3',
          create_heading: true
        })
      end

      before do
        allow(draft).to receive(:body).and_return(%(# h1\r\nCommit A\r\n# h2))
      end

      it 'update the release' do
        expect(client).to receive(:update_release)
          .with('http://draft/', body: %(# h1\r\nCommit A\r\n# h2\r\n\r\n## H3 ##\r\n\r\nMessage abc))
          .and_return(true)
        runner.update_draft_release
      end
    end
  end
end
