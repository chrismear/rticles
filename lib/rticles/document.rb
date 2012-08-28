require 'yaml'

module Rticles
  class Document < ActiveRecord::Base
    NAME_RE = /\A#rticles#name#([A-Za-z_]+) /
    TOPIC_RE = /\A#rticles#topic#([A-Za-z_]+) /
    CONTINUATION_RE = /\A#rticles#continue /
    HEADING_RE = /\A#rticles#heading(#\d+|) /

    has_many :paragraphs, :order => 'position'
    has_many :top_level_paragraphs, :class_name => 'Paragraph', :order => 'position', :conditions => "parent_id IS NULL"

    alias_method :children, :paragraphs

    attr_accessor :insertions, :choices

    after_initialize :after_initialize
    def after_initialize
      set_up_insertions
      set_up_choices
    end

    def set_up_insertions
      self.insertions ||= {}
      self.insertions = insertions.with_indifferent_access
    end

    def set_up_choices
      self.choices ||= {}
      self.choices = choices.with_indifferent_access
    end

    def outline(options={})
      options = options.with_indifferent_access
      for_display = options[:for_display]

      o = []
      top_level_paragraphs.each do |tlp|
        body = for_display ? tlp.body_for_display({:insertions => insertions, :choices => choices}.merge(options)) : tlp.body
        if body
          o.push(for_display ? tlp.body_for_display({:insertions => insertions, :choices => choices}.merge(options)) : tlp.body)
          unless tlp.children.empty?
            o.push(sub_outline(tlp, options))
          end
        end
      end
      o
    end

    def to_html
      html = "<section>"
      html += Rticles::Paragraph.generate_html(top_level_paragraphs, :insertions => insertions, :choices => choices)
      html += "</section>"
      html.html_safe
    end

    def to_yaml
      outline.to_yaml
    end

    def self.from_yaml(yaml)
      parsed_yaml = YAML.load(yaml)
      document = self.new

      build_paragraphs_from_array(document.paragraphs, parsed_yaml)

      document
    end

    def self.build_paragraphs_from_array(paragraphs_relation, array)
      array.each do |text_or_sub_array|
        case text_or_sub_array
        when String
          name = nil
          topic = nil
          continuation = false
          heading = nil

          if name_match = text_or_sub_array.match(NAME_RE)
            text_or_sub_array = text_or_sub_array.sub(NAME_RE, '')
            name = name_match[1]
          end

          if topic_match = text_or_sub_array.match(TOPIC_RE)
            text_or_sub_array = text_or_sub_array.sub(TOPIC_RE, '')
            topic = topic_match[1]
          end

          if text_or_sub_array.match(CONTINUATION_RE)
            text_or_sub_array = text_or_sub_array.sub(CONTINUATION_RE, '')
            continuation = true
          end

          if heading_match = text_or_sub_array.match(HEADING_RE)
            text_or_sub_array = text_or_sub_array.sub(HEADING_RE, '')
            if heading_match[1].empty?
              heading = 1
            else
              heading = heading_match[1].sub(/\A#/, '').to_i
            end
          end
          paragraphs_relation << Rticles::Paragraph.new(
            :body => text_or_sub_array,
            :name => name,
            :topic => topic,
            :heading => heading,
            :continuation => continuation
          )
        when Array
          if paragraphs_relation.empty?
            raise RuntimeError, "jump in nesting at: #{text_or_sub_array.first}"
          end
          build_paragraphs_from_array(paragraphs_relation.last.children, text_or_sub_array)
        end
      end
    end

    def paragraph_for_reference(raw_reference)
      # TODO optimise
      Rails.logger.debug("Finding raw reference: #{raw_reference}")
      paragraphs.all.detect{|p| p.full_index == raw_reference}
    end

  protected

    def sub_outline(p, options={})
      options = options.with_indifferent_access
      for_display = options[:for_display]

      o = []
      p.children.each do |c|
        body = for_display ? c.body_for_display({:insertions => insertions, :choices => choices}.merge(options)) : c.body
        if body
          o.push(body)
          unless c.children.empty?
            o.push(sub_outline(c, options))
          end
        end
      end
      o
    end
  end
end
