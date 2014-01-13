# -*- encoding: utf-8 -*-

module Shell

  def execute_command(command, need_puts = false)
    puts "$ #{command}\n\n" if need_puts
    `#{command}`
  end

end
