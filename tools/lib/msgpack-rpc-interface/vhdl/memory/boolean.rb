module MsgPack_RPC_Interface::VHDL::Memory::Boolean
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_port_list(master, data_type, kvmap, registory)
    data_type_name  = data_type.class.to_s.split('::').last
    data_type = MsgPack_RPC_Interface::Standard::Type.new(Hash({"name" => data_type_name, "width" => registory[:width]*data_type.bits}))
    strb_type = MsgPack_RPC_Interface::Standard::Type.new(Hash({"name" => "Logic_Vector", "width" => registory[:width]}))
    addr_type = registory[:addr_type]
    size_type = registory[:size_type]
    addr_type_name = addr_type.vhdl_type
    size_type_name = size_type.vhdl_type
    data_type_name = data_type.vhdl_type
    strb_type_name = strb_type.vhdl_type
    vhdl_lines = Array.new
    w_out = (master) ? "out" : "in"
    w_in  = (master) ? "in"  : "out"
    r_in  = (master) ? "in"  : "out"
    r_out = (master) ? "out" : "in"
    add_port_line( vhdl_lines, registory, :store_addr  , w_out,  "#{addr_type_name}" )
    add_port_line( vhdl_lines, registory, :store_data  , w_out,  "#{data_type_name}" )
    add_port_line( vhdl_lines, registory, :store_strb  , w_out,  "#{strb_type_name}" )
    add_port_line( vhdl_lines, registory, :store_valid , w_out,  "std_logic"         )
    add_port_line( vhdl_lines, registory, :store_ready , w_in ,  "std_logic"         )
    add_port_line( vhdl_lines, registory, :query_addr  , w_out,  "#{addr_type_name}" )
    add_port_line( vhdl_lines, registory, :query_data  , r_in ,  "#{data_type_name}" )
    add_port_line( vhdl_lines, registory, :query_valid , r_in ,  "std_logic"         )
    add_port_line( vhdl_lines, registory, :query_ready , r_out,  "std_logic"         )
    add_port_line( vhdl_lines, registory, :query_enable, r_out,  "std_logic"         )
    add_port_line( vhdl_lines, registory, :default_size, r_in ,  "#{size_type_name}" )
    return vhdl_lines
  end

  module_function :generate_port_list

  require_relative 'boolean/store'
  require_relative 'boolean/query'

end
