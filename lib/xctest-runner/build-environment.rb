# -*- encoding: utf-8 -*-

require 'xctest-runner/shell'

class XCTestRunner
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

    def xcodebuild_list(build_command)
      execute_command("#{build_command} -list")
    end

    def default_scheme(build_command)
      unless @default_scheme
        scheme = nil
        is_scheme = false

        output = xcodebuild_list(build_command)
        output.each_line do |line|
          line = line.strip
          if line =~ /\w+:/
            is_scheme = ('Schemes:' == line)
          elsif is_scheme
            scheme = line if scheme.nil? || line.end_with?('Tests')
          end
        end
        @default_scheme = scheme
      end
      @default_scheme
    end

  end
end
