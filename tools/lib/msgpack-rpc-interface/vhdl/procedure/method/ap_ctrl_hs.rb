module MsgPack_RPC_Interface::VHDL::Procedure::Method::AP_CTRL_HS
  extend MsgPack_RPC_Interface::VHDL::Util
  
  def generate_method_port_list(master, registory)
    vhdl_lines = Array.new
    req_out = (master) ? "out" : "in"
    req_in  = (master) ? "in"  : "out"
    add_port_line(vhdl_lines, registory, :ap_start, req_out,  "std_logic")
    add_port_line(vhdl_lines, registory, :ap_idle , req_in ,  "std_logic")
    add_port_line(vhdl_lines, registory, :ap_ready, req_in ,  "std_logic")
    add_port_line(vhdl_lines, registory, :ap_done , req_in ,  "std_logic")
    return vhdl_lines
  end
    
  def generate_method_decl(indent, name, registory)
    return string_to_lines(
      indent, <<"      EOT"
          signal    proc_run_busy         :  std_logic;
      EOT
    )
  end

  def generate_method_signals(registory)
    method_signals = Hash.new
    method_signals[:req    ] = registory[:ap_start]
    method_signals[:ack    ] = "proc_run_busy"
    method_signals[:running] = "open"
    method_signals[:done   ] = registory[:ap_done]
    method_signals[:busy   ] = "proc_run_busy"
    return method_signals
  end

  def generate_method_stmt(indent, name, method_signals, registory)
    return string_to_lines(
      indent, <<"      EOT"
          #{method_signals[:busy]} <= '1' when (#{registory[:ap_idle]} = '0') else '0';
      EOT
    )
  end
  module_function :generate_method_port_list
  module_function :generate_method_decl
  module_function :generate_method_stmt
  module_function :generate_method_signals
end
