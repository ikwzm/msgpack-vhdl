module MsgPack_RPC_Interface::VHDL::Signal::Integer::Store
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_decl(indent, name, type, kvmap, registory)
    block_regs = registory.dup
    block_regs[:store_data ] = "proc_0_value"
    block_regs[:store_valid] = "proc_0_valid"
    value_type = MsgPack_RPC_Interface::Standard::Type::Integer.new(Hash({"width" => type.bits, "sign" => type.sign}))
    generator  = MsgPack_RPC_Interface::VHDL::Register::Integer::Store
    return string_to_lines(
      indent, <<"      EOT"
           signal    #{block_regs[:store_data ]} :  #{value_type.vhdl_type};
           signal    #{block_regs[:store_valid]} :  std_logic;
      EOT
    ).concat(generator.generate_decl(indent, name, value_type, kvmap, block_regs))
  end

  def generate_stmt(indent, name, type, kvmap, registory)
    block_regs = registory.dup
    block_regs[:store_data ] = "proc_0_value"
    block_regs[:store_valid] = "proc_0_valid"
    value_type = MsgPack_RPC_Interface::Standard::Type::Integer.new(Hash({"width" => type.bits, "sign" => type.sign}))
    generator  = MsgPack_RPC_Interface::VHDL::Register::Integer::Store
    return string_to_lines(
      indent, <<"      EOT"
             process(#{registory[:clock]}, #{registory[:reset]}) begin
                 if (#{registory[:reset]} = '1') then
                          #{type.generate_vhdl_reset_value(registory[:store_data], 0)}
                 elsif (#{registory[:clock]}'event and #{registory[:clock]} = '1') then
                     if    (#{registory[:clear]} = '1') then
                          #{type.generate_vhdl_reset_value(registory[:store_data], 0)}
                     elsif (proc_0_valid = '1') then
                          #{type.generate_vhdl_convert_from_std_logic_vector(registory[:store_data], block_regs[:store_data])}
                     end if;
                 end if;
             end process;
      EOT
    ).concat(generator.generate_stmt(indent, name, value_type, kvmap, block_regs))
  end

  def generate_body(indent, name, type, kvmap, registory)
    block_name = registory.fetch(:instance_name, "PROC_0_" + name.upcase)
    decl_lines = generate_decl(indent + "    ", name, type, kvmap, registory)
    stmt_lines = generate_stmt(indent + "    ", name, type, kvmap, registory)
    return ["#{indent}#{block_name}: block"] + 
           decl_lines + 
           ["#{indent}begin"] +
           stmt_lines +
           ["#{indent}end block;"]
  end

  def use_package_list(kvmap)
    return MsgPack_RPC_Interface::VHDL::Register::Integer::Store.use_package_list(kvmap)
  end

  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :use_package_list

end
