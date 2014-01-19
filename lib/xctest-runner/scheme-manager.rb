# -*- encoding: utf-8 -*-

require 'find'
require 'rexml/document'

class XCTestRunner
  module SchemeManager

    TEMP_SCHEME = 'XCTestRunnerTemp'
    TEMP_SCHEME_NAME = "#{TEMP_SCHEME}.xcscheme"

    def temp_scheme
      TEMP_SCHEME
    end

    def copy_xcscheme_if_need(scheme)
      return nil unless scheme
      scheme_path = scheme_path_for(scheme)
      return nil unless scheme_path
      find_xml_need_to_be_updated(scheme_path) do |doc|
        temp_scheme_path = File.dirname(scheme_path) << "/#{TEMP_SCHEME_NAME}"
        write_xml(doc, temp_scheme_path)
        return temp_scheme_path
      end
      nil
    end

    def scheme_path_for(scheme)
      expect = "/#{scheme}.xcscheme"
      Find.find('.') do |path|
        if path.end_with? expect
          return path
        end
      end
      nil
    end

    def find_xml_need_to_be_updated(scheme_path, &block)
      need_to_be_updated = false
      doc = REXML::Document.new(File.open(scheme_path))
      doc.elements.each('Scheme/BuildAction/BuildActionEntries/BuildActionEntry') do |element|
        if 'YES' == element.attributes['buildForTesting'] && 'NO' == element.attributes['buildForRunning']
          element.attributes['buildForRunning'] = 'YES'
          need_to_be_updated = true
        end
      end
      block.call(doc) if need_to_be_updated
    end

    def write_xml(doc, path)
      File.open(path, 'w') do |f|
        f.sync = true
        f.write(doc)
      end
    end

    def remove_scheme(path)
      File.unlink(path)
    end

  end
end
