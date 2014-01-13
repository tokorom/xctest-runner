# -*- encoding: utf-8 -*-

require 'systemu'

module Shell

  def execute_command(command, need_puts = false)
    status, stdout, stderr = systemu command
    if need_puts
      puts "$ #{command}\n\n"
      puts stdout
    end
    puts stderr
    stdout
  end

end
