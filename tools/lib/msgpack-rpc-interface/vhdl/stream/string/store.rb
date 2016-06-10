module MsgPack_RPC_Interface::VHDL::Stream::String::Store
  extend  MsgPack_RPC_Interface::VHDL::Util
  include MsgPack_RPC_Interface::VHDL::Stream::Binary::Store
  module_function :generate_body
  module_function :generate_decl
  module_function :generate_stmt
  module_function :use_package_list
end
