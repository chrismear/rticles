# encoding: UTF-8

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

    def to_html(options={})
      html = "<section>"
      html += Rticles::Paragraph.generate_html(top_level_paragraphs,
        {
          :insertions => insertions,
          :choices => choices,
          :numbering_config => numbering_config
        }.merge(options)
      )
      html += "</section>"
      html.html_safe
    end

    def to_yaml
      outline.to_yaml
    end

    def self.from_yaml(yaml)
      parsed_yaml = YAML.load(yaml)
      document = self.create

      create_paragraphs_from_array(document, nil, parsed_yaml)

      document
    end

    def self.create_paragraphs_from_array(document, parent, array)
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
          document.paragraphs.create(
            :parent_id => parent ? parent.id : nil,
            :body => text_or_sub_array,
            :name => name,
            :topic => topic,
            :heading => heading,
            :continuation => continuation
          )
        when Array
          paragraphs_relation = parent ? parent.children : document.paragraphs.select{|p| p.parent_id.nil?}
          if paragraphs_relation.empty?
            raise RuntimeError, "jump in nesting at: #{text_or_sub_array.first}"
          end
          create_paragraphs_from_array(
            document,
            paragraphs_relation.last,
            text_or_sub_array
          )
        end
      end
    end

    def paragraph_for_reference(raw_reference)
      # TODO optimise
      Rails.logger.debug("Finding raw reference: #{raw_reference}")
      paragraphs.all.detect{|p| p.full_index == raw_reference}
    end

    def paragraph_numbers_for_topic(topic, consolidate=false)
      relevant_paragraphs = paragraphs.where(:topic => topic)
      relevant_paragraphs = relevant_paragraphs.for_choices(choices)
      paragraph_numbers = relevant_paragraphs.map{|p| p.full_index(true, choices)}.select{|i| !i.nil?}.sort

      if consolidate
        consolidate_paragraph_numbers(paragraph_numbers)
      else
        paragraph_numbers.join(', ')
      end
    end

    def numbering_config
      @numbering_config ||= Rticles::Numbering::Config.new
    end

  protected

    def consolidate_paragraph_numbers(numbers)
      numbers = numbers.sort
      consolidated_numbers = []
      current_run = []
      numbers.each do |n|
        if current_run.empty? || is_adjacent?(current_run.last, n)
          current_run.push(n)
        else
          if current_run.length == 1
            consolidated_numbers.push(current_run[0])
          else
            consolidated_numbers.push("#{current_run[0]}–#{current_run[-1]}")
          end
          current_run = [n]
        end
      end
      if current_run.length == 1
        consolidated_numbers.push(current_run[0])
      else
        consolidated_numbers.push("#{current_run[0]}–#{current_run[-1]}")
      end
      consolidated_numbers.join(', ')
    end

    def is_adjacent?(a, b)
      # TODO Make this smart enough to handle sub-numbers like '2.4', '2.6'
      b.to_i == a.to_i + 1
    end

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
