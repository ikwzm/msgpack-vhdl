module MsgPack_RPC_Interface::VHDL::Procedure::Method::Polyphony
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_method_port_list(master, registory)
    vhdl_lines = Array.new
    req_out = (master) ? "out" : "in"
    req_in  = (master) ? "in"  : "out"
    add_port_line(vhdl_lines, registory, :run_ready , req_out,  "std_logic")
    add_port_line(vhdl_lines, registory, :run_accept, req_out,  "std_logic")
    add_port_line(vhdl_lines, registory, :run_valid , req_in ,  "std_logic")
    return vhdl_lines
  end
    
  def generate_method_decl(indent, name, registory)
    return string_to_lines(
      indent, <<"      EOT"
          signal    proc_run_req_valid    :  std_logic;
          signal    proc_run_res_valid    :  std_logic;
          signal    proc_run_res_ready    :  std_logic;
      EOT
    )
  end

  def generate_method_signals(registory)
    method_signals = Hash.new
    method_signals[:req_valid] = "proc_run_req_valid"
    method_signals[:req_ready] = "'1'"
    method_signals[:res_valid] = "proc_run_res_valid"
    method_signals[:res_ready] = "proc_run_res_ready"
    method_signals[:running  ] = "open"
    return method_signals
  end

  def generate_method_stmt(indent, name, method_signals, registory)
    return string_to_lines(
      indent, <<"      EOT"
          #{registory[:run_ready ]} <= proc_run_req_valid;
          #{registory[:run_accept]} <= proc_run_res_ready;
          proc_run_res_valid <= '1' when (proc_run_res_ready = '1' and #{registory[:run_valid]} = '1') else '0';
      EOT
    )
  end

  module_function :generate_method_port_list
  module_function :generate_method_decl
  module_function :generate_method_stmt
  module_function :generate_method_signals
end
