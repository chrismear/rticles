class Document < ActiveRecord::Base
  has_many :paragraphs, :order => 'position'
  has_many :top_level_paragraphs, :class_name => 'Paragraph', :order => 'position', :conditions => "parent_id IS NULL"
  
  def outline
    o = []
    top_level_paragraphs.each do |tlp|
      o.push(tlp.body)
      unless tlp.children.empty?
        o.push(sub_outline(tlp))
      end
    end
    o
  end
  
protected
  
  def sub_outline(p)
    o = []
    p.children.each do |c|
      o.push(c.body)
      unless c.children.empty?
        o.push(sub_outline(c))
      end
    end
    o
  end
end
