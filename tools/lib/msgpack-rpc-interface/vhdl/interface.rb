require 'set'

module MsgPack_RPC_Interface::VHDL::Interface
  extend MsgPack_RPC_Interface::VHDL::Util
    
  def generate_decl(indent, name, interface, registory)
    code_width  = registory[:code_width ]
    match_phase = registory[:match_phase]
    vhdl_lines  = string_to_lines(
      indent, <<"        EOT"
          constant  PROC_NUM          :  integer := #{interface.methods.size};
          signal    proc_match_req    :  std_logic_vector        (#{match_phase}-1 downto 0);
          signal    proc_match_code   :  MsgPack_RPC.Code_Type;
          signal    proc_match_ok     :  std_logic_vector        (PROC_NUM-1 downto 0);
          signal    proc_match_not    :  std_logic_vector        (PROC_NUM-1 downto 0);
          signal    proc_match_shift  :  MsgPack_RPC.Shift_Vector(PROC_NUM-1 downto 0);
          signal    proc_req_id       :  MsgPack_RPC.MsgID_Type;
          signal    proc_req          :  std_logic_vector        (PROC_NUM-1 downto 0);
          signal    proc_busy         :  std_logic_vector        (PROC_NUM-1 downto 0);
          signal    proc_param_code   :  MsgPack_RPC.Code_Vector (PROC_NUM-1 downto 0);
          signal    proc_param_valid  :  std_logic_vector        (PROC_NUM-1 downto 0);
          signal    proc_param_last   :  std_logic_vector        (PROC_NUM-1 downto 0);
          signal    proc_param_shift  :  MsgPack_RPC.Shift_Vector(PROC_NUM-1 downto 0);
          signal    proc_res_id       :  MsgPack_RPC.MsgID_Vector(PROC_NUM-1 downto 0);
          signal    proc_res_code     :  MsgPack_RPC.Code_Vector (PROC_NUM-1 downto 0);
          signal    proc_res_valid    :  std_logic_vector        (PROC_NUM-1 downto 0);
          signal    proc_res_last     :  std_logic_vector        (PROC_NUM-1 downto 0);
          signal    proc_res_ready    :  std_logic_vector        (PROC_NUM-1 downto 0);
        EOT
    )
    (interface.methods + interface.variables).map{|a| a.interface.blocks}.flatten.each do |block|
      vhdl_lines.concat(block.generate_vhdl_decl(indent, registory))
    end
    return vhdl_lines
  end

  def generate_stmt(indent, name, interface, registory)
    code_width  = registory[:code_width ]
    match_phase = registory[:match_phase]
    vhdl_lines  = string_to_lines(
      indent, <<"        EOT"
          PROC_SERVER: MsgPack_RPC_Server                   -- 
              generic map (              #{sprintf("%-28s", ""                      )}   -- 
                  I_BYTES             => #{sprintf("%-28s", registory[:intake_bytes])} , --
                  O_BYTES             => #{sprintf("%-28s", registory[:outlet_bytes])} , --
                  PROC_NUM            => #{sprintf("%-28s", "PROC_NUM"              )} , --
                  MATCH_PHASE         => #{sprintf("%-28s", match_phase             )}   --
              )                          #{sprintf("%-28s", ""                      )}   -- 
              port map (                 #{sprintf("%-28s", ""                      )}   -- 
                  CLK                 => #{sprintf("%-28s", registory[:clock       ])} , -- In  :
                  RST                 => #{sprintf("%-28s", registory[:reset       ])} , -- in  :
                  CLR                 => #{sprintf("%-28s", registory[:clear       ])} , -- in  :
                  I_DATA              => #{sprintf("%-28s", registory[:intake_data ])} , -- In  :
                  I_STRB              => #{sprintf("%-28s", registory[:intake_strb ])} , -- In  :
                  I_LAST              => #{sprintf("%-28s", registory[:intake_last ])} , -- In  :
                  I_VALID             => #{sprintf("%-28s", registory[:intake_valid])} , -- In  :
                  I_READY             => #{sprintf("%-28s", registory[:intake_ready])} , -- Out :
                  O_DATA              => #{sprintf("%-28s", registory[:outlet_data ])} , -- Out :
                  O_STRB              => #{sprintf("%-28s", registory[:outlet_strb ])} , -- Out :
                  O_LAST              => #{sprintf("%-28s", registory[:outlet_last ])} , -- Out :
                  O_VALID             => #{sprintf("%-28s", registory[:outlet_valid])} , -- Out :
                  O_READY             => #{sprintf("%-28s", registory[:outlet_ready])} , -- In  :
                  MATCH_REQ           => #{sprintf("%-28s", "proc_match_req"        )} , -- Out :
                  MATCH_CODE          => #{sprintf("%-28s", "proc_match_code"       )} , -- Out :
                  MATCH_OK            => #{sprintf("%-28s", "proc_match_ok"         )} , -- In  :
                  MATCH_NOT           => #{sprintf("%-28s", "proc_match_not"        )} , -- In  :
                  MATCH_SHIFT         => #{sprintf("%-28s", "proc_match_shift"      )} , -- In  :
                  PROC_REQ_ID         => #{sprintf("%-28s", "proc_req_id"           )} , -- Out :
                  PROC_REQ            => #{sprintf("%-28s", "proc_req"              )} , -- Out :
                  PROC_BUSY           => #{sprintf("%-28s", "proc_busy"             )} , -- In  :
                  PARAM_VALID         => #{sprintf("%-28s", "proc_param_valid"      )} , -- Out :
                  PARAM_CODE          => #{sprintf("%-28s", "proc_param_code"       )} , -- Out :
                  PARAM_LAST          => #{sprintf("%-28s", "proc_param_last"       )} , -- Out :
                  PARAM_SHIFT         => #{sprintf("%-28s", "proc_param_shift"      )} , -- In  :
                  PROC_RES_ID         => #{sprintf("%-28s", "proc_res_id"           )} , -- In  :
                  PROC_RES_CODE       => #{sprintf("%-28s", "proc_res_code"         )} , -- In  :
                  PROC_RES_VALID      => #{sprintf("%-28s", "proc_res_valid"        )} , -- In  :
                  PROC_RES_LAST       => #{sprintf("%-28s", "proc_res_last"         )} , -- In  :
                  PROC_RES_READY      => #{sprintf("%-28s", "proc_res_ready"        )}   -- Out :
              );                         #{sprintf("%-28s", ""                      )}   -- 
        EOT
    )
    interface.methods.each_with_index do |method, num|
      method_registory = Hash.new
      method_registory[:code_width ] = code_width
      method_registory[:match_phase] = match_phase
      method_registory[:clock      ] = registory[:clock]
      method_registory[:reset      ] = registory[:reset]
      method_registory[:clear      ] = registory[:clear]
      method_registory[:match_req  ] = "proc_match_req"
      method_registory[:match_code ] = "proc_match_code"
      method_registory[:match_ok   ] = "proc_match_ok   (#{num})"
      method_registory[:match_not  ] = "proc_match_not  (#{num})"
      method_registory[:match_shift] = "proc_match_shift(#{num})"
      method_registory[:proc_req_id] = "proc_req_id"
      method_registory[:proc_req   ] = "proc_req        (#{num})"
      method_registory[:proc_busy  ] = "proc_busy       (#{num})"
      method_registory[:param_code ] = "proc_param_code (#{num})"
      method_registory[:param_valid] = "proc_param_valid(#{num})"
      method_registory[:param_last ] = "proc_param_last (#{num})"
      method_registory[:param_shift] = "proc_param_shift(#{num})"
      method_registory[:proc_res_id] = "proc_res_id     (#{num})"
      method_registory[:res_code   ] = "proc_res_code   (#{num})"
      method_registory[:res_valid  ] = "proc_res_valid  (#{num})"
      method_registory[:res_last   ] = "proc_res_last   (#{num})"
      method_registory[:res_ready  ] = "proc_res_ready  (#{num})"
      vhdl_lines.concat(method.interface.generate_vhdl_body(indent, method_registory))
    end
    (interface.methods + interface.variables).map{|a| a.interface.blocks}.flatten.each do |block|
      vhdl_lines.concat(block.generate_vhdl_stmt(indent, registory))
    end
    return vhdl_lines
  end
    
  def generate_body(indent, name, interface, registory)
    indent_sub = indent + "    "
    decl_code  = generate_decl(indent_sub, name, interface, registory)
    if (decl_code.size > 0) then
      block_start = registory.fetch(:block_start, "#{name}: block")
      block_end   = registory.fetch(:block_end  , "end #{name}")
      return ["#{indent}#{block_start}"] + 
             decl_code +
             ["#{indent}begin"] +
             generate_stmt(indent_sub, name, interface, registory) +
             ["#{indent}#{block_end};"]
    else
      return generate_stmt(indent    , name, interface, registory)
    end
  end

  def generate_interface_list(indent, interface, registory)
    generic_list = Array.new
    add_generic_line( generic_list, registory, :intake_bytes, "integer := 1")
    add_generic_line( generic_list, registory, :outlet_bytes, "integer := 1")

    port_list = Array.new
    add_port_line( port_list, registory, :clock       , "in ", "std_logic"      )
    add_port_line( port_list, registory, :reset       , "in ", "std_logic"      )
    add_port_line( port_list, registory, :clear       , "in ", "std_logic"      )
    add_port_line( port_list, registory, :intake_data , "in ", "std_logic_vector(8*#{registory[:intake_bytes]}-1 downto 0)")
    add_port_line( port_list, registory, :intake_strb , "in ", "std_logic_vector(  #{registory[:intake_bytes]}-1 downto 0)")
    add_port_line( port_list, registory, :intake_last , "in ", "std_logic"      )
    add_port_line( port_list, registory, :intake_valid, "in ", "std_logic"      )
    add_port_line( port_list, registory, :intake_ready, "out", "std_logic"      )
    add_port_line( port_list, registory, :outlet_data , "out", "std_logic_vector(8*#{registory[:outlet_bytes]}-1 downto 0)")
    add_port_line( port_list, registory, :outlet_strb , "out", "std_logic_vector(  #{registory[:outlet_bytes]}-1 downto 0)")
    add_port_line( port_list, registory, :outlet_last , "out", "std_logic"      )
    add_port_line( port_list, registory, :outlet_valid, "out", "std_logic"      )
    add_port_line( port_list, registory, :outlet_ready, "in ", "std_logic"      )

    interface.methods.each   do |m|
      port_list.concat(m.interface.generate_vhdl_port_list(true))
    end

    interface.variables.each do |v|
      port_list.concat(v.interface.generate_vhdl_port_list(true))
    end

    vhdl_lines = Array.new
    if generic_list.size > 0 then
      vhdl_lines << indent + "generic("
      vhdl_lines.concat(generic_list.join(";\n").split("\n").map{|s| indent + "    " + s})
      vhdl_lines << indent + ");"
    end
      
    if port_list.size    > 0 then
      vhdl_lines << indent + "port("
      vhdl_lines.concat(port_list.join(";\n").split("\n").map{|s| indent + "    " + s})
      vhdl_lines << indent + ");"
    end

    return vhdl_lines
  end

  def generate_entity(indent, name, interface, registory)
    vhdl_lines = ["library ieee;"                   ,
                  "use     ieee.std_logic_1164.all;",
                  "use     ieee.numeric_std.all;"   
                 ]
    vhdl_lines << indent + "entity  #{name} is"
    vhdl_lines.concat(generate_interface_list(indent + "    ", interface, registory))
    vhdl_lines << indent + "end     #{name};"
    return vhdl_lines
  end

  def generate_component(indent, name, interface, registory)
    vhdl_lines = Array.new
    vhdl_lines << indent + "component #{name} is"
    vhdl_lines.concat(generate_interface_list(indent + "    ", interface, registory))
    vhdl_lines << indent + "end component;"
    return vhdl_lines
  end

  def generate_instance(indent, name, interface, registory, external_registory)
    vhdl_lines = Array.new
    instance_name = external_registory.fetch(:instance_name, "U")
    vhdl_lines << indent + "#{instance_name} : #{name}"

    generic_map_list = Array.new
    add_generic_map_line( generic_map_list, registory, external_registory, :intake_bytes )
    add_generic_map_line( generic_map_list, registory, external_registory, :outlet_bytes )

    port_map_list    = Array.new
    add_port_map_line( port_map_list, registory, external_registory, :clock        ) 
    add_port_map_line( port_map_list, registory, external_registory, :reset        )
    add_port_map_line( port_map_list, registory, external_registory, :clear        )
    add_port_map_line( port_map_list, registory, external_registory, :intake_data  )
    add_port_map_line( port_map_list, registory, external_registory, :intake_strb  )
    add_port_map_line( port_map_list, registory, external_registory, :intake_last  )
    add_port_map_line( port_map_list, registory, external_registory, :intake_valid )
    add_port_map_line( port_map_list, registory, external_registory, :intake_ready )
    add_port_map_line( port_map_list, registory, external_registory, :outlet_data  )
    add_port_map_line( port_map_list, registory, external_registory, :outlet_strb  )
    add_port_map_line( port_map_list, registory, external_registory, :outlet_last  )
    add_port_map_line( port_map_list, registory, external_registory, :outlet_valid )
    add_port_map_line( port_map_list, registory, external_registory, :outlet_ready )

    port_list = Array.new
    interface.methods.each   do |m|
      port_list.concat(m.interface.generate_vhdl_port_list(true))
    end
    interface.variables.each do |v|
      port_list.concat(v.interface.generate_vhdl_port_list(true))
    end
    port_list.each do |port_desc|
      port_name = port_desc.match(/^([a-zA-Z]+[a-zA-Z_]*)/)[0]
      port_map_list << sprintf("%-20s => %-20s", port_name, port_name)
    end

    indent_sub = indent + "    "
    if generic_map_list.size > 0 then
      vhdl_lines << indent_sub + "generic map("
      vhdl_lines.concat(generic_map_list.join(",\n").split("\n").map{|s| indent_sub + "    " + s})
      vhdl_lines << indent_sub + ")"
    end
      
    if port_map_list.size    > 0 then
      vhdl_lines << indent_sub + "port map("
      vhdl_lines.concat(port_map_list.join(",\n").split("\n").map{|s| indent_sub + "    " + s})
      vhdl_lines << indent_sub + ");"
    end
    
    return vhdl_lines
  end

  def use_package_list
    return ["MsgPack.MsgPack_Object",
            "MsgPack.MsgPack_RPC"   ,
            "MsgPack.MsgPack_RPC_Components.MsgPack_RPC_Server"]
  end

  def generate_use(interface)
    use_set    = Set.new(use_package_list)
    lib_set    = Set.new
    vhdl_lines = ["library ieee;"                   ,
                  "use     ieee.std_logic_1164.all;",
                  "use     ieee.numeric_std.all;"   
                 ]
    interface.methods.each   do |m|
      use_set.merge(Set.new(m.interface.use_package_list))
    end
    interface.variables.each do |v|
      use_set.merge(Set.new(v.interface.use_package_list))
    end
    use_set.each do |use|
      lib_set << use.split(".")[0]
    end
    lib_set.each do |lib|
      vhdl_lines << "library #{lib};"
    end
    use_set.each do |use|
      vhdl_lines << "use     #{use};"
    end
    return vhdl_lines
  end
    
  module_function :generate_use
  module_function :generate_entity
  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :generate_component
  module_function :generate_instance
  module_function :generate_interface_list
  module_function :use_package_list
end
