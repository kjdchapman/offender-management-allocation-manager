# frozen_string_literal: true

require 'nokogiri'

module Delius
  class StringCollector < Nokogiri::XML::SAX::Document
    DATA_CELL = 't'

    def initialize(&block)
      @inside_cell = false
      @block = block
    end

    def start_element(name, _attrs)
      @inside_cell = true if name == DATA_CELL
    end

    def characters(str)
      @block.call(str) if @inside_cell
      @inside_cell = false
    end

    def end_element(_name)
      @inside_cell = false
    end
  end
end
