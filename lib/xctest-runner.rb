# -*- encoding: utf-8 -*-

require 'xctest-runner/version'
require 'xctest-runner/build-environment'
require 'xctest-runner/scheme-manager'
require 'xctest-runner/shell'

class XCTestRunner
  include BuildEnvironment
  include SchemeManager
  include Shell

  def initialize(opts = {})
    @clean = opts[:clean] || false
    @scheme = opts[:scheme] || nil
    @project = opts[:project] || nil
    @workspace = opts[:workspace] || nil
    @sdk = opts[:sdk] || 'iphonesimulator'
    @configuration = opts[:configuration] || 'Debug'
    @arch = opts[:arch] || nil
    @test_class = opts[:test] || 'Self'
    @suffix = opts[:suffix] || ''

    @scheme = default_scheme(build_command) unless @scheme
    @env = current_environment(build_command)
    @arch = default_build_arch if @arch.nil?
    @build_option = nil
  end

  def sdk_root
    @sdk_root ||= @env['SDK_DIR']
  end

  def bundle_path
    executableFolderPath = find_buildable_name_for_testaction(@scheme)
    executableFolderPath = @env['EXECUTABLE_FOLDER_PATH'] unless executableFolderPath
    @bundle_path ||= "#{@env['BUILT_PRODUCTS_DIR']}/#{executableFolderPath}"
  end

  def executable_path
    @executable_path ||= "#{@env['BUILT_PRODUCTS_DIR']}/#{@env['EXECUTABLE_PATH']}"
  end

  def is_valid_arch?(arch)
    ['i386', 'x86_64'].include?(arch)
  end

  def native_arch
    unless @native_arch
      arch = `file #{executable_path}`.split(' ').last
      if is_valid_arch?(arch)
        @native_arch = arch
      else
        @native_arch = @env['CURRENT_ARCH']
      end
    end
    is_valid_arch?(@native_arch) ? @native_arch : 'i386'
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
      options << "-project #{@project}" if @project
      options << "-workspace #{@workspace}" if @workspace
      options << "-sdk #{@sdk}" if @sdk
      options << "-configuration #{@configuration}" if @configuration
      options << "-arch #{@arch} #{valid_archs}" if @arch
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
    execute_command("#{command} #{@suffix} 2>&1", true)
  end

  def run
    temp_scheme_path = copy_xcscheme_if_need(@scheme)
    @scheme = temp_scheme if temp_scheme_path

    clean if @clean
    if build
      test(@test_class)
    end

    remove_scheme(temp_scheme_path) if temp_scheme_path
  end

end
