module MsgPack_RPC_Interface::VHDL::Memory::String::Store
  extend  MsgPack_RPC_Interface::VHDL::Util
  include MsgPack_RPC_Interface::VHDL::Memory::Binary::Store
  module_function :instance_name
  module_function :interface_signals
  module_function :sub_block?
  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :generate_stmt_post
  module_function :use_package_list
end
