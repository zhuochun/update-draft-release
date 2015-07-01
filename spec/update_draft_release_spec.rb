require 'spec_helper'
require 'update_draft_release'

RSpec.describe UpdateDraftRelease do
  let(:logger) { double() }
  let(:user) { double(login: 'user') }
  let(:client) { double(user: user) }
  let(:draft) { double(draft: true, body: '') }
  let(:commit) do
    double(committer: double(login: 'user'),
           commit: double(message: 'message'),
           sha: 'abc')
  end

  before do
    allow(Logger).to receive(:new).and_return(logger)
    allow(Octokit::Client).to receive(:new).and_return(client)
  end

  context 'update_draft_release without valid release' do
    let(:runner) { UpdateDraftRelease::Runner.new('repo/repo') }

    it 'exit on no release' do
      allow(client).to receive(:releases).and_return([])
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end

    it 'exit on no draft release' do
      allow(client).to receive(:releases).and_return([double(draft: false)])
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end
  end

  context 'update_draft_release without valid commits' do
    let(:runner) { UpdateDraftRelease::Runner.new('repo/repo') }

    before { allow(client).to receive(:releases).and_return([draft]) }

    it 'exit on no commits' do
      allow(client).to receive(:commits).and_return([])
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end

    it 'exit on all commits are in body' do
      allow(client).to receive(:commits).and_return([commit])
      allow(draft).to receive(:body).and_return("Message #{commit.sha}")
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end
  end
end

RSpec.describe UpdateDraftRelease::Content do
  context '#initialize' do
    it 'parse body with \n' do
      body = UpdateDraftRelease::Content.new %(abc Efg\nabc\n## efg)
      expect(body.lines).to eq(['abc Efg', 'abc', '## efg'])
      expect(body.title).to eq('Abc Efg')
      expect(body.headings).to eq(['## efg'])
    end

    it 'parse body with \r\n' do
      body = UpdateDraftRelease::Content.new %(abc\r\n## efg\r\nabc)
      expect(body.lines).to eq(['abc', '## efg', 'abc'])
      expect(body.title).to eq('Abc')
      expect(body.headings).to eq(['## efg'])
    end
  end

  context '#line_separator' do
    context 'no line_separator exists' do
      subject { UpdateDraftRelease::Content.new(%(line 1)).line_separator }
      it { is_expected.to eq(%(\r\n)) }
    end

    context 'line_separator exists' do
      subject { UpdateDraftRelease::Content.new(%(line 1\nline 2)).line_separator }
      it { is_expected.to eq(%(\n)) }
    end

    context 'mixed line_separator exists' do
      subject { UpdateDraftRelease::Content.new(%(line 1\nline 2\r\n)).line_separator }
      it { is_expected.to eq(%(\n)) }
    end
  end

  context '#append' do
    subject { UpdateDraftRelease::Content.new %(line 1\r\nline 2\r\n) }

    it 'add single line to the end' do
      subject.append('new line')
      expect(subject.line_separator).to eq(%(\r\n))
      expect(subject.lines.size).to eq(4)
      expect(subject.lines.last).to eq('new line')
    end

    it 'add lines to the end' do
      subject.append(['new line 1', 'new line 2'])
      expect(subject.line_separator).to eq(%(\r\n))
      expect(subject.lines.size).to eq(6)
      expect(subject.lines.last).to eq('new line 2')
    end
  end

  context '#insert' do
    subject { UpdateDraftRelease::Content.new %(line 1\nline 2\n) }

    it 'add to the beginning' do
      subject.insert(0, 'new line')
      expect(subject.lines.size).to eq(3)
      expect(subject.lines.first).to eq('new line')
    end

    it 'add to any lines in between' do
      subject.insert(1, 'new line')
      expect(subject.lines.size).to eq(4)
      expect(subject.lines[1]).to eq('')
      expect(subject.lines[2]).to eq('new line')
    end

    it 'add to the end' do
      subject.insert(2, 'new line')
      expect(subject.lines.size).to eq(4)
      expect(subject.lines[2]).to eq('')
      expect(subject.lines[3]).to eq('new line')
    end
  end

  context '#include?' do
    subject { UpdateDraftRelease::Content.new %(line 1\nline 2\n) }

    it 'return true on inclusion' do
      expect(subject.include?('1')).to be(true)
    end

    it 'return false on exclusion' do
      expect(subject.include?('3')).to be(false)
    end
  end

  context '#to_s' do
    let(:body) { %(line 1\n\nline 2) }
    subject { UpdateDraftRelease::Content.new body }

    it 'construct back itself' do
      expect(subject.to_s).to eq(body)
    end

    it 'construct correct body' do
      subject.append 'new line'
      expect(subject.to_s).to eq(body << %(\n\nnew line))
    end
  end
end
