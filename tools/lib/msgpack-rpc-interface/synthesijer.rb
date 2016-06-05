require_relative 'standard'

module MsgPack_RPC_Interface::Synthesijer
  module Variable
    module Interface
    end
    class  Interface::Register       < MsgPack_RPC_Interface::Standard::Variable::Interface::Register
    end
    class  Interface::Signal         < MsgPack_RPC_Interface::Standard::Variable::Interface::Signal
    end
    class  Interface::Memory         < MsgPack_RPC_Interface::Standard::Variable::Interface::Memory
    end
  end
  module Procedure
    module Interface
    end
    class  Interface::Method         < MsgPack_RPC_Interface::Standard::Procedure::Interface::Method
    end
    class  Interface::StoreVariables < MsgPack_RPC_Interface::Standard::Procedure::Interface::StoreVariables
    end
    class  Interface::QueryVariables < MsgPack_RPC_Interface::Standard::Procedure::Interface::QueryVariables
    end
  end
  module Module
    class Interface                  < MsgPack_RPC_Interface::Standard::Module::Interface
    end
  end
end
