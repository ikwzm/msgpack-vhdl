module MsgPack_RPC_Interface::VHDL::Stream::Integer::Query
  extend  MsgPack_RPC_Interface::VHDL::Util
  include MsgPack_RPC_Interface::VHDL::Util::Query

  def generate_stmt(indent, name, data_type, kvmap, registory)
    instance_name = instance_name(name, data_type, registory)
    query_sig     = internal_signals(data_type, registory)
    value_bits    = data_type.width
    value_sign    = data_type.sign
    size_bits     = query_sig[:size_bits]
    width         = registory.fetch(:width      , 1     )
    default_size  = registory.fetch(:query_dsize , '"' + Array.new(size_bits){|n| (width >> (size_bits-1-n)) & 1}.join + '"')
    if kvmap == true then
      key_string = "STRING'(\"" + name + "\")"
      vhdl_lines = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_KVMap_Query_Integer_Stream   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  KEY                 => #{sprintf("%-28s", key_string             )} , --
                  MATCH_PHASE         => #{sprintf("%-28s", registory[:match_phase])} , --
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
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
                  START               => #{sprintf("%-28s", query_sig[:start      ])} , -- Out :
                  BUSY                => #{sprintf("%-28s", query_sig[:busy       ])} , -- Out :
                  SIZE                => #{sprintf("%-28s", query_sig[:size       ])} , -- In  :
                  VALUE               => #{sprintf("%-28s", query_sig[:data       ])} , -- In  :
                  VALID               => #{sprintf("%-28s", query_sig[:valid      ])} , -- In  :
                  READY               => #{sprintf("%-28s", query_sig[:ready      ])}   -- Out :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    else
      vhdl_lines = string_to_lines(
        indent, <<"        EOT"
          #{instance_name} : MsgPack_Object_Query_Binary_Stream   -- 
              generic map (              #{sprintf("%-28s", ""                     )}   -- 
                  CODE_WIDTH          => #{sprintf("%-28s", registory[:code_width ])} , --
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
                  START               => #{sprintf("%-28s", query_sig[:start      ])} , -- Out :
                  BUSY                => #{sprintf("%-28s", query_sig[:busy       ])} , -- Out :
                  SIZE                => #{sprintf("%-28s", query_sig[:size       ])} , -- In  :
                  VALUE               => #{sprintf("%-28s", query_sig[:data       ])} , -- In  :
                  VALID               => #{sprintf("%-28s", query_sig[:valid      ])} , -- In  :
                  READY               => #{sprintf("%-28s", query_sig[:ready      ])}   -- Out :
              );                         #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    end
    return vhdl_lines + generate_stmt_post(indent, name, data_type, kvmap, registory)
  end
  
  def use_package_list(kvmap)
    if kvmap == true then
      return ["MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Query_Integer_Stream"]
    else
      return ["MsgPack.MsgPack_Object_Components.MsgPack_Object_Query_Integer_Stream"]
    end
  end

  module_function :instance_name
  module_function :internal_signals
  module_function :sub_block?
  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :generate_stmt_post
  module_function :use_package_list
end
