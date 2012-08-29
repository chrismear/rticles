require 'roman-numerals'

module Rticles
  module Numbering
    DECIMAL = :decimal
    LOWER_ALPHA = :lower_alpha
    LOWER_ROMAN = :lower_roman

    def self.number_to_string(number, style)
      case style
      when DECIMAL
        number.to_s
      when LOWER_ALPHA
        number_to_alpha(number)
      when LOWER_ROMAN
        RomanNumerals.to_roman(number).downcase
      end
    end

    class Config
      attr_accessor :separator, :innermost_only

      def initialize
        self.separator = '.'
        @level_configs = []
      end

      def [](level)
        @level_configs[level] ||= LevelConfig.new
      end

      class LevelConfig
        attr_accessor :style, :format

        def initialize
          self.style = Rticles::Numbering::DECIMAL
          self.format = '#'
        end
      end
    end

  protected

    def self.number_to_alpha(number)
      numerator = number
      result = ''
      while numerator > 0 do
        modulo = (numerator - 1) % 26
        result = (97 + modulo).chr + result
        numerator = (numerator - modulo) / 26
      end
      result
    end

  end
end
