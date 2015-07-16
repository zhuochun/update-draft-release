require 'spec_helper'
require 'content'

RSpec.describe UpdateDraftRelease::Content do
  describe '#initialize' do
    it 'parse body with \n' do
      body = UpdateDraftRelease::Content.new %(abc Efg\nabc\n## efg)
      expect(body.lines).to eq(['abc Efg', 'abc', '## efg'])
      expect(body.title).to eq('Abc Efg')
      expect(body.headings).to eq(['## efg'])
      expect(body.heading_indexes).to eq([2])
    end

    it 'parse body with \r\n' do
      body = UpdateDraftRelease::Content.new %(abc\r\n## efg\r\nabc)
      expect(body.lines).to eq(['abc', '## efg', 'abc'])
      expect(body.title).to eq('Abc')
      expect(body.headings).to eq(['## efg'])
      expect(body.heading_indexes).to eq([1])
    end
  end

  describe '#line_separator' do
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

  describe '#find_heading' do
    subject { UpdateDraftRelease::Content.new %(# heading 1\r\nline 2\r\nline 3\r\n## heading 2\r\nline 5) }

    it 'return nil if not found' do
      expect(subject.find_heading('line 1')).to be(nil)
    end

    it 'find in different cases' do
      expect(subject.find_heading('HEADING 1')).to eq(0)
    end

    it 'find in different heading level' do
      expect(subject.find_heading('heading 2')).to eq(3)
    end
  end

  describe '#append' do
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

  describe '#insert' do
    subject { UpdateDraftRelease::Content.new %(line 1\nline 2\n\nline 3\n) }

    it 'add to the beginning' do
      subject.insert(0, 'new line')
      expect(subject.lines.size).to eq(6)
      expect(subject.lines[0]).to eq('new line')
      expect(subject.lines[1]).to eq('')
    end

    it 'add to any lines in between' do
      subject.insert(1, 'new line')
      expect(subject.lines.size).to eq(6)
      expect(subject.lines[1]).to eq('')
      expect(subject.lines[2]).to eq('new line')
    end

    it 'add to an empty line' do
      subject.insert(2, 'new line')
      expect(subject.lines.size).to eq(6)
      expect(subject.lines[2]).to eq('')
      expect(subject.lines[3]).to eq('new line')
      expect(subject.lines[4]).to eq('')
    end

    it 'add to the end' do
      subject.insert(4, 'new line')
      expect(subject.lines.size).to eq(6)
      expect(subject.lines[4]).to eq('')
      expect(subject.lines[5]).to eq('new line')
    end
  end

  describe '#include?' do
    subject { UpdateDraftRelease::Content.new %(line 1\nline 2\n) }

    it 'return true on inclusion' do
      expect(subject.include?('1')).to be(true)
    end

    it 'return false on exclusion' do
      expect(subject.include?('3')).to be(false)
    end
  end

  describe '#to_s' do
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
