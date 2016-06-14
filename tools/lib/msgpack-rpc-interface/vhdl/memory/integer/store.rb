module MsgPack_RPC_Interface::VHDL::Memory::Integer::Store
  extend  MsgPack_RPC_Interface::VHDL::Util
  include MsgPack_RPC_Interface::VHDL::Util::Store

  def generate_stmt(indent, name, data_type, kvmap, registory)
    instance_name = instance_name(name, data_type, registory)
    write_sig     = interface_signals(data_type, registory)
    write_sign    = registory.fetch(:store_sign , "open")
    check_range   = registory.fetch(:check_range, "TRUE")
    enable64      = registory.fetch(:enable64   , "TRUE")
    value_bits    = data_type.width
    value_sign    = data_type.sign
    if kvmap == true then
      key_string = "STRING'(\"" + name + "\")"
      vhdl_lines = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_KVMap_Store_Integer_Array   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  KEY                 => #{sprintf("%-28s", key_string             )} , --
                  MATCH_PHASE         => #{sprintf("%-28s", registory[:match_phase])} , --
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                  ADDR_BITS           => #{sprintf("%-28s", write_sig[:addr_bits  ])} , --
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
                  START               => #{sprintf("%-28s", write_sig[:start      ])} , -- Out :
                  BUSY                => #{sprintf("%-28s", write_sig[:busy       ])} , -- Out :
                  ADDR                => #{sprintf("%-28s", write_sig[:addr       ])} , -- Out :
                  VALUE               => #{sprintf("%-28s", write_sig[:data       ])} , -- Out :
                  SIGN                => #{sprintf("%-28s", write_sign             )} , -- Out :
                  LAST                => #{sprintf("%-28s", write_sig[:last       ])} , -- Out :
                  VALID               => #{sprintf("%-28s", write_sig[:valid      ])} , -- Out :
                  READY               => #{sprintf("%-28s", write_sig[:ready      ])}   -- In  :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    else
      vhdl_lines    = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_Object_Store_Integer_Array   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                  ADDR_BITS           => #{sprintf("%-28s", write_sig[:addr_bits  ])} , --
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
                  START               => #{sprintf("%-28s", write_sig[:start      ])} , -- Out :
                  BUSY                => #{sprintf("%-28s", write_sig[:busy       ])} , -- Out :
                  ADDR                => #{sprintf("%-28s", write_sig[:addr       ])} , -- Out :
                  VALUE               => #{sprintf("%-28s", write_sig[:data       ])} , -- Out :
                  SIGN                => #{sprintf("%-28s", write_sign             )} , -- Out :
                  LAST                => #{sprintf("%-28s", write_sig[:last       ])} , -- Out :
                  VALID               => #{sprintf("%-28s", write_sig[:valid      ])} , -- Out :
                  READY               => #{sprintf("%-28s", write_sig[:ready      ])}   -- In  :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    end
    return vhdl_lines + generate_stmt_post(indent, name, data_type, kvmap, registory)
  end

  def use_package_list(kvmap)
    if kvmap == true then
      return ["MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Store_Integer_Array"]
    else
      return ["MsgPack.MsgPack_Object_Components.MsgPack_Object_Store_Integer_Array"]
    end
  end

  module_function :instance_name
  module_function :interface_signals
  module_function :sub_block?
  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :generate_stmt_post
  module_function :use_package_list
end
