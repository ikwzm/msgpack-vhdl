module MsgPack_RPC_Interface::VHDL::Signal::Integer
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_port_list(master, type, registory)
    type_name  = type.generate_vhdl_type
    vhdl_lines = Array.new
    w_out = (master) ? "out" : "in"
    w_in  = (master) ? "in"  : "out"
    r_in  = (master) ? "in"  : "out"
    r_out = (master) ? "out" : "in"
    add_port_line(vhdl_lines, registory, :write_value, w_out,  "#{type_name}")
    add_port_line(vhdl_lines, registory, :write_sign , w_out,  "std_logic"   )
    add_port_line(vhdl_lines, registory, :write_last , w_out,  "std_logic"   )
    add_port_line(vhdl_lines, registory, :write_valid, w_out,  "std_logic"   )
    add_port_line(vhdl_lines, registory, :write_ready, w_in ,  "std_logic"   )
    add_port_line(vhdl_lines, registory, :read_value , r_in ,  "#{type_name}")
    add_port_line(vhdl_lines, registory, :read_valid , r_in ,  "std_logic"   )
    add_port_line(vhdl_lines, registory, :read_ready , r_out,  "std_logic"   )
    return vhdl_lines
  end

  module_function :generate_port_list

  module StoreDecode
   extend MsgPack_RPC_Interface::VHDL::Util

   def generate_decl(set_method, indent, name, type, registory)
     block_regs = registory.dup
     block_regs[:write_value] = "proc_0_value"
     block_regs[:write_valid] = "proc_0_valid"
     logic_type = MsgPack_RPC_Interface::Standard::Type::Integer.new(Hash({"width" => type.width, "sign" => type.sign}))
     generator  = MsgPack_RPC_Interface::VHDL::Register::Integer.const_get(set_method)
     return string_to_lines(
       indent, <<"       EOT"
             signal    proc_0_value   :  std_logic_vector(#{type.width-1} downto 0);
             signal    proc_0_valid   :  std_logic;
       EOT
     ).concat(generator.generate_decl(indent, name, logic_type, block_regs))
   end

   def generate_stmt(set_method, indent, name, type, registory)
     block_regs = registory.dup
     block_regs[:write_value] = "proc_0_value"
     block_regs[:write_valid] = "proc_0_valid"
     conv_value = type.generate_vhdl_convert("proc_0_value")
     logic_type = MsgPack_RPC_Interface::Standard::Type::Integer.new(Hash({"width" => type.width, "sign" => type.sign}))
     generator  = MsgPack_RPC_Interface::VHDL::Register::Integer.const_get(set_method)
     return string_to_lines(
       indent, <<"       EOT"
              process(#{registory[:clock]}, #{registory[:reset]}) begin
                  if (#{registory[:reset]} = '1') then
                           #{registory[:write_value]} <= (others => '0');
                  elsif (#{registory[:clock]}'event and #{registory[:clock]} = '1') then
                      if    (#{registory[:clear]} = '1') then
                           #{registory[:write_value]} <= (others => '0');
                      elsif (proc_0_valid = '1') then
                           #{registory[:write_value]} <= #{conv_value};
                      end if;
                  end if;
              end process;
       EOT
     ).concat(generator.generate_stmt(indent, name, logic_type, block_regs))
    end

    def generate_body(set_method, indent, name, type, registory)
      block_name = registory.fetch(:instance_name, "PROC_0_" + name.upcase)
      decl_lines = generate_decl(set_method, indent + "    ", name, type, registory)
      stmt_lines = generate_stmt(set_method, indent + "    ", name, type, registory)
      return ["#{indent}#{block_name}: block"] + 
             decl_lines + 
             ["#{indent}begin"] +
             stmt_lines +
             ["#{indent}end block;"]
    end

    module_function :generate_body
    module_function :generate_decl
    module_function :generate_stmt
  end

  require_relative 'integer/store'
  require_relative 'integer/decode'

end
