module MsgPack_RPC_Interface::VHDL::Stream::Integer::Store
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_decl(indent, name, data_type, kvmap, registory)
    vhdl_lines = Array.new
    if data_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
      vhdl_lines.concat(string_to_lines(indent, <<"        EOT"
        signal    proc_0_data      :  std_logic_vector(#{data_type.width-1} downto 0);
        EOT
      ))
    end
    return vhdl_lines
  end

  def generate_stmt(indent, name, data_type, kvmap, registory)
    if data_type.generate_vhdl_type.match(/^std_logic_vector/) then
      instance_name = registory.fetch(:instance_name, "PROC_STORE_" + name.upcase)
      write_data    = registory[:write_data]
    else
      instance_name = "PROC_0"
      write_data    = "proc_0_data"
    end
    class_name    = self.name.to_s.split("::")[-2]
    size_type     = registory[:size_type]
    write_start   = registory.fetch(:write_start  , "open")
    write_busy    = registory.fetch(:write_busy   , "open")
    write_size    = registory.fetch(:write_size   , "open")
    write_last    = registory.fetch(:write_last   , "open")
    write_sign    = registory.fetch(:write_sign   , "open")
    write_valid   = registory.fetch(:write_valid  , "open")
    write_ready   = registory.fetch(:write_ready  , "'1'" )
    check_range   = registory.fetch(:check_range  , "TRUE")
    enable64      = registory.fetch(:enable64     , "TRUE")
    value_bits    = data_type.width
    value_sign    = data_type.sign
    size_bits     = size_type.width
    if kvmap == true then
      key_string = "STRING'(\"" + name + "\")"
      vhdl_lines = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_KVMap_Store_Integer_Stream   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  KEY                 => #{sprintf("%-28s", key_string             )} , --
                  MATCH_PHASE         => #{sprintf("%-28s", registory[:match_phase])} , --
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                  SIZE_BITS           => #{sprintf("%-28s", size_bits              )} , --
                  VALUE_BITS          => #{sprintf("%-28s", value_bits             )} , --
                  VALUE_SIGN          => #{sprintf("%-28s", value_sign             )} , --
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
                  MATCH_REQ           => #{sprintf("%-28s", registory[:match_req  ])} , -- In  :
                  MATCH_CODE          => #{sprintf("%-28s", registory[:match_code ])} , -- In  :
                  MATCH_OK            => #{sprintf("%-28s", registory[:match_ok   ])} , -- Out :
                  MATCH_NOT           => #{sprintf("%-28s", registory[:match_not  ])} , -- Out :
                  MATCH_SHIFT         => #{sprintf("%-28s", registory[:match_shift])} , -- Out :
                  START               => #{sprintf("%-28s", write_start            )} , -- Out :
                  BUSY                => #{sprintf("%-28s", write_busy             )} , -- Out :
                  SIZE                => #{sprintf("%-28s", write_size             )} , -- Out :
                  VALUE               => #{sprintf("%-28s", write_data             )} , -- Out :
                  SIGN                => #{sprintf("%-28s", write_sign             )} , -- Out :
                  LAST                => #{sprintf("%-28s", write_last             )} , -- Out :
                  VALID               => #{sprintf("%-28s", write_valid            )} , -- Out :
                  READY               => #{sprintf("%-28s", write_ready            )}   -- In  :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    else
      vhdl_lines    = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_Object_Store_Integer_Stream   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                  SIZE_BITS           => #{sprintf("%-28s", size_bits              )} , --
                  VALUE_BITS          => #{sprintf("%-28s", value_bits             )} , --
                  VALUE_SIGN          => #{sprintf("%-28s", value_sign             )} , --
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
                  START               => #{sprintf("%-28s", write_start            )} , -- Out :
                  BUSY                => #{sprintf("%-28s", write_busy             )} , -- Out :
                  SIZE                => #{sprintf("%-28s", write_size             )} , -- Out :
                  VALUE               => #{sprintf("%-28s", write_data             )} , -- Out :
                  SIGN                => #{sprintf("%-28s", write_sign             )} , -- Out :
                  LAST                => #{sprintf("%-28s", write_last             )} , -- Out :
                  VALID               => #{sprintf("%-28s", write_valid            )} , -- Out :
                  READY               => #{sprintf("%-28s", write_ready            )}   -- In  :
        EOT
      )
    end
    if data_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
      converted_data = data_type.generate_vhdl_convert("proc_0_data")
      vhdl_lines.concat(string_to_lines(indent, <<"        EOT"
        #{registory[:write_data]} <= #{converted_data};
        EOT
      ))
    end
    return vhdl_lines
  end
  
  def generate_body(indent, name, data_type, kvmap, registory)
    if data_type.generate_vhdl_type.match(/^std_logic_vector/) then
      return generate_stmt(indent, name, data_type, kvmap, registory)
    else
      block_name = registory.fetch(:instance_name, "PROC_STORE_" + name.upcase)
      decl_lines = generate_decl(indent + "    ", name, data_type, kvmap, registory)
      stmt_lines = generate_stmt(indent + "    ", name, data_type, kvmap, registory)
      return ["#{indent}#{block_name}: block"] + 
             decl_lines + 
             ["#{indent}begin"] +
             stmt_lines +
             ["#{indent}end block;"]
    end
  end
  
  def use_package_list(kvmap)
    if kvmap == true then
      return ["MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Store_Integer_Stream"]
    else
      return ["MsgPack.MsgPack_Object_Components.MsgPack_Object_Store_Integer_Stream"]
    end
  end

  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :use_package_list
end
