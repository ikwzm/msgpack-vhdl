module MsgPack_RPC_Interface::VHDL::Register::Integer::Query
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_decl(indent, name, type, kvmap, registory)
    if type.generate_vhdl_type.match(/^std_logic_vector/) then
      return []
    else
      return string_to_lines(indent, <<"        EOT"
        signal    proc_1_value      :  std_logic_vector(#{type.width-1} downto 0);
        EOT
      )
    end
  end

  def generate_stmt(indent, name, type, kvmap, registory)
    if type.generate_vhdl_type.match(/^std_logic_vector/) then
      instance_name = registory.fetch(:instance_name, "PROC_QUERY_" + name.upcase)
      i_value       = registory[:read_value]
    else
      instance_name = "PROC_1"
      i_value       = "proc_1_value"
    end
    i_valid       = registory.fetch(:read_valid , "'1'" )
    i_ready       = registory.fetch(:read_ready , "open")
    value_bits    = type.width
    value_sign    = type.sign
    if kvmap == true then
      key_string  = "STRING'(\"" + name + "\")"
      vhdl_lines  = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_KVMap_Query_Integer_Register   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  KEY                 => #{sprintf("%-28s", key_string             )} , --
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                  MATCH_PHASE         => #{sprintf("%-28s", registory[:match_phase])} , --
                  VALUE_BITS          => #{sprintf("%-28s", value_bits             )} , --
                  VALUE_SIGN          => #{sprintf("%-28s", value_sign             )}   --
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
                  O_CODE              => #{sprintf("%-28s", registory[:value_code ])} , -- Out :
                  O_LAST              => #{sprintf("%-28s", registory[:value_last ])} , -- Out :
                  O_VALID             => #{sprintf("%-28s", registory[:value_valid])} , -- Out :
                  O_ERROR             => #{sprintf("%-28s", registory[:value_error])} , -- Out :
                  O_READY             => #{sprintf("%-28s", registory[:value_ready])} , -- In  :
                  MATCH_REQ           => #{sprintf("%-28s", registory[:match_req  ])} , -- In  :
                  MATCH_CODE          => #{sprintf("%-28s", registory[:match_code ])} , -- In  :
                  MATCH_OK            => #{sprintf("%-28s", registory[:match_ok   ])} , -- Out :
                  MATCH_NOT           => #{sprintf("%-28s", registory[:match_not  ])} , -- Out :
                  MATCH_SHIFT         => #{sprintf("%-28s", registory[:match_shift])} , -- Out :
                  VALUE               => #{sprintf("%-28s", i_value                )} , -- In  :
                  VALID               => #{sprintf("%-28s", i_valid                )} , -- In  :
                  READY               => #{sprintf("%-28s", i_ready                )}   -- Out :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    else
      vhdl_lines  = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_Object_Query_Integer_Register   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                  VALUE_BITS          => #{sprintf("%-28s", value_bits             )} , --
                  VALUE_SIGN          => #{sprintf("%-28s", value_sign             )}   --
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
                  O_CODE              => #{sprintf("%-28s", registory[:value_code ])} , -- Out :
                  O_LAST              => #{sprintf("%-28s", registory[:value_last ])} , -- Out :
                  O_VALID             => #{sprintf("%-28s", registory[:value_valid])} , -- Out :
                  O_ERROR             => #{sprintf("%-28s", registory[:value_error])} , -- Out :
                  O_READY             => #{sprintf("%-28s", registory[:value_ready])} , -- In  :
                  VALUE               => #{sprintf("%-28s", i_value                )} , -- In  :
                  VALID               => #{sprintf("%-28s", i_valid                )} , -- In  :
                  READY               => #{sprintf("%-28s", i_ready                )}   -- Out :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    end
    if type.generate_vhdl_type.match(/^std_logic_vector/) then
      return vhdl_lines
    else
      return vhdl_lines.concat(string_to_lines(indent, <<"        EOT"
        proc_1_value <= std_logic_vector(#{registory[:read_value]});
        EOT
      ))
    end
  end

  def generate_body(indent, name, type, kvmap, registory)
    if type.generate_vhdl_type.match(/^std_logic_vector/) then
      return generate_stmt(indent, name, type, registory)
    else
      block_name = registory.fetch(:instance_name, "PROC_QUERY_" + name.upcase)
      decl_lines = generate_decl(indent + "    ", name, type, kvmap, registory)
      stmt_lines = generate_stmt(indent + "    ", name, type, kvmap, registory)
      return ["#{indent}#{block_name}: block"] + 
             decl_lines + 
             ["#{indent}begin"] +
             stmt_lines +
             ["#{indent}end block;"]
    end
  end

  def use_package_list(kvmap)
    if kvmap == true then
      return ["MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Query_Integer_Register"]
    else
      return ["MsgPack.MsgPack_Object_Components.MsgPack_Object_Query_Integer_Register"]
    end
  end

  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :use_package_list
end
