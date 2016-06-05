module MsgPack_RPC_Interface::VHDL::Signal::Integer::Store

  def generate_decl(indent, name, type, registory)
    return StoreDecode.generate_decl(:Store , indent, name, type, registory)
  end

  def generate_stmt(indent, name, type, registory)
    return StoreDecode.generate_stmt(:Store , indent, name, type, registory)
  end

  def generate_body(indent, name, type, registory)
    return StoreDecode.generate_body(:Store , indent, name, type, registory)
  end

  def use_package_list
    return MsgPack_RPC_Interface::VHDL::Register::Integer::Store.use_package_list
  end

  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :use_package_list

end
