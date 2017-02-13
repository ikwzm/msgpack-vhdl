module MsgPack_RPC_Interface::VHDL::Procedure::Method::Synthesijer
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_method_port_list(master, registory)
    vhdl_lines = Array.new
    req_out = (master) ? "out" : "in"
    req_in  = (master) ? "in"  : "out"
    add_port_line(vhdl_lines, registory, :run_req , req_out,  "std_logic")
    add_port_line(vhdl_lines, registory, :run_busy, req_in ,  "std_logic")
    add_port_line(vhdl_lines, registory, :run_done, req_in ,  "std_logic")
    return vhdl_lines
  end
    
  def generate_method_decl(indent, name, registory)
    return []
  end

  def generate_method_signals(registory)
    method_signals = Hash.new
    method_signals[:req    ] = registory.fetch(:run_req , "open")
    method_signals[:ack    ] = registory.fetch(:run_busy, "'1'" )
    method_signals[:running] = "open"
    method_signals[:done   ] = registory.fetch(:run_done, "'0'" )
    method_signals[:busy   ] = registory.fetch(:run_busy, "'0'" )
    return method_signals
  end

  def generate_method_stmt(indent, name, method_signals, registory)
    return []
  end

  module_function :generate_method_port_list
  module_function :generate_method_decl
  module_function :generate_method_stmt
  module_function :generate_method_signals
end
