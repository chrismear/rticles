require 'acts_as_list'

module Rticles
  class Paragraph < ActiveRecord::Base
    attr_accessible :body, :parent_id, :after_id, :position, :before_id, :heading, :continuation,
      :name, :topic

    belongs_to :document
    belongs_to :parent, :class_name => 'Paragraph'
    has_many :children, :class_name => 'Paragraph', :foreign_key => 'parent_id', :order => 'position', :dependent => :destroy

    acts_as_list :scope => [:document_id, :parent_id]

    scope :for_choices, lambda {|choices|
        choices_condition = ["", {}]
        choices.each do |k, v|
          choices_condition[0] += "AND body NOT LIKE :#{k}"
          choices_condition[1][k.to_sym] = "#rticles##{v ? 'false' : 'true'}##{k}%"
        end
        choices_condition[0].sub!(/\AAND /, '')
        where(choices_condition)
    }

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

    def heading?
      heading && heading > 0
    end

    def heading_level
      ancestors.length + (heading ? heading : 0)
    end

    def level
      ancestors.length + 1
    end

    def index(choices=nil)
      return nil if heading? || continuation?

      predecessors = higher_items.where(['(heading = 0 OR heading IS NULL) AND (continuation = ? OR continuation IS NULL)', false])

      if choices.present?
        predecessors = predecessors.for_choices(choices)
      end

      predecessors.count + 1
    end

    def full_index(recalculate=false, choices=nil, numbering_config=nil)
      return nil if heading? || continuation?

      return @full_index if @full_index && !recalculate

      if numbering_config.nil?
        numbering_config = Rticles::Numbering::Config.new
      end

      if numbering_config.innermost_only
        @full_index = numbering_config[level].format.sub('#', Rticles::Numbering.number_to_string(index(choices), numbering_config[level].style))
      else
        @full_index = ancestors.unshift(self).reverse.map do |p|
          numbering_config[p.level].format.sub('#', Rticles::Numbering.number_to_string(p.index(choices), numbering_config[p.level].style))
        end
        @full_index = @full_index.join(numbering_config.separator)
      end
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

    def higher_items
      return nil unless in_list?
      acts_as_list_class.where(
        "#{scope_condition} AND #{position_column} < #{(send(position_column).to_i).to_s}"
      )
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
      options = options.with_indifferent_access

      if options[:insertions]
        @insertions = options[:insertions]
      end

      if options[:choices]
        @choices = options[:choices]
      end

      with_meta_characters = options[:with_meta_characters] || false

      result = resolve_choices(body)
      return result if result.nil?

      result = resolve_references(result, with_meta_characters)
      result = resolve_insertions(result)

      if options[:with_index] && full_index(true, choices, options[:numbering_config])
        result = "#{full_index} #{result}"
      end

      result
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

    def resolve_choices(string)
      choice_re = /\A#rticles#(true|false)#([A-Za-z_]+) /
      match = string.match(choice_re)
      return string if !match

      choice_name = match[2]
      choice_parameter = match[1]

      if (choices[choice_name] && choice_parameter == 'true') || (!choices[choice_name] && choice_parameter == 'false')
        string.sub(choice_re, '')
      else
        nil
      end
    end

    def prepare_for_editing
      self.body = body_with_resolved_references(true)
      self
    end

    def self.generate_html(paragraphs, options={})
      paragraph_groups = []
      paragraphs.each do |paragraph|
        if paragraph.continuation?
          paragraph_groups.last.push(paragraph)
        else
          paragraph_groups.push([paragraph])
        end
      end
      generate_html_for_paragraph_groups(paragraph_groups, options)
    end

  protected

    def self.generate_html_for_paragraph_groups(paragraph_groups, options={})
      previous_type = nil
      html = paragraph_groups.inject("") do |memo, paragraph_group|
        # FIXME: Don't generate HTML by interpolating into a string;
        # use some standard library function that provides some safe
        # escaping defaults, etc..
        if paragraph_group.first.heading?
          if previous_type == :paragraph
            memo += "</ol>"
          end
          if paragraph_group.length == 1
            memo += generate_html_for_paragraphs(paragraph_group, options)
          else
            memo += "<hgroup>#{generate_html_for_paragraphs(paragraph_group, options)}</hgroup>"
          end
          previous_type = :heading
        else
          unless previous_type == :paragraph
            memo += "<ol>"
          end
          if paragraph_group[0] && !paragraph_group[0].heading?
            index = paragraph_group[0].index
          else
            index = nil
          end
          li_opening_tag = index ? "<li value=\"#{index}\">" : "<li>"
          memo += "#{li_opening_tag}#{generate_html_for_paragraphs(paragraph_group, options)}</li>"
          previous_type = :paragraph
        end
        memo
      end
      if previous_type == :paragraph
        html += "</ol>"
      end
    end

    def self.generate_html_for_paragraphs(paragraphs, options={})
      paragraphs.inject("") do |memo, paragraph|
        body = paragraph.body_for_display({:with_index => true}.merge(options))
        return memo if body.nil?

        if paragraph.heading?
          memo += "<h#{paragraph.heading_level}>#{body}</h#{paragraph.heading_level}>"
        else
          memo += body
        end

        if !paragraph.children.empty?
          memo += generate_html(paragraph.children, options)
        end
        memo
      end
    end

    def insertions
      return @insertions.with_indifferent_access if @insertions
      begin
        (parent || document).insertions.with_indifferent_access
      rescue NoMethodError
        raise RuntimeError, "parent was nil when finding insertions; I am: #{self.inspect}"
      end
    end

    def choices
      if @choices
        @choices.with_indifferent_access
      else
        {}.with_indifferent_access
      end
    end
  end
end
