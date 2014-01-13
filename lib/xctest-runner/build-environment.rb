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

end
