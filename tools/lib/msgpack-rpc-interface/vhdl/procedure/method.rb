module MsgPack_RPC_Interface::VHDL::Procedure::Method
  extend MsgPack_RPC_Interface::VHDL::Util

  def self.generate_decl_method_no_param(indent, name, registory)
    vhdl_lines = string_to_lines(
      indent, <<"      EOT"
          signal    proc_return_start     :  std_logic;
          signal    proc_return_done      :  std_logic;
          signal    proc_return_error     :  std_logic;
          signal    proc_return_busy      :  std_logic;
          signal    proc_start            :  std_logic;
      EOT
    )
    vhdl_lines.concat(string_to_lines(
      indent, <<"      EOT"
          signal    proc_run_busy         :  std_logic;
      EOT
    )) if registory.key?(:run_idle)
    return vhdl_lines
  end

  def self.generate_stmt_method_no_param(indent, name, registory)
    key_string = "STRING'(\"" + name + "\")"
    run_req    = registory.fetch(:run_req ,   "open")
    run_done   = registory.fetch(:run_done,
                 registory.key?( :run_idle) ? "'0'" :
                 registory.key?( :run_busy) ? "'0'" : "'1'")
    run_busy   = registory.key?( :run_idle) ? "proc_run_busy" :
                 registory.fetch(:run_busy,   "'1'" )
    vhdl_lines = string_to_lines(
      indent, <<"      EOT"
          PROC_MAIN: MsgPack_RPC_Method_Main_No_Param         -- 
              generic map (                  #{sprintf("%-28s", ""                     )}   -- 
                  NAME                    => #{sprintf("%-28s", key_string             )} , --
                  MATCH_PHASE             => #{sprintf("%-28s", registory[:match_phase])}   --
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
                  PROC_START              => #{sprintf("%-28s", "proc_start"           )} , -- Out :
                  PARAM_CODE              => #{sprintf("%-28s", registory[:param_code ])} , -- In  :
                  PARAM_VALID             => #{sprintf("%-28s", registory[:param_valid])} , -- In  :
                  PARAM_LAST              => #{sprintf("%-28s", registory[:param_last ])} , -- In  :
                  PARAM_SHIFT             => #{sprintf("%-28s", registory[:param_shift])} , -- Out :
                  RUN_REQ                 => #{sprintf("%-28s", run_req                )} , -- Out :
                  RUN_BUSY                => #{sprintf("%-28s", run_busy               )} , -- In  :
                  RUN_DONE                => #{sprintf("%-28s", run_done               )} , -- In  :
                  RET_ID                  => #{sprintf("%-28s", registory[:proc_res_id])} , -- Out :
                  RET_START               => #{sprintf("%-28s", "proc_return_start"    )} , -- Out :
                  RET_ERROR               => #{sprintf("%-28s", "proc_return_error"    )} , -- Out :
                  RET_DONE                => #{sprintf("%-28s", "proc_return_done"     )} , -- Out :
                  RET_BUSY                => #{sprintf("%-28s", "proc_return_busy"     )}   -- In  :
              );                             #{sprintf("%-28s", ""                     )}   -- 
      EOT
    )
    vhdl_lines.concat(string_to_lines(
      indent, <<"      EOT"
          proc_run_busy <= '1' when (#{registory[:run_idle]} = '0') else '0';
      EOT
    )) if registory.key?(:run_idle) 
    return vhdl_lines
  end

  def self.generate_decl_method_with_param(indent, name, arguments, registory)
    vhdl_lines = string_to_lines(
      indent, <<"      EOT"
          constant  PROC_PARAM_NUM        :  integer := #{arguments.size};
          signal    proc_set_param_code   :  MsgPack_RPC.Code_Type;
          signal    proc_set_param_last   :  std_logic;
          signal    proc_set_param_valid  :  std_logic_vector        (PROC_PARAM_NUM-1 downto 0);
          signal    proc_set_param_error  :  std_logic_vector        (PROC_PARAM_NUM-1 downto 0);
          signal    proc_set_param_done   :  std_logic_vector        (PROC_PARAM_NUM-1 downto 0);
          signal    proc_set_param_shift  :  MsgPack_RPC.Shift_Vector(PROC_PARAM_NUM-1 downto 0);
          signal    proc_return_start     :  std_logic;
          signal    proc_return_error     :  std_logic;
          signal    proc_return_done      :  std_logic;
          signal    proc_return_busy      :  std_logic;
          signal    proc_start            :  std_logic;
      EOT
    )
    vhdl_lines.concat(string_to_lines(
      indent, <<"      EOT"
          signal    proc_run_busy         :  std_logic;
      EOT
    )) if registory.key?(:run_idle)
    return vhdl_lines
  end

  def self.generate_stmt_method_with_param(indent, name, arguments, registory)
    key_string = "STRING'(\"" + name + "\")"
    run_req    = registory.fetch(:run_req ,   "open")
    run_done   = registory.fetch(:run_done,
                 registory.key?( :run_idle) ? "'0'" :
                 registory.key?( :run_busy) ? "'0'" : "'1'")
    run_busy   = registory.key?( :run_idle) ? "proc_run_busy" :
                 registory.fetch(:run_busy,   "'1'" )
    vhdl_lines = string_to_lines(
      indent, <<"      EOT"
          PROC_MAIN: MsgPack_RPC_Method_Main_with_Param         -- 
              generic map (                  #{sprintf("%-28s", ""                     )}   -- 
                  NAME                    => #{sprintf("%-28s", key_string             )} , --
                  PARAM_NUM               => #{sprintf("%-28s", "PROC_PARAM_NUM"       )} , --
                  MATCH_PHASE             => #{sprintf("%-28s", registory[:match_phase])}   --
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
                  PROC_START              => #{sprintf("%-28s", "proc_start"           )} , -- Out :
                  PARAM_CODE              => #{sprintf("%-28s", registory[:param_code ])} , -- In  :
                  PARAM_VALID             => #{sprintf("%-28s", registory[:param_valid])} , -- In  :
                  PARAM_LAST              => #{sprintf("%-28s", registory[:param_last ])} , -- In  :
                  PARAM_SHIFT             => #{sprintf("%-28s", registory[:param_shift])} , -- Out :
                  SET_PARAM_CODE          => #{sprintf("%-28s", "proc_set_param_code"  )} , -- Out :
                  SET_PARAM_LAST          => #{sprintf("%-28s", "proc_set_param_last"  )} , -- Out :
                  SET_PARAM_VALID         => #{sprintf("%-28s", "proc_set_param_valid" )} , -- Out :
                  SET_PARAM_ERROR         => #{sprintf("%-28s", "proc_set_param_error" )} , -- In  :
                  SET_PARAM_DONE          => #{sprintf("%-28s", "proc_set_param_done"  )} , -- In  :
                  SET_PARAM_SHIFT         => #{sprintf("%-28s", "proc_set_param_shift" )} , -- In  :
                  RUN_REQ                 => #{sprintf("%-28s", run_req                )} , -- Out :
                  RUN_BUSY                => #{sprintf("%-28s", run_busy               )} , -- In  :
                  RUN_DONE                => #{sprintf("%-28s", run_done               )} , -- In  :
                  RET_ID                  => #{sprintf("%-28s", registory[:proc_res_id])} , -- Out :
                  RET_START               => #{sprintf("%-28s", "proc_return_start"    )} , -- Out :
                  RET_DONE                => #{sprintf("%-28s", "proc_return_done"     )} , -- Out :
                  RET_ERROR               => #{sprintf("%-28s", "proc_return_error"    )} , -- Out :
                  RET_BUSY                => #{sprintf("%-28s", "proc_return_busy"     )}   -- In  :
              );                             #{sprintf("%-28s", ""                     )}   -- 
      EOT
    )
    vhdl_lines.concat(string_to_lines(
      indent, <<"      EOT"
          proc_run_busy <= '1' when (#{registory[:run_idle]} = '0') else '0';
      EOT
    )) if registory.key?(:run_idle) 
    arguments.each_with_index do |argument, num|
      args_regs = Hash.new
      args_regs[:num         ] = num
      args_regs[:code_width  ] = registory[:code_width]
      args_regs[:match_phase ] = registory[:match_phase]
      args_regs[:clock       ] = registory[:clock]
      args_regs[:reset       ] = registory[:reset]
      args_regs[:clear       ] = registory[:clear]
      args_regs[:param_code  ] = "proc_set_param_code"
      args_regs[:param_last  ] = "proc_set_param_last"
      args_regs[:param_valid ] = "proc_set_param_valid(#{num})"
      args_regs[:param_error ] = "proc_set_param_error(#{num})"
      args_regs[:param_done  ] = "proc_set_param_done (#{num})"
      args_regs[:param_shift ] = "proc_set_param_shift(#{num})"
      vhdl_lines.concat(argument.interface.generate_vhdl_body_store(indent, args_regs))
    end
    return vhdl_lines
  end

  def self.generate_decl_method_return_nil(indent, name, registory)
    return []
  end
        
  def self.generate_stmt_method_return_nil(indent, name, registory)
    vhdl_lines = string_to_lines(
      indent, <<"        EOT"
          PROC_RETURN : MsgPack_RPC_Method_Return_Nil              -- 
              port map (                     #{sprintf("%-28s", ""                     )}   -- 
                  CLK                     => #{sprintf("%-28s", registory[:clock      ])} , -- In  :
                  RST                     => #{sprintf("%-28s", registory[:reset      ])} , -- in  :
                  CLR                     => #{sprintf("%-28s", registory[:clear      ])} , -- in  :
                  RET_ERROR               => #{sprintf("%-28s", "proc_return_error"    )} , -- In  :
                  RET_START               => #{sprintf("%-28s", "proc_return_start"    )} , -- In  :
                  RET_DONE                => #{sprintf("%-28s", "proc_return_done"     )} , -- In  :
                  RET_BUSY                => #{sprintf("%-28s", "proc_return_busy"     )} , -- Out :
                  RES_CODE                => #{sprintf("%-28s", registory[:res_code   ])} , -- Out :
                  RES_VALID               => #{sprintf("%-28s", registory[:res_valid  ])} , -- Out :
                  RES_LAST                => #{sprintf("%-28s", registory[:res_last   ])} , -- Out :
                  RES_READY               => #{sprintf("%-28s", registory[:res_ready  ])}   -- In  :
              );                             #{sprintf("%-28s", ""                     )}   -- 
        EOT
      )
    return vhdl_lines
  end
      
  def self.generate_decl_method_return_integer(indent, name, return_variable, registory)
    return []
  end
        
  def self.generate_stmt_method_return_integer(indent, name, return_variable, registory)
    value_width = return_variable.interface.type.bits
    return_uint = (return_variable.type.sign) ? "FALSE" : "TRUE"
    return_int  = (return_variable.type.sign) ? "TRUE"  : "FALSE"
    return_name = return_variable.interface.registory[:query_data]
    return_stmt = return_variable.interface.type.generate_vhdl_convert_to_std_logic_vector(return_name, "proc_return_value")
    vhdl_lines  = string_to_lines(
      indent, <<"        EOT"
          PROC_RETURN : block
              signal proc_return_value : std_logic_vector(#{value_width}-1 downto 0);
          begin
              RET: MsgPack_RPC_Method_Return_Integer  -- 
                  generic map (                  #{sprintf("%-28s", ""                     )}   -- 
                      VALUE_WIDTH             => #{sprintf("%-28s", value_width            )} , --
                      RETURN_UINT             => #{sprintf("%-28s", return_uint            )} , --
                      RETURN_INT              => #{sprintf("%-28s", return_int             )} , --
                      RETURN_FLOAT            => #{sprintf("%-28s", "FALSE"                )} , --
                      RETURN_BOOLEAN          => #{sprintf("%-28s", "FALSE"                )}   --
                  )                              #{sprintf("%-28s", ""                     )}   -- 
                  port map (                     #{sprintf("%-28s", ""                     )}   -- 
                      CLK                     => #{sprintf("%-28s", registory[:clock      ])} , -- In  :
                      RST                     => #{sprintf("%-28s", registory[:reset      ])} , -- in  :
                      CLR                     => #{sprintf("%-28s", registory[:clear      ])} , -- in  :
                      RET_ERROR               => #{sprintf("%-28s", "proc_return_error"    )} , -- In  :
                      RET_START               => #{sprintf("%-28s", "proc_return_start"    )} , -- In  :
                      RET_DONE                => #{sprintf("%-28s", "proc_return_done"     )} , -- In  :
                      RET_BUSY                => #{sprintf("%-28s", "proc_return_busy"     )} , -- Out :
                      RES_CODE                => #{sprintf("%-28s", registory[:res_code   ])} , -- Out :
                      RES_VALID               => #{sprintf("%-28s", registory[:res_valid  ])} , -- Out :
                      RES_LAST                => #{sprintf("%-28s", registory[:res_last   ])} , -- Out :
                      RES_READY               => #{sprintf("%-28s", registory[:res_ready  ])} , -- In  :
                      VALUE                   => #{sprintf("%-28s", "proc_return_value"    )}   -- In  :
                  );
              #{return_stmt}
          end block;
        EOT
    )
    return vhdl_lines
  end

  def self.generate_decl_method_return_boolean(indent, name, return_variable, registory)
    return []
  end
        
  def self.generate_stmt_method_return_boolean(indent, name, return_variable, registory)
    return_name = return_variable.interface.registory[:query_data]
    return_stmt = return_variable.interface.type.generate_vhdl_convert_to_std_logic_vector(return_name, "proc_return_value")
    vhdl_lines  = string_to_lines(
      indent, <<"        EOT"
          PROC_RETURN : block
              signal proc_return_value : std_logic_vector(0 downto 0);
          begin
              RET: MsgPack_RPC_Method_Return_Integer  -- 
                  generic map (                  #{sprintf("%-28s", ""                     )}   -- 
                      VALUE_WIDTH             => #{sprintf("%-28s", 1                      )} , --
                      RETURN_UINT             => #{sprintf("%-28s", "FALSE"                )} , --
                      RETURN_INT              => #{sprintf("%-28s", "FALSE"                )} , --
                      RETURN_FLOAT            => #{sprintf("%-28s", "FALSE"                )} , --
                      RETURN_BOOLEAN          => #{sprintf("%-28s", "TRUE"                 )}   --
                  )                              #{sprintf("%-28s", ""                     )}   -- 
                  port map (                     #{sprintf("%-28s", ""                     )}   -- 
                      CLK                     => #{sprintf("%-28s", registory[:clock      ])} , -- In  :
                      RST                     => #{sprintf("%-28s", registory[:reset      ])} , -- in  :
                      CLR                     => #{sprintf("%-28s", registory[:clear      ])} , -- in  :
                      RET_ERROR               => #{sprintf("%-28s", "proc_return_error"    )} , -- In  :
                      RET_START               => #{sprintf("%-28s", "proc_return_start"    )} , -- In  :
                      RET_DONE                => #{sprintf("%-28s", "proc_return_done"     )} , -- In  :
                      RET_BUSY                => #{sprintf("%-28s", "proc_return_busy"     )} , -- Out :
                      RES_CODE                => #{sprintf("%-28s", registory[:res_code   ])} , -- Out :
                      RES_VALID               => #{sprintf("%-28s", registory[:res_valid  ])} , -- Out :
                      RES_LAST                => #{sprintf("%-28s", registory[:res_last   ])} , -- Out :
                      RES_READY               => #{sprintf("%-28s", registory[:res_ready  ])} , -- In  :
                      VALUE                   => #{sprintf("%-28s", "proc_return_value"    )}   -- In  :
                  );
              #{return_stmt}
          end block;
        EOT
    )
    return vhdl_lines
  end

  def generate_decl(indent, name, arguments, return_variable, registory)
    if (arguments.size > 0) then
      decl_code = generate_decl_method_with_param(indent, name, arguments, registory)
    else
      decl_code = generate_decl_method_no_param(  indent, name, registory)
    end
    if    return_variable == nil then
      decl_code.concat(generate_decl_method_return_nil(    indent, name, registory))
    elsif return_variable.type.generator_class == "Integer" then
      decl_code.concat(generate_decl_method_return_integer(indent, name, return_variable, registory))
    elsif return_variable.type.generator_class == "Boolean" then
      decl_code.concat(generate_decl_method_return_boolean(indent, name, return_variable, registory))
    else
      raise "Not Supported method return variable type (#{return_variable.type.class})"
    end
    return decl_code
  end

  def generate_stmt(indent, name, arguments, return_variable, registory)
    if (arguments.size > 0) then
      body_code = generate_stmt_method_with_param(indent, name, arguments, registory)
    else
      body_code = generate_stmt_method_no_param(  indent, name, registory)
    end
    if    return_variable == nil then
      body_code.concat(generate_stmt_method_return_nil(    indent, name, registory))
    elsif return_variable.type.generator_class == "Integer" then
      body_code.concat(generate_stmt_method_return_integer(indent, name, return_variable, registory))
    elsif return_variable.type.generator_class == "Boolean" then
      body_code.concat(generate_stmt_method_return_boolean(indent, name, return_variable, registory))
    else
      raise "Not Supported method return variable type (#{return_variable.type.class})"
    end
    return body_code
  end

  def generate_body(indent, name, arguments, return_variable, registory)
    indent_sub = indent + "    "
    decl_code  = generate_decl(indent_sub, name, arguments, return_variable, registory)
    if (decl_code.size > 0) then
      block_start = registory.fetch(:block_start, "PROC_" + name.upcase + ": block")
      block_end   = registory.fetch(:block_end  , "end block")
      return ["#{indent}#{block_start}"] + 
             decl_code +
             ["#{indent}begin"] +
             generate_stmt(indent_sub, name, arguments, return_variable, registory) +
             ["#{indent}#{block_end};"]
    else
      return generate_stmt(indent, name, arguments, return_variable, registory)
    end
  end

  def generate_port_list(master, registory)
    vhdl_lines = Array.new
    req_out = (master) ? "out" : "in"
    req_in  = (master) ? "in"  : "out"
    add_port_line(vhdl_lines, registory, :run_req , req_out,  "std_logic")
    add_port_line(vhdl_lines, registory, :run_busy, req_in ,  "std_logic")
    add_port_line(vhdl_lines, registory, :run_idle, req_in ,  "std_logic")
    add_port_line(vhdl_lines, registory, :run_done, req_in ,  "std_logic")
    registory[:arguments].each do |argument|
      vhdl_lines.concat(argument.interface.generate_vhdl_port_list(master))
    end
    if (registory[:return] != nil) then
      vhdl_lines.concat(registory[:return].interface.generate_vhdl_port_list(master))
    end
    return vhdl_lines
  end
    
  def use_package_list(arguments, return_variable)
    list = Array.new
    if arguments.size > 0 then
      list << "MsgPack.MsgPack_RPC_Components.MsgPack_RPC_Method_Main_with_Param"
      arguments.each do |argument|
        list.concat(argument.interface.use_package_list)
      end
    else
      list << "MsgPack.MsgPack_RPC_Components.MsgPack_RPC_Method_Main_no_Param"
    end
    if    return_variable == nil then
      list << "MsgPack.MsgPack_RPC_Components.MsgPack_RPC_Method_Return_Nil"
    elsif return_variable.type.generator_class == "Integer" or
          return_variable.type.generator_class == "Boolean" then
      list << "MsgPack.MsgPack_RPC_Components.MsgPack_RPC_Method_Return_Integer"
    else
      raise "Not Supported method return variable type (#{return_variable.type.class})"
    end
    return list
  end

  module_function :generate_port_list
  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :use_package_list
end
