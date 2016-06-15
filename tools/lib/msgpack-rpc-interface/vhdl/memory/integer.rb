module MsgPack_RPC_Interface::VHDL::Memory::Integer
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_port_list(master, data_type, kvmap, registory)
    addr_type      = registory[:addr_type]
    addr_type_name = addr_type.vhdl_type
    data_type_name = data_type.vhdl_type
    vhdl_lines = Array.new
    w_out = (master) ? "out" : "in"
    w_in  = (master) ? "in"  : "out"
    r_in  = (master) ? "in"  : "out"
    r_out = (master) ? "out" : "in"
    add_port_line(vhdl_lines, registory, :store_addr , w_out,  "#{addr_type_name}")
    add_port_line(vhdl_lines, registory, :store_data , w_out,  "#{data_type_name}")
    add_port_line(vhdl_lines, registory, :store_valid, w_out,  "std_logic"        )
    add_port_line(vhdl_lines, registory, :query_addr , w_out,  "#{addr_type_name}")
    add_port_line(vhdl_lines, registory, :query_data , r_in ,  "#{data_type_name}")
    return vhdl_lines
  end

  module_function :generate_port_list

  require_relative 'integer/store'
  require_relative 'integer/query'

end
