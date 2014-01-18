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
    @configuration = opts[:configuration] || 'Debug'
    @arch = opts[:arch] || nil
    @test_class = opts[:test] || 'Self'
    @suffix = opts[:suffix] || ''

    @env = current_environment(build_command)
    @arch = default_build_arch if @arch.nil?
    @build_option = nil
  end

  def sdk_root
    @sdk_root ||= @env['SDK_DIR']
  end

  def bundle_path
    @bundle_path ||= "#{@env['BUILT_PRODUCTS_DIR']}/#{@env['EXECUTABLE_FOLDER_PATH']}"
  end

  def executable_path
    @executable_path ||= "#{@env['BUILT_PRODUCTS_DIR']}/#{@env['EXECUTABLE_PATH']}"
  end

  def native_arch
    unless @native_arch
      arch = `file #{executable_path}`.split(' ').last
      if 'i386' == arch || 'x86_64' == arch
        @native_arch = arch
      else
        @native_arch = @env['CURRENT_ARCH']
      end
    end
    @native_arch || 'i386'
  end

  def arch_command
    unless @arch_command
      @arch_command = native_arch ? "arch -arch #{native_arch}" : ''
    end
    @arch_command
  end

  def xcodebuild
    @xcodebuild ||= 'xcodebuild'
  end

  def default_build_arch
    if @env && @env && @env['VALID_ARCHS'] && @env['CURRENT_ARCH']
      @env['VALID_ARCHS'].include?(@env['CURRENT_ARCH']) ? nil : 'i386'
    end
  end

  def valid_archs
    if @env && @env['VALID_ARCHS'] && @env['CURRENT_ARCH']
      @env['VALID_ARCHS'].include?(@env['CURRENT_ARCH']) ? '' : "VALID_ARCHS=#{@arch}"
    end
  end

  def build_option
    unless @build_option
      options = []
      options << "-scheme #{@scheme}" if @scheme
      options << "-workspace #{@workspace}" if @workspace
      options << "-project #{@project}" if @project
      options << "-target #{@target}" if @target
      options << "-sdk #{@sdk}" if @sdk
      options << "-configuration #{@configuration}" if @configuration
      options << "-arch #{@arch} #{valid_archs}" if @arch
      options << "-target #{default_target}" if @scheme.nil? && @target.nil? && default_target
      @build_option = options.join(' ')
    end
    @build_option
  end


  def xctest_environment
    @xctest_environment ||= "-e DYLD_ROOT_PATH='#{sdk_root}'"
  end

  def xctest
    unless @xctest
      xctest_command = "#{@env['SDK_DIR']}/Developer/usr/bin/xctest"
      @xctest = "#{arch_command} #{xctest_environment} #{xctest_command}"
    end
    @xctest
  end

  def clean_command
    "#{xcodebuild} clean #{build_option}"
  end

  def build_command
    "#{xcodebuild} #{build_option}"
  end

  def test_command(test_class)
    xctest_command = xctest
    additional_options = "-NSTreatUnknownArgumentsAsOpen NO -ApplePersistenceIgnoreState YES"
    "#{xctest_command} -XCTest #{test_class} #{additional_options} #{bundle_path}"
  end

  def clean
    execute_command(clean_command, true)
  end

  def build
    execute_command("#{build_command} #{@suffix}", true)
  end

  def test(test_class = 'Self')
    command = test_command(test_class)
    execute_command("#{command} #{@suffix}", true)
  end

  def run
    configure_environment(build_command)
    clean if @clean
    build
    test(@test_class)
  end

end
