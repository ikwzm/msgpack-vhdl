module MsgPack_RPC_Interface::VHDL::Server
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_decl(indent, name, module_interface, server_registory, interface_registory, module_registory)
    vhdl_lines = Array.new
    vhdl_lines << indent + sprintf("signal    %-16s :  std_logic;", server_registory[:internal_reset  ])
    vhdl_lines << indent + sprintf("signal    %-16s :  std_logic;", server_registory[:internal_reset_n])
    
    port_list  = Array.new
    module_interface.methods.each do |m|
      port_list.concat(m.interface.generate_vhdl_port_list(true))
    end
    module_interface.variables.each do |v|
      port_list.concat(v.interface.generate_vhdl_port_list(true))
    end
    port_list.each do |port_desc|
      port_match_list = port_desc.match(/^([a-zA-Z]+[a-zA-Z0-9_]*)\s*:\s*(\w+)\s+(.*)$/)
      vhdl_lines << indent + sprintf("signal    %-16s :  %s;", port_match_list[1], port_match_list[3])
    end
    
    vhdl_lines.concat( module_interface.generate_vhdl_component(indent, interface_registory ))
    vhdl_lines.concat( generate_module_component(indent, module_interface, module_registory ))
    return vhdl_lines
  end

  def generate_stmt(indent, name, module_interface, server_registory, interface_registory, module_registory)
    vhdl_lines = Array.new
    external_registory = server_registory.dup
    if    server_registory.key?(:reset_n) then
        vhdl_lines << indent + sprintf("%-10s", server_registory[:internal_reset  ]) + " <= not #{server_registory[:reset_n]};"
        vhdl_lines << indent + sprintf("%-10s", server_registory[:internal_reset_n]) + " <=     #{server_registory[:reset_n]};"
        external_registory[:reset  ] = server_registory[:internal_reset  ]
        external_registory[:reset_n] = server_registory[:reset_n]
    elsif server_registory.key?(:reset  ) then
        vhdl_lines << indent + sprintf("%-10s", server_registory[:internal_reset  ]) + " <=     #{server_registory[:reset]};"
        vhdl_lines << indent + sprintf("%-10s", server_registory[:internal_reset_n]) + " <= not #{server_registory[:reset]};"
        external_registory[:reset  ] = server_registory[:reset]
        external_registory[:reset_n] = server_registory[:internal_reset_n]
    end
    vhdl_lines.concat( module_interface.generate_vhdl_instance( indent, interface_registory, external_registory))
    vhdl_lines.concat( generate_module_instance( indent, module_interface, module_registory, external_registory ))
    return vhdl_lines
  end
  
  def generate_body(indent, name, module_interface, server_registory, interface_registory, module_registory)
    vhdl_lines = ["library ieee;"                   ,
                  "use     ieee.std_logic_1164.all;",
                  "use     ieee.numeric_std.all;"
                 ]
    indent_sub = indent + "    "
    decl_code  = generate_decl(indent_sub, name, module_interface, server_registory, interface_registory, module_registory)
    if (decl_code.size > 0) then
      block_start = server_registory.fetch(:block_start, "#{name}: block")
      block_end   = server_registory.fetch(:block_end  , "end #{name}")
      return vhdl_lines +
             ["#{indent}#{block_start}"] + 
             decl_code +
             ["#{indent}begin"] +
             generate_stmt(indent_sub, name, module_interface, server_registory, interface_registory, module_registory) +
             ["#{indent}#{block_end};"]
    else
      return vhdl_lines +
             generate_stmt(indent    , name, module_interface, server_registory, interface_registory, module_registory)
    end
  end

  def generate_interface_list(indent, server_registory)
    generic_list = Array.new
    add_generic_line( generic_list, server_registory, :intake_bytes, "integer := 1" )
    add_generic_line( generic_list, server_registory, :outlet_bytes, "integer := 1" )

    intake_bytes = server_registory[:intake_bytes]
    outlet_bytes = server_registory[:outlet_bytes]

    port_list = Array.new
    add_port_line( port_list, server_registory, :clock       , "in ", "std_logic"      )
    add_port_line( port_list, server_registory, :reset       , "in ", "std_logic"      )
    add_port_line( port_list, server_registory, :reset_n     , "in ", "std_logic"      )
    add_port_line( port_list, server_registory, :clear       , "in ", "std_logic"      )
    add_port_line( port_list, server_registory, :intake_data , "in ", "std_logic_vector(8*#{intake_bytes}-1 downto 0)" )
    add_port_line( port_list, server_registory, :intake_strb , "in ", "std_logic_vector(  #{intake_bytes}-1 downto 0)" )
    add_port_line( port_list, server_registory, :intake_last , "in ", "std_logic"      )
    add_port_line( port_list, server_registory, :intake_valid, "in ", "std_logic"      )
    add_port_line( port_list, server_registory, :intake_ready, "out", "std_logic"      )
    add_port_line( port_list, server_registory, :outlet_data , "out", "std_logic_vector(8*#{outlet_bytes}-1 downto 0)" )
    add_port_line( port_list, server_registory, :outlet_strb , "out", "std_logic_vector(  #{outlet_bytes}-1 downto 0)" )
    add_port_line( port_list, server_registory, :outlet_last , "out", "std_logic"      )
    add_port_line( port_list, server_registory, :outlet_valid, "out", "std_logic"      )
    add_port_line( port_list, server_registory, :outlet_ready, "in ", "std_logic"      )

    vhdl_lines   = Array.new
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

  def generate_entity(indent, name, module_interface, server_registory, interface_registory, module_registory)
    vhdl_lines = ["library ieee;"                   ,
                  "use     ieee.std_logic_1164.all;"
                 ]
    vhdl_lines << indent + "entity  #{name} is"
    vhdl_lines.concat(generate_interface_list(indent + "    ", server_registory))
    vhdl_lines << indent + "end     #{name};"
    return vhdl_lines
  end
  
  def generate_module_component(indent, module_interface, module_registory)
    module_name = module_registory[:name]

    port_list  = Array.new
    add_port_line( port_list, module_registory, :clock   , "in ", "std_logic" )
    add_port_line( port_list, module_registory, :reset   , "in ", "std_logic" )
    add_port_line( port_list, module_registory, :reset_n , "in ", "std_logic" )
    add_port_line( port_list, module_registory, :clear   , "in ", "std_logic" )
    
    module_interface.methods.each   do |m|
      port_list.concat(m.interface.generate_vhdl_port_list(false))
    end

    module_interface.variables.each do |v|
      port_list.concat(v.interface.generate_vhdl_port_list(false))
    end

    vhdl_lines  = [ indent + "component #{module_name} is" ]
    indent_sub  = indent + "    "
    if port_list.size    > 0 then
      vhdl_lines << indent_sub + "port("
      vhdl_lines.concat(port_list.join(";\n").split("\n").map{|s| indent_sub + "    " + s})
      vhdl_lines << indent_sub + ");"
    end
    vhdl_lines << indent + "end component;"

    return vhdl_lines
  end

  def generate_module_instance(indent, module_interface, module_registory, external_registory)
    module_name   = module_registory[:name]
    instance_name = external_registory.fetch(:instance_name, "T")

    port_map_list = Array.new
    add_port_map_line( port_map_list, module_registory, external_registory, :clock   ) 
    add_port_map_line( port_map_list, module_registory, external_registory, :reset   )
    add_port_map_line( port_map_list, module_registory, external_registory, :reset_n )
    add_port_map_line( port_map_list, module_registory, external_registory, :clear   )

    port_list = Array.new
    module_interface.methods.each   do |m|
      port_list.concat(m.interface.generate_vhdl_port_list(false))
    end
    module_interface.variables.each do |v|
      port_list.concat(v.interface.generate_vhdl_port_list(false))
    end
    port_list.each do |port_desc|
      port_name = port_desc.match(/^([a-zA-Z]+[a-zA-Z0-9_]*)/)[0]
      port_map_list << sprintf("%-20s => %-20s", port_name, port_name)
    end

    vhdl_lines = [ indent + "#{instance_name} : #{module_name}" ]
    indent_sub = indent + "    "
    if port_map_list.size    > 0 then
      vhdl_lines << indent_sub + "port map("
      vhdl_lines.concat(port_map_list.join(",\n").split("\n").map{|s| indent_sub + "    " + s})
      vhdl_lines << indent_sub + ");"
    end
    return vhdl_lines
  end
  
  module_function :generate_entity
  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :generate_module_component
  module_function :generate_module_instance
  module_function :generate_interface_list
  
end
