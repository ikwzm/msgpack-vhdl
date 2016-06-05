module MsgPack_RPC_Interface::VHDL::Signal::Integer::Decode

  def generate_decl(indent, name, type, registory)
    return MsgPack_RPC_Interface::VHDL::Signal::Integer::StoreDecode.generate_decl(:Decode, indent, name, type, registory)
  end

  def generate_stmt(indent, name, type, registory)
    return MsgPack_RPC_Interface::VHDL::Signal::Integer::StoreDecode.generate_stmt(:Decode, indent, name, type, registory)
  end

  def generate_body(indent, name, type, registory)
    return MsgPack_RPC_Interface::VHDL::Signal::Integer::StoreDecode.generate_body(:Decode, indent, name, type, registory)
  end

  def use_package_list
    return MsgPack_RPC_Interface::VHDL::Register::Integer::Decode.use_package_list
  end

  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :use_package_list
end

