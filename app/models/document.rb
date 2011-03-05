class Document < ActiveRecord::Base
  has_many :paragraphs, :order => 'position'
  has_many :top_level_paragraphs, :class_name => 'Paragraph', :order => 'position', :conditions => "parent_id IS NULL"
end
