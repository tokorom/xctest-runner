# -*- encoding: utf-8 -*-

require 'xctest-runner/shell'

module BuildEnvironment
  include Shell

  def current_environment(build_command)
    env = {}
    settings = execute_command("#{build_command} -showBuildSettings test")
    settings.each_line do |line|
      if line =~ /^\s(.*)=(.*)/
        variable, value = line.split('=')
        variable = variable.strip
        value = value.strip
        env[variable] = value if (env[variable].nil? || env[variable].empty?)
      end
    end
    env
  end

  def configure_environment(build_command)
    env = current_environment(build_command)
    env.each do |key, value|
      ENV[key] = value
    end
    ENV['DYLD_ROOT_PATH'] = ENV['SDK_DIR']
  end

  def xcodebuild_list
    execute_command("xcodebuild -list")
  end

  def default_target
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
    target ? target : 'Tests'
  end

end
