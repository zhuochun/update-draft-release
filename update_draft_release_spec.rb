require 'Rspec'
require './update_draft_release.rb'

RSpec.describe UpdateDraftRelease do
  let(:client) { double() }
  let(:user) { double() }
  let(:repo) { 'random/repo' }
  let(:latest_release) { double() }
  let(:latest_commit) { double() }
  let(:release_body) { double() }

  before do
    allow(Octokit::Client).to receive(:new).and_return(client)
    allow(client).to receive(:user).and_return(user)
  end

  context 'true' do
    it 'is true' do
      expect(true).to eq(true) # lah
    end
  end
end

RSpec.describe UpdateDraftRelease::ReleaseBody do
  context '#initialize' do
    it 'parse body with \n' do
      body = UpdateDraftRelease::ReleaseBody.new %(abc\nabc\n## efg)
      expect(body.lines).to eq(['abc', 'abc', '## efg'])
      expect(body.headings).to eq(['## efg'])
    end

    it 'parse body with \r\n' do
      body = UpdateDraftRelease::ReleaseBody.new %(abc\r\n## efg\r\nabc)
      expect(body.lines).to eq(['abc', '## efg', 'abc'])
      expect(body.headings).to eq(['## efg'])
    end
  end

  context '#append' do
    subject { UpdateDraftRelease::ReleaseBody.new %(line 1\nline 2\n) }

    it 'add to the end' do
      subject.append('new line') 
      expect(subject.lines.size).to eq(4)
      expect(subject.lines.last).to eq('new line')
    end
  end

  context '#insert' do
    subject { UpdateDraftRelease::ReleaseBody.new %(line 1\nline 2\n) }

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
    subject { UpdateDraftRelease::ReleaseBody.new %(line 1\nline 2\n) }

    it 'return true on inclusion' do
      expect(subject.include?('1')).to be(true)
    end

    it 'return false on exclusion' do
      expect(subject.include?('3')).to be(false)
    end
  end

  context '#to_s' do
    let(:body) { %(line 1\n\nline 2) }
    subject { UpdateDraftRelease::ReleaseBody.new body }

    it 'construct back itself' do
      expect(subject.to_s).to eq(body)
    end

    it 'construct correct body' do
      subject.append 'new line'
      expect(subject.to_s).to eq(body << %(\n\nnew line))
    end
  end
end
