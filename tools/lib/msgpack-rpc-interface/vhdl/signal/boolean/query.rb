module MsgPack_RPC_Interface::VHDL::Signal::Boolean::Query
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_decl(indent, name, type, kvmap, registory)
    return MsgPack_RPC_Interface::VHDL::Register::Boolean::Query.generate_decl(indent, name, type, kvmap, registory)
  end

  def generate_stmt(indent, name, type, kvmap, registory)
    return MsgPack_RPC_Interface::VHDL::Register::Boolean::Query.generate_stmt(indent, name, type, kvmap, registory)
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
    return MsgPack_RPC_Interface::VHDL::Register::Boolean::Query.use_package_list(kvmap)
  end

  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :use_package_list

end
