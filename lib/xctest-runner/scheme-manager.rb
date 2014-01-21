# -*- encoding: utf-8 -*-

require 'find'
require 'rexml/document'

class XCTestRunner
  module SchemeManager

    TEMP_SCHEME = 'XCTestRunnerTemp'
    TEMP_SCHEME_NAME = "#{TEMP_SCHEME}.xcscheme"

    BUILD_ACTION_TAG = 'Scheme/BuildAction'
    BUILD_ACTION_ENTRY_TAG = 'Scheme/BuildAction/BuildActionEntries/BuildActionEntry'
    TEST_REFERENCE_TAG = 'Scheme/TestAction/Testables/TestableReference/BuildableReference'

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
      if doc.get_elements(BUILD_ACTION_ENTRY_TAG).empty?
        need_to_be_updated = add_build_action_entry_to(doc)
      else
        doc.elements.each(BUILD_ACTION_ENTRY_TAG) do |element|
          if element.attributes['buildForTesting'] != element.attributes['buildForRunning']
            element.attributes['buildForRunning'] = element.attributes['buildForTesting']
            need_to_be_updated = true
          end
        end
      end
      block.call(doc) if need_to_be_updated
    end

    def add_build_action_entry_to(doc)
      buildable_reference = doc.get_elements(TEST_REFERENCE_TAG).first
      return false unless buildable_reference
      build_action = doc.get_elements(BUILD_ACTION_TAG).first
      return false unless build_action
      entries = build_action.add_element('BuildActionEntries')
      attributes = {
        'buildForTesting' => 'YES',
        'buildForRunning' => 'YES',
        'buildForProfiling' => 'NO',
        'buildForArchiving' => 'NO',
        'buildForAnalyzing' => 'NO',
      }
      entry = entries.add_element('BuildActionEntry', attributes)
      entry.add_element(buildable_reference.name, buildable_reference.attributes)
      true
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
