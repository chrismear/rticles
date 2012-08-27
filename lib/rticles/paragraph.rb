require 'acts_as_list'

module Rticles
  class Paragraph < ActiveRecord::Base
    attr_accessible :body, :parent_id, :after_id, :position, :before_id

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

    def can_move_lower?
      !!lower_item
    end

    def can_move_higher?
      !!higher_item
    end

    def can_indent?
      !!higher_item
    end

    def indent!
      return unless can_indent?
      new_parent_id = higher_item.id
      remove_from_list
      update_attribute(:parent_id, new_parent_id)
      send(:assume_bottom_position)
    end

    def can_outdent?
      !!parent_id
    end

    def outdent!
      return unless can_outdent?
      new_parent_id = parent.parent_id
      new_position = parent.position + 1
      reparent_lower_items_under_self
      remove_from_list
      update_attribute(:parent_id, new_parent_id)
      insert_at(new_position)
    end

    def lower_items
      return nil unless in_list?
      acts_as_list_class.where(
        "#{scope_condition} AND #{position_column} > #{(send(position_column).to_i).to_s}"
      )
    end

    def reparent_lower_items_under_self
      return unless in_list?
      acts_as_list_class.update_all(
        "#{position_column} = (#{position_column} - #{position}), parent_id = #{id}", "#{scope_condition} AND #{position_column} > #{send(position_column).to_i}"
      )
    end

    before_save :normalise_references
    def normalise_references
      return if body.blank?
      raw_reference_re = /!(\d\.)*\d/
      Rails.logger.debug("Body: #{body}")
      self.body = body.gsub(raw_reference_re) do |match|
        raw_reference = match.sub('!', '')
        '#rticles#' + document.paragraph_for_reference(raw_reference).id.to_s
      end
    end

    def body_for_display(options={})
      if options[:insertions]
        @insertions = options[:insertions]
      end
      with_meta_characters = options[:with_meta_characters] || false
      result = resolve_references(body, with_meta_characters)
      resolve_insertions(result)
    end

    def body_with_resolved_references(with_meta_characters=false)
      resolve_references(body, with_meta_characters)
    end

    def resolve_references(string, with_meta_characters=false)
      return string if string.blank?
      normalised_reference_re = /#rticles#(\d+)/
      string.gsub(normalised_reference_re) do |match|
        normalised_reference = match.sub('#rticles#', '')
        result = with_meta_characters ? '!' : ''
        result += document.paragraphs.find(normalised_reference).full_index
        result
      end
    end

    def resolve_insertions(string)
      return string if string.blank?
      insertion_re = /#rticles#([A-Za-z_]+)/
      string.gsub(insertion_re) do |match|
        insertion_name = match.sub('#rticles#', '')
        if insertions[insertion_name].present?
          insertions[insertion_name]
        else
          "[#{insertion_name.humanize.upcase}]"
        end
      end
    end

    def prepare_for_editing
      self.body = body_with_resolved_references(true)
      self
    end

  protected

    def insertions
      return @insertions.with_indifferent_access if @insertions
      begin
        (parent || document).insertions.with_indifferent_access
      rescue NoMethodError
        raise RuntimeError, "parent was nil when finding insertions; I am: #{self.inspect}"
      end
    end
  end
end
