module MsgPack_RPC_Interface::VHDL::Procedure::StoreVariables
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_decl(indent, name, variables, registory)
    code_width  = registory[:code_width ]
    match_phase = registory[:match_phase]
    vhdl_lines  = string_to_lines(
      indent, <<"        EOT"
          constant  PROC_MAP_STORE_SIZE   :  integer := #{variables.size};
          signal    proc_map_match_req    :  std_logic_vector        (#{match_phase}-1 downto 0);
          signal    proc_map_match_code   :  MsgPack_RPC.Code_Type;
          signal    proc_map_match_ok     :  std_logic_vector        (PROC_MAP_STORE_SIZE-1 downto 0);
          signal    proc_map_match_not    :  std_logic_vector        (PROC_MAP_STORE_SIZE-1 downto 0);
          signal    proc_map_match_shift  :  MsgPack_RPC.Shift_Vector(PROC_MAP_STORE_SIZE-1 downto 0);
          signal    proc_map_param_code   :  MsgPack_RPC.Code_Type;
          signal    proc_map_param_valid  :  std_logic_vector        (PROC_MAP_STORE_SIZE-1 downto 0);
          signal    proc_map_param_last   :  std_logic;
          signal    proc_map_param_error  :  std_logic_vector        (PROC_MAP_STORE_SIZE-1 downto 0);
          signal    proc_map_param_done   :  std_logic_vector        (PROC_MAP_STORE_SIZE-1 downto 0);
          signal    proc_map_param_shift  :  MsgPack_RPC.Shift_Vector(PROC_MAP_STORE_SIZE-1 downto 0);
        EOT
      )
      return vhdl_lines
  end

  def generate_stmt(indent, name, variables, registory)
    key_string  = "STRING'(\"" + name + "\")"
    code_width  = registory[:code_width ]
    match_phase = registory[:match_phase]
    vhdl_lines  = string_to_lines(
      indent, <<"        EOT"
          PROC_MAIN: MsgPack_RPC_Server_KVMap_Set_Value         -- 
              generic map (                  #{sprintf("%-28s", ""                     )}   -- 
                  NAME                    => #{sprintf("%-28s", key_string             )} , --
                  STORE_SIZE              => #{sprintf("%-28s", "PROC_MAP_STORE_SIZE"  )} , --
                  MATCH_PHASE             => #{sprintf("%-28s", match_phase            )}   --
              )                              #{sprintf("%-28s", ""                     )}   -- 
              port map (                     #{sprintf("%-28s", ""                     )}   -- 
                  CLK                     => #{sprintf("%-28s", registory[:clock      ])} , -- In  :
                  RST                     => #{sprintf("%-28s", registory[:reset      ])} , -- in  :
                  CLR                     => #{sprintf("%-28s", registory[:clear      ])} , -- in  :
                  MATCH_REQ               => #{sprintf("%-28s", registory[:match_req  ])} , -- In  :
                  MATCH_CODE              => #{sprintf("%-28s", registory[:match_code ])} , -- In  :
                  MATCH_OK                => #{sprintf("%-28s", registory[:match_ok   ])} , -- Out :
                  MATCH_NOT               => #{sprintf("%-28s", registory[:match_not  ])} , -- Out :
                  MATCH_SHIFT             => #{sprintf("%-28s", registory[:match_shift])} , -- Out :
                  PROC_REQ_ID             => #{sprintf("%-28s", registory[:proc_req_id])} , -- In  :
                  PROC_REQ                => #{sprintf("%-28s", registory[:proc_req   ])} , -- In  :
                  PROC_BUSY               => #{sprintf("%-28s", registory[:proc_busy  ])} , -- Out :
                  PARAM_CODE              => #{sprintf("%-28s", registory[:param_code ])} , -- In  :
                  PARAM_VALID             => #{sprintf("%-28s", registory[:param_valid])} , -- In  :
                  PARAM_LAST              => #{sprintf("%-28s", registory[:param_last ])} , -- In  :
                  PARAM_SHIFT             => #{sprintf("%-28s", registory[:param_shift])} , -- Out :
                  MAP_MATCH_REQ           => #{sprintf("%-28s", "proc_map_match_req"   )} , -- Out :
                  MAP_MATCH_CODE          => #{sprintf("%-28s", "proc_map_match_code"  )} , -- Out :
                  MAP_MATCH_OK            => #{sprintf("%-28s", "proc_map_match_ok"    )} , -- In  :
                  MAP_MATCH_NOT           => #{sprintf("%-28s", "proc_map_match_not"   )} , -- In  :
                  MAP_MATCH_SHIFT         => #{sprintf("%-28s", "proc_map_match_shift" )} , -- In  :
                  MAP_VALUE_VALID         => #{sprintf("%-28s", "proc_map_param_valid" )} , -- Out :
                  MAP_VALUE_CODE          => #{sprintf("%-28s", "proc_map_param_code"  )} , -- Out :
                  MAP_VALUE_LAST          => #{sprintf("%-28s", "proc_map_param_last"  )} , -- Out :
                  MAP_VALUE_ERROR         => #{sprintf("%-28s", "proc_map_param_error" )} , -- In  :
                  MAP_VALUE_DONE          => #{sprintf("%-28s", "proc_map_param_done"  )} , -- In  :
                  MAP_VALUE_SHIFT         => #{sprintf("%-28s", "proc_map_param_shift" )} , -- In  :
                  RES_ID                  => #{sprintf("%-28s", registory[:proc_res_id])} , -- Out :
                  RES_CODE                => #{sprintf("%-28s", registory[:res_code   ])} , -- Out :
                  RES_VALID               => #{sprintf("%-28s", registory[:res_valid  ])} , -- Out :
                  RES_LAST                => #{sprintf("%-28s", registory[:res_last   ])} , -- Out :
                  RES_READY               => #{sprintf("%-28s", registory[:res_ready  ])}   -- In  :
              );                             #{sprintf("%-28s", ""                     )}   -- 
        EOT
    )
    variables.to_a.each_with_index do |variable, num|
      var_regs = Hash.new
      var_regs[:num         ] = num
      var_regs[:code_width  ] = code_width
      var_regs[:match_phase ] = match_phase
      var_regs[:clock       ] = registory[:clock]
      var_regs[:reset       ] = registory[:reset]
      var_regs[:clear       ] = registory[:clear]
      var_regs[:param_code  ] = "proc_map_param_code"
      var_regs[:param_last  ] = "proc_map_param_last"
      var_regs[:param_valid ] = "proc_map_param_valid(#{num})"
      var_regs[:param_error ] = "proc_map_param_error(#{num})"
      var_regs[:param_done  ] = "proc_map_param_done (#{num})"
      var_regs[:param_shift ] = "proc_map_param_shift(#{num})"
      var_regs[:match_req   ] = "proc_map_match_req"
      var_regs[:match_code  ] = "proc_map_match_code"
      var_regs[:match_ok    ] = "proc_map_match_ok   (#{num})"
      var_regs[:match_not   ] = "proc_map_match_not  (#{num})"
      var_regs[:match_shift ] = "proc_map_match_shift(#{num})"
      vhdl_lines.concat(variable.interface.generate_vhdl_body_store(indent, var_regs))
    end
    return vhdl_lines
  end

  def generate_body(indent, name, variable, registory)
    indent_sub = indent + "    "
    decl_code  = generate_decl(indent_sub, name, variable, registory)
    if (decl_code.size > 0) then
      block_start = registory.fetch(:block_start, "PROC_STORE_VARIABLES: block")
      block_end   = registory.fetch(:block_end  , "end block")
      return ["#{indent}#{block_start}"] + 
             decl_code +
             ["#{indent}begin"] +
             generate_stmt(indent_sub, name, variable, registory) +
             ["#{indent}#{block_end};"]
    else
      return generate_stmt(indent    , name, variable, registory)
    end
  end

  def generate_port_list(registory)
    return []
  end
    
  def use_package_list
    return ["MsgPack.MsgPack_RPC_Components.MsgPack_RPC_Server_KVMap_Set_Value"]
  end
    
  module_function :generate_port_list
  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :use_package_list
end

