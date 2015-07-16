module UpdateDraftRelease
  class Content
    HEADING_REGEX = /^\s*#+\s+.+/

    attr_reader :body, :line_separator, :lines

    def initialize(body)
      @body = body
      @line_separator = if body =~ /(\r\n|\n)/ then $1 else %(\r\n) end
      @lines = body.split(@line_separator)
    end

    def title
      @lines.first[0].upcase + @lines.first[1..-1]
    end

    def headings
      @lines.select { |line| line.match(HEADING_REGEX) }
    end

    def heading_indexes
      @lines.each_index.select { |i| @lines[i].match(HEADING_REGEX) }
    end

    def find_heading(heading)
      @lines.index { |line| line.match(/^\s*#+\s+.*#{heading}.*/i)  }
    end

    def append(new_lines)
      insert(@lines.size, new_lines)
    end

    def insert(line_num, new_lines)
      if line_num == 0 || @lines[line_num - 1].strip.empty?
        @lines[line_num,0] = Array(new_lines).flat_map { |line| [line, ''] }
      else
        @lines[line_num,0] = Array(new_lines).flat_map { |line| ['', line] }
      end
    end

    def include?(sha)
      @body.include?(sha)
    end

    def to_s
      @lines.join(@line_separator)
    end
  end
end
