class Paragraph < ActiveRecord::Base
  belongs_to :document
  belongs_to :parent, :class_name => 'Paragraph'
  has_many :children, :class_name => 'Paragraph', :foreign_key => 'parent_id', :order => 'position', :dependent => :destroy
  
  acts_as_list :scope => [:document_id, :parent_id]
  
  before_create :set_document_id
  def set_document_id
    if parent
      self.document_id ||= parent.document_id
    end
  end
  
  attr_accessor :before_id, :after_id
  
  after_create :set_parent_and_position
  def set_parent_and_position
    if before_id.present?
      sibling = self.class.find(before_id)
      self.update_attribute(:parent_id, sibling.parent_id)
      insert_at(sibling.position)
    elsif after_id.present?
      sibling = self.class.find(after_id)
      self.update_attribute(:parent_id, sibling.parent_id)
      insert_at(self.class.find(after_id).position + 1)
    end
  end
  
  def full_index
    ancestors.unshift(self).reverse.map(&:position).join('.')
  end
  
  def ancestors
    node = self
    nodes = []
    nodes.push(node = node.parent) while node.parent
    nodes
  end
end
