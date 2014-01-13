# -*- encoding: utf-8 -*-

module Shell

  def execute_command(command, need_puts = false)
    if need_puts
      puts "$ #{command}\n\n" if need_puts
      system command
    else
      `#{command}`
    end
  end

end
