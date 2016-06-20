module MsgPack_RPC_Interface::VHDL::Memory::Boolean::Store
  extend  MsgPack_RPC_Interface::VHDL::Util
  include MsgPack_RPC_Interface::VHDL::Util::Store

  def generate_stmt(indent, name, data_type, kvmap, registory)
    instance_name = instance_name(name, data_type, registory)
    interface     = interface_signals(data_type, registory)
    if kvmap == true then
      key_string = "STRING'(\"" + name + "\")"
      vhdl_lines = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_KVMap_Store_Boolean_Array   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  KEY                 => #{sprintf("%-28s", key_string             )} , --
                  MATCH_PHASE         => #{sprintf("%-28s", registory[:match_phase])} , --
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                  DATA_BITS           => #{sprintf("%-28s", interface[:data_bits  ])} , --
                  ADDR_BITS           => #{sprintf("%-28s", interface[:addr_bits  ])} , --
                  SIZE_BITS           => #{sprintf("%-28s", interface[:size_bits  ])}   --
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
                  START               => #{sprintf("%-28s", interface[:start      ])} , -- Out :
                  BUSY                => #{sprintf("%-28s", interface[:busy       ])} , -- Out :
                  SIZE                => #{sprintf("%-28s", interface[:size       ])} , -- Out :
                  ADDR                => #{sprintf("%-28s", interface[:addr       ])} , -- Out :
                  DATA                => #{sprintf("%-28s", interface[:data       ])} , -- Out :
                  STRB                => #{sprintf("%-28s", interface[:strb       ])} , -- Out :
                  LAST                => #{sprintf("%-28s", interface[:last       ])} , -- Out :
                  VALID               => #{sprintf("%-28s", interface[:valid      ])} , -- Out :
                  READY               => #{sprintf("%-28s", interface[:ready      ])}   -- In  :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    else
      vhdl_lines    = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_Object_Store_Boolean_Array   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                  DATA_BITS           => #{sprintf("%-28s", interface[:data_bits  ])} , --
                  ADDR_BITS           => #{sprintf("%-28s", interface[:addr_bits  ])} , --
                  SIZE_BITS           => #{sprintf("%-28s", interface[:size_bits  ])}   --
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
                  START               => #{sprintf("%-28s", interface[:start      ])} , -- Out :
                  BUSY                => #{sprintf("%-28s", interface[:busy       ])} , -- Out :
                  SIZE                => #{sprintf("%-28s", interface[:size       ])} , -- Out :
                  ADDR                => #{sprintf("%-28s", interface[:addr       ])} , -- Out :
                  DATA                => #{sprintf("%-28s", interface[:data       ])} , -- Out :
                  STRB                => #{sprintf("%-28s", interface[:strb       ])} , -- Out :
                  LAST                => #{sprintf("%-28s", interface[:last       ])} , -- Out :
                  VALID               => #{sprintf("%-28s", interface[:valid      ])} , -- Out :
                  READY               => #{sprintf("%-28s", interface[:ready      ])}   -- In  :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    end
    return vhdl_lines + generate_stmt_post(indent, name, data_type, kvmap, registory)
  end

  def use_package_list(kvmap)
    if kvmap == true then
      return ["MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Store_Boolean_Array"]
    else
      return ["MsgPack.MsgPack_Object_Components.MsgPack_Object_Store_Boolean_Array"]
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
