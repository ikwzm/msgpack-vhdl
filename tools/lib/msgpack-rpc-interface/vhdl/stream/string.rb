module MsgPack_RPC_Interface::VHDL::Stream::String
  extend  MsgPack_RPC_Interface::VHDL::Util
  include MsgPack_RPC_Interface::VHDL::Stream::Binary
  module_function  :generate_port_list
  require_relative 'string/store'
  require_relative 'string/query'
end
