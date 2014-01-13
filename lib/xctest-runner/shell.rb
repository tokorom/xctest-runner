# -*- encoding: utf-8 -*-

module Shell

  def execute_command(command)
    puts "$ #{command}\n\n"
    `#{command}`
  end

end
