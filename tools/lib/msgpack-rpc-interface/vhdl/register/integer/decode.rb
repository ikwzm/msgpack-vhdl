module MsgPack_RPC_Interface::VHDL::Register::Integer::Decode
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_decl(indent, name, type, registory)
    if type.generate_vhdl_type.match(/^std_logic_vector/) then
      return []
    else
      return string_to_lines(indent, <<"        EOT"
        signal    proc_0_value      :  std_logic_vector(#{type.width-1} downto 0);
        EOT
      )
    end
  end

  def generate_stmt(indent, name, type, registory)
    if type.generate_vhdl_type.match(/^std_logic_vector/) then
      instance_name = registory.fetch(:instance_name, "PROC_DECODE_" + name.upcase)
      o_value       = registory[:write_value]
    else
      instance_name = "PROC_0"
      o_value       = "proc_0_value"
    end
    o_sign        = registory.fetch(:write_sign   , "open")
    o_last        = registory.fetch(:write_last   , "open")
    o_valid       = registory.fetch(:write_valid  , "open")
    o_ready       = registory.fetch(:write_ready  , "'1'" )
    check_range   = registory.fetch(:check_range  , "TRUE")
    enable64      = registory.fetch(:enable64     , "TRUE")
    queue_size    = registory.fetch(:queue_size   , 0)
    value_bits    = o_value + "'length"
    value_sign    = type.sign
    vhdl_lines    = string_to_lines(
      indent, <<"      EOT"
        #{instance_name} : MsgPack_Object_Decode_Integer                          -- 
            generic map (              #{sprintf("%-28s", ""                     )}   -- 
                CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                VALUE_BITS          => #{sprintf("%-28s", value_bits             )} , --
                VALUE_SIGN          => #{sprintf("%-28s", value_sign             )} , --
                QUEUE_SIZE          => #{sprintf("%-28s", queue_size             )} , --
                CHECK_RANGE         => #{sprintf("%-28s", check_range            )} , --
                ENABLE64            => #{sprintf("%-28s", enable64               )}   --
            )                          #{sprintf("%-28s", ""                     )}   -- 
            port map (                 #{sprintf("%-28s", ""                     )}   -- 
                CLK                 => #{sprintf("%-28s", registory[:clock      ])} , -- In  :
                RST                 => #{sprintf("%-28s", registory[:reset      ])} , -- in  :
                CLR                 => #{sprintf("%-28s", registory[:clear      ])} , -- in  :
                I_CODE              => #{sprintf("%-28s", registory[:param_code ])} , -- In  :
                I_LAST              => #{sprintf("%-28s", registory[:param_last ])} , -- In  :
                I_VALID             => #{sprintf("%-28s", registory[:param_valid])} , -- In  :
                I_ERROR             => #{sprintf("%-28s", registory[:param_error])} , -- Out :
                I_DONE              => #{sprintf("%-28s", registory[:param_done ])} , -- Out :
                I_SHIFT             => #{sprintf("%-28s", registory[:param_shift])} , -- Out :
                O_VALUE             => #{sprintf("%-28s", o_value                )} , -- Out :
                O_SIGN              => #{sprintf("%-28s", o_sign                 )} , -- Out :
                O_LAST              => #{sprintf("%-28s", o_last                 )} , -- Out :
                O_VALID             => #{sprintf("%-28s", o_valid                )} , -- Out :
                O_READY             => #{sprintf("%-28s", o_ready                )}   -- In  :
            );                         #{sprintf("%-28s", ""                     )}   -- 
      EOT
    )
    if type.generate_vhdl_type.match(/^std_logic_vector/) then
      return vhdl_lines
    else
      converted_value = type.generate_vhdl_convert("proc_0_value")
      return vhdl_lines.concat(string_to_lines(indent, <<"        EOT"
        #{registory[:write_value]} <= #{converted_value};
        EOT
      ))
    end
  end

  def generate_body(indent, name, type, registory)
    if type.generate_vhdl_type.match(/^std_logic_vector/) then
      return generate_stmt(indent, name, type, registory)
    else
      block_name = registory.fetch(:instance_name, "PROC_DECODE_" + name.upcase)
      decl_lines = generate_decl(indent + "    ", name, type, registory)
      stmt_lines = generate_stmt(indent + "    ", name, type, registory)
      return ["#{indent}#{block_name}: block"] + 
             decl_lines + 
             ["#{indent}begin"] +
             stmt_lines +
             ["#{indent}end block;"]
    end
  end

  def use_package_list
    return ["MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Integer"]
  end

  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :use_package_list
end
