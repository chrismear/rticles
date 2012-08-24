module DocumentMacros
  def stub_outline(outline=[])
    @document ||= Rticles::Document.create
    i = 0
    while i < outline.length
      tlp = @document.top_level_paragraphs.create(:body => outline[i].to_s)
      if outline[i + 1].is_a?(Array)
        stub_child_paragraphs(tlp, outline[i + 1])
        i += 2
      else
        i += 1
      end
    end
    @document
  end

  def stub_child_paragraphs(p, outline)
    document = p.document
    i = 0
    while i < outline.length
      sp = document.paragraphs.create(:body => outline[i].to_s, :parent_id => p.id)
      if outline[i + 1].is_a?(Array)
        stub_child_paragraphs(sp, outline[i + 1])
        i += 2
      else
        i += 1
      end
    end
  end
end
