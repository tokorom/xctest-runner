# -*- encoding: utf-8 -*-

require 'xctest-runner/version'
require 'xctest-runner/build-environment'
require 'xctest-runner/shell'

class XCTestRunner
  include BuildEnvironment
  include Shell
  
  def initialize(opts = {})
    @clean = opts[:clean] || false
    @scheme = opts[:scheme] || nil
    @workspace = opts[:workspace] || nil
    @project = opts[:project] || nil
    @target = opts[:target] || nil
    @sdk = opts[:sdk] || 'iphonesimulator'
    @arch = opts[:arch] || 'x86_64'
    @configuration = opts[:configuration] || 'Debug'
    @test_class = opts[:test] || 'Self'

    @env = current_environment(build_command)
  end

  def xcodebuild
    "xcodebuild"
  end

  def xctest
    if @xctest.nil?
      @xctest = "#{@env['SDK_DIR']}/Developer/usr/bin/xctest"
    end
    @xctest
  end

  def clean_command
    "#{xcodebuild} clean #{xcodebuild_option}"
  end

  def build_command
    "#{xcodebuild} #{xcodebuild_option}"
  end

  def test_command(test_class = 'Self')
    configure_environment(build_command)
    additional_options = "-NSTreatUnknownArgumentsAsOpen NO -ApplePersistenceIgnoreState YES"
    bundle_path = "#{@env['BUILT_PRODUCTS_DIR']}/#{@env['FULL_PRODUCT_NAME']}"
    "#{xctest} -XCTest #{test_class} #{additional_options} #{bundle_path}"
  end

  def xcodebuild_option
    (@scheme ? "-scheme #{@scheme} " : '') +
    (@workspace ? "-workspace #{@workspace} " : '') +
    (@project ? "-project #{@project} " : '') +
    (@target ? "-target #{@target} " : '') +
    "-sdk #{@sdk} -arch #{@arch} -configuration #{@configuration}"
  end

  def clean
    execute_command(clean_command)
  end

  def build
    execute_command(build_command)
  end

  def test(test_class)
    command = test_command(test_class)
    execute_command("#{command}")
  end

  def run
    clean if @clean
    build
    test(@test_class)
  end

end
