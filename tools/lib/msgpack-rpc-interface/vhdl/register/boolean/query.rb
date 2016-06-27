module MsgPack_RPC_Interface::VHDL::Register::Boolean::Query
  extend  MsgPack_RPC_Interface::VHDL::Util
  include MsgPack_RPC_Interface::VHDL::Util::Query

  def generate_stmt(indent, name, data_type, kvmap, registory)
    instance_name = instance_name(name, data_type, registory)
    interface     = interface_signals(data_type, registory)
    value_name    = interface[:data] + "(0)"
    if kvmap == true then
      key_string  = "STRING'(\"" + name + "\")"
      vhdl_lines  = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_KVMap_Query_Boolean_Register   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  KEY                 => #{sprintf("%-28s", key_string             )} , --
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
                  MATCH_PHASE         => #{sprintf("%-28s", registory[:match_phase])}   --
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
                  VALUE               => #{sprintf("%-28s", value_name             )} , -- In  :
                  VALID               => #{sprintf("%-28s", interface[:valid      ])} , -- In  :
                  READY               => #{sprintf("%-28s", interface[:ready      ])}   -- Out :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    else
      vhdl_lines  = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_Object_Query_Boolean_Register   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])}   --
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
                  VALUE               => #{sprintf("%-28s", value_name             )} , -- In  :
                  VALID               => #{sprintf("%-28s", interface[:valid      ])} , -- In  :
                  READY               => #{sprintf("%-28s", interface[:ready      ])}   -- Out :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    end
    return vhdl_lines + generate_stmt_post(indent, name, data_type, kvmap, registory)
  end

  def use_package_list(kvmap)
    if kvmap == true then
      return ["MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Query_Boolean_Register"]
    else
      return ["MsgPack.MsgPack_Object_Components.MsgPack_Object_Query_Boolean_Register"]
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
