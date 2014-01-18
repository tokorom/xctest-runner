# -*- encoding: utf-8 -*-

require 'xctest-runner/shell'

module BuildEnvironment
  include Shell

  def current_environment(build_command)
    env = {}
    settings = execute_command("#{build_command} -showBuildSettings test")
    settings.each_line do |line|
      if line.strip.start_with?('Build settings')
        break if env.include?('EXECUTABLE_FOLDER_PATH') && env['EXECUTABLE_FOLDER_PATH'].end_with?('.xctest')
      elsif line =~ /^\s(.*)=(.*)/
        variable, value = line.split('=')
        env[variable.strip] = value.strip
      end
    end
    env
  end

  def xcodebuild_list
    execute_command("xcodebuild -list")
  end

  def default_target
    unless @default_target
      target = nil
      is_target = false

      output = xcodebuild_list
      output.each_line do |line|
        line = line.strip
        if line =~ /\w+:/
          is_target = ('Targets:' == line)
        elsif is_target
          target = line if target.nil? || line.end_with?('Tests')
        end
      end
      @default_target = target
    end
    @default_target
  end

end
