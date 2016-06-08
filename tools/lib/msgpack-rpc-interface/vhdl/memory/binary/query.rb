module MsgPack_RPC_Interface::VHDL::Memory::Binary::Query
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_decl(indent, name, data_type, addr_type, kvmap, registory)
    return []
  end

  def generate_stmt(indent, name, data_type, addr_type, kvmap, registory)
    class_name    = self.name.to_s.split("::")[-2]
    encode_binary = (class_name == "Binary") ? "TRUE" : "FALSE"
    encode_string = (class_name == "String") ? "TRUE" : "FALSE"
    instance_name = registory.fetch(:instance_name, "PROC_QUERY_" + name.upcase)
    read_data     = registory[:read_data]
    read_addr     = registory[:read_addr]
    read_start    = registory.fetch(:read_start , "open")
    read_busy     = registory.fetch(:read_busy  , "open")
    read_valid    = registory.fetch(:read_valid , "'1'" )
    read_ready    = registory.fetch(:read_ready , "open")
    memory_size   = registory.fetch(:size       , 2**addr_type.width)
    addr_bits     = addr_type.width
    data_bits     = registory[:width]*8
    size_bits     = 32
    if kvmap == true then
      key_string = "STRING'(\"" + name + "\")"
      vhdl_lines = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_KVMap_Query_Binary_Array   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  KEY                 => #{sprintf("%-28s", key_string             )} , --
                  MATCH_PHASE         => #{sprintf("%-28s", registory[:match_phase])} , --
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                  ADDR_BITS           => #{sprintf("%-28s", addr_bits              )} , --
                  DATA_BITS           => #{sprintf("%-28s", data_bits              )} , --
                  SIZE_BITS           => #{sprintf("%-28s", size_bits              )} , --
                  SIZE_MAX            => #{sprintf("%-28s", memory_size            )} , --
                  ENCODE_BINARY       => #{sprintf("%-28s", encode_binary          )} , --
                  ENCODE_STRING       => #{sprintf("%-28s", encode_string          )}   --
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
                  START               => #{sprintf("%-28s", read_start             )} , -- Out :
                  BUSY                => #{sprintf("%-28s", read_busy              )} , -- Out :
                  ADDR                => #{sprintf("%-28s", read_addr              )} , -- Out :
                  DATA                => #{sprintf("%-28s", read_data              )} , -- In  :
                  VALID               => #{sprintf("%-28s", read_valid             )} , -- In  :
                  READY               => #{sprintf("%-28s", read_ready             )}   -- Out :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    else
      vhdl_lines = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_Object_Query_Binary_Array   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                  ADDR_BITS           => #{sprintf("%-28s", addr_bits              )} , --
                  DATA_BITS           => #{sprintf("%-28s", data_bits              )} , --
                  SIZE_BITS           => #{sprintf("%-28s", size_bits              )} , --
                  SIZE_MAX            => #{sprintf("%-28s", memory_size            )} , --
                  ENCODE_BINARY       => #{sprintf("%-28s", encode_binary          )} , --
                  ENCODE_STRING       => #{sprintf("%-28s", encode_string          )}   --
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
                  START               => #{sprintf("%-28s", read_start             )} , -- Out :
                  BUSY                => #{sprintf("%-28s", read_busy              )} , -- Out :
                  ADDR                => #{sprintf("%-28s", read_addr              )} , -- Out :
                  DATA                => #{sprintf("%-28s", read_data              )} , -- In  :
                  VALID               => #{sprintf("%-28s", read_valid             )} , -- In  :
                  READY               => #{sprintf("%-28s", read_ready             )}   -- Out :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    end
    return vhdl_lines
  end
  
  def generate_body(indent, name, data_type, addr_type, kvmap, registory)
    return generate_stmt(indent, name, data_type, addr_type, kvmap, registory)
  end
  
  def use_package_list(kvmap)
    if kvmap == true then
      return ["MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Query_Binary_Array"]
    else
      return ["MsgPack.MsgPack_Object_Components.MsgPack_Object_Query_Binary_Array"]
    end
  end

  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :use_package_list
end
