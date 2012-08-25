require 'yaml'

module Rticles
  class Document < ActiveRecord::Base
    has_many :paragraphs, :order => 'position'
    has_many :top_level_paragraphs, :class_name => 'Paragraph', :order => 'position', :conditions => "parent_id IS NULL"

    alias_method :children, :paragraphs

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
          paragraphs_relation << Rticles::Paragraph.new(:body => text_or_sub_array)
        when Array
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
end
