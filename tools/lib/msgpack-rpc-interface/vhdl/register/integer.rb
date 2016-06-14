module MsgPack_RPC_Interface::VHDL::Register::Integer
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_port_list(master, type, kvmap, registory)
    type_name  = type.generate_vhdl_type
    vhdl_lines = Array.new
    w_out = (master) ? "out" : "in"
    w_in  = (master) ? "in"  : "out"
    r_in  = (master) ? "in"  : "out"
    r_out = (master) ? "out" : "in"
    add_port_line(vhdl_lines, registory, :store_data , w_out,  "#{type_name}")
    add_port_line(vhdl_lines, registory, :store_sign , w_out,  "std_logic"   )
    add_port_line(vhdl_lines, registory, :store_last , w_out,  "std_logic"   )
    add_port_line(vhdl_lines, registory, :store_valid, w_out,  "std_logic"   )
    add_port_line(vhdl_lines, registory, :store_ready, w_in ,  "std_logic"   )
    add_port_line(vhdl_lines, registory, :query_data , r_in ,  "#{type_name}")
    add_port_line(vhdl_lines, registory, :query_valid, r_in ,  "std_logic"   )
    add_port_line(vhdl_lines, registory, :query_ready, r_out,  "std_logic"   )
    return vhdl_lines
  end

  module_function :generate_port_list

  require_relative 'integer/store'
  require_relative 'integer/query'

end
