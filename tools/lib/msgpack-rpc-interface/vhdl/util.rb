module MsgPack_RPC_Interface::VHDL::Util

  def string_to_lines(indent, str)
    first_line_indent = str.slice(/^\s*/)
    vhdl_code_list    = Array.new
    str.split(/\n/).each do |line|
      vhdl_code_list.push(line.sub(/^#{first_line_indent}/, indent))
    end
    return vhdl_code_list
  end

  def add_generic_line(list, registory, name, type)
    if registory.key?(name) then
      if registory[name].to_s.match(/^[a-zA-Z]+/) then
        list << sprintf("%-20s : %s", registory[name], type)
      end
    end
  end
      
  def add_port_line(list, registory, name, io, type)
    if registory.key?(name) then
      if registory[name].to_s.match(/^[a-zA-Z]+/) then
        list << sprintf("%-20s : %-3s %s", registory[name], io, type)
      end
    end
  end
      
  module_function :string_to_lines
  module_function :add_generic_line
  module_function :add_port_line

end
