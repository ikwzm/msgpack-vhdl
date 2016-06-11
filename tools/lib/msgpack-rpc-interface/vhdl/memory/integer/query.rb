module MsgPack_RPC_Interface::VHDL::Memory::Integer::Query
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_decl(indent, name, data_type, kvmap, registory)
    addr_type  = registory[:addr_type]
    vhdl_lines = Array.new
    if data_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
      vhdl_lines.concat(string_to_lines(indent, <<"        EOT"
        signal    proc_1_data      :  std_logic_vector(#{data_type.width-1} downto 0);
        EOT
      ))
    end
    if addr_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
      vhdl_lines.concat(string_to_lines(indent, <<"        EOT"
        signal    proc_1_addr      :  std_logic_vector(#{addr_type.width-1} downto 0);
        EOT
      ))
    end
    return vhdl_lines
  end

  def generate_stmt(indent, name, data_type, kvmap, registory)
    addr_type  = registory[:addr_type]
    if data_type.generate_vhdl_type.match(/^std_logic_vector/) and
       addr_type.generate_vhdl_type.match(/^std_logic_vector/) then
      instance_name = registory.fetch(:instance_name, "PROC_QUERY_" + name.upcase)
    else
      instance_name = "PROC_1"
    end
    if data_type.generate_vhdl_type.match(/^std_logic_vector/) then
      read_data  = registory[:read_data]
    else
      read_data  = "proc_1_data"
    end
    if addr_type.generate_vhdl_type.match(/^std_logic_vector/) then
      read_addr  = registory[:read_addr]
    else
      read_addr  = "proc_1_addr"
    end
    read_start   = registory.fetch(:read_start , "open")
    read_busy    = registory.fetch(:read_busy  , "open")
    read_size    = registory.fetch(:read_size  , "open")
    read_valid   = registory.fetch(:read_valid , "'1'" )
    read_ready   = registory.fetch(:read_ready , "open")
    memory_size  = registory.fetch(:size       , 2**addr_type.width)
    value_bits   = data_type.width
    value_sign   = data_type.sign
    addr_bits    = addr_type.width
    size_bits    = Math::log2(memory_size+1).ceil
    default_size = '"' + Array.new(size_bits){|n| (memory_size >> (size_bits-1-n)) & 1}.join + '"'
    if kvmap == true then
      key_string = "STRING'(\"" + name + "\")"
      vhdl_lines = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_KVMap_Query_Integer_Array   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  KEY                 => #{sprintf("%-28s", key_string             )} , --
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                  MATCH_PHASE         => #{sprintf("%-28s", registory[:match_phase])} , --
                  ADDR_BITS           => #{sprintf("%-28s", addr_bits              )} , --
                  SIZE_BITS           => #{sprintf("%-28s", size_bits              )} , --
                  VALUE_BITS          => #{sprintf("%-28s", value_bits             )} , --
                  VALUE_SIGN          => #{sprintf("%-28s", value_sign             )}   --
              )                          #{sprintf("%-28s", ""                     )}   -- 
              port map (                 #{sprintf("%-28s", ""                     )}   -- 
                  CLK                 => #{sprintf("%-28s", registory[:clock      ])} , -- In  :
                  RST                 => #{sprintf("%-28s", registory[:reset      ])} , -- in  :
                  CLR                 => #{sprintf("%-28s", registory[:clear      ])} , -- in  :
                  DEFAULT_SIZE        => #{sprintf("%-28s", default_size           )} , -- In  :
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
                  START               => #{sprintf("%-28s", read_start             )} , -- Out :
                  BUSY                => #{sprintf("%-28s", read_busy              )} , -- Out :
                  ADDR                => #{sprintf("%-28s", read_addr              )} , -- Out :
                  SIZE                => #{sprintf("%-28s", read_size              )} , -- Out :
                  VALUE               => #{sprintf("%-28s", read_data              )} , -- In  :
                  VALID               => #{sprintf("%-28s", read_valid             )} , -- In  :
                  READY               => #{sprintf("%-28s", read_ready             )}   -- Out :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    else
      vhdl_lines  = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_Object_Query_Integer_Array   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                  ADDR_BITS           => #{sprintf("%-28s", addr_bits              )} , --
                  SIZE_BITS           => #{sprintf("%-28s", size_bits              )} , --
                  VALUE_BITS          => #{sprintf("%-28s", value_bits             )} , --
                  VALUE_SIGN          => #{sprintf("%-28s", value_sign             )}   --
              )                          #{sprintf("%-28s", ""                     )}   -- 
              port map (                 #{sprintf("%-28s", ""                     )}   -- 
                  CLK                 => #{sprintf("%-28s", registory[:clock      ])} , -- In  :
                  RST                 => #{sprintf("%-28s", registory[:reset      ])} , -- in  :
                  CLR                 => #{sprintf("%-28s", registory[:clear      ])} , -- in  :
                  DEFAULT_SIZE        => #{sprintf("%-28s", default_size           )} , -- In  :
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
                  START               => #{sprintf("%-28s", read_start             )} , -- Out :
                  BUSY                => #{sprintf("%-28s", read_busy              )} , -- Out :
                  ADDR                => #{sprintf("%-28s", read_addr              )} , -- Out :
                  SIZE                => #{sprintf("%-28s", read_size              )} , -- Out :
                  VALUE               => #{sprintf("%-28s", read_data              )} , -- In  :
                  VALID               => #{sprintf("%-28s", read_valid             )} , -- In  :
                  READY               => #{sprintf("%-28s", read_ready             )}   -- Out :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    end
    if data_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
      vhdl_lines.concat(string_to_lines(indent, <<"        EOT"
        proc_1_data <= std_logic_vector(#{registory[:read_data]});
        EOT
      ))
    end
    if addr_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
      converted_addr = addr_type.generate_vhdl_convert("proc_1_addr")
      vhdl_lines.concat(string_to_lines(indent, <<"        EOT"
        #{registory[:read_addr]} <= #{converted_addr};
        EOT
      ))
    end
    return vhdl_lines
  end

  def generate_body(indent, name, data_type, kvmap, registory)
    addr_type = registory[:addr_type]
    if data_type.generate_vhdl_type.match(/^std_logic_vector/) and
       addr_type.generate_vhdl_type.match(/^std_logic_vector/) then
      return generate_stmt(indent, name, data_type, kvmap, registory)
    else
      block_name = registory.fetch(:instance_name, "PROC_QUERY_" + name.upcase)
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
      return ["MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Query_Integer_Array"]
    else
      return ["MsgPack.MsgPack_Object_Components.MsgPack_Object_Query_Integer_Array"]
    end
  end

  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :use_package_list
end
