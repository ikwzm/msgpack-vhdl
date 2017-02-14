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
          signal    proc_run_request      :  std_logic;
          signal    proc_run_busy         :  std_logic;
          signal    proc_run_done         :  std_logic;
      EOT
    )
  end

  def generate_method_signals(registory)
    method_signals = Hash.new
    method_signals[:req    ] = "proc_run_request"
    method_signals[:ack    ] = "proc_run_busy"
    method_signals[:running] = "open"
    method_signals[:done   ] = "proc_run_done"
    method_signals[:busy   ] = "proc_run_busy"
    return method_signals
  end

  def generate_method_stmt(indent, name, method_signals, registory)
    return string_to_lines(
      indent, <<"      EOT"
          process(#{registory[:clock]}, #{registory[:reset]}) begin
              if (#{registory[:reset]} = '1') then
                      proc_run_busy <= '0';
              elsif (#{registory[:clock]}'event and #{registory[:clock]} = '1') then
                  if    (#{registory[:clear]} = '1') then
                      proc_run_busy <= '0';
                  elsif (proc_run_busy = '0' and proc_run_request = '1') or
                        (proc_run_busy = '1' and #{registory[:run_valid]} = '0') then
                      proc_run_busy <= '1';
                  else
                      proc_run_busy <= '0';
                  end if;
              end if;
          end process;
          #{registory[:run_ready ]} <= proc_run_request;
          #{registory[:run_accept]} <= proc_run_busy;
          proc_run_done <= '1' when (proc_run_busy = '1' and #{registory[:run_valid]} = '1') else '0';
      EOT
    )
  end

  module_function :generate_method_port_list
  module_function :generate_method_decl
  module_function :generate_method_stmt
  module_function :generate_method_signals
end
