module MsgPack_RPC_Interface::VHDL::Type

  module Unsigned
    def vhdl_type
      return "unsigned(#{@bits}-1 downto 0)"
    end
    def std_logic_vector?
      return false
    end
    def generate_vhdl_convert_from_std_logic_vector(name, value_name)
      return "#{name} <= unsigned(#{value_name});"
    end
    def generate_vhdl_convert_to_std_logic_vector(name, value_name)
      return "#{value_name} <= std_logic_vector(#{name});"
    end
  end

  module Signed
    def vhdl_type
      return "signed(#{@bits}-1 downto 0)"
    end
    def std_logic_vector?
      return false
    end
    def generate_vhdl_convert_from_std_logic_vector(name, value_name)
      return "#{name} <= signed(#{value_name});"
    end
    def generate_vhdl_convert_to_std_logic_vector(  name, value_name)
      return "#{value_name} <= std_logic_vector(#{name});"
    end
  end

  module Std_Logic
    def vhdl_type
      return "std_logic"
    end
    def std_logic_vector?
      return false
    end
    def generate_vhdl_convert_from_std_logic_vector(name, value_name)
      return "#{name} <= #{value_name}(0);"
    end
    def generate_vhdl_convert_to_std_logic_vector(  name, value_name)
      return "#{value_name}(0) <= #{name};"
    end
  end

  module Std_Logic_Vector
    def vhdl_type
      return "std_logic_vector(#{@bits}-1 downto 0)"
    end
    def std_logic_vector?
      return true
    end
    def generate_vhdl_convert_from_std_logic_vector(name, value_name)
      return "#{name} <= #{value_name};"
    end
    def generate_vhdl_convert_to_std_logic_vector(  name, value_name)
      return "#{value_name} <= #{name};"
    end
  end
  
  module Boolean
    extend  MsgPack_RPC_Interface::VHDL::Util
    def vhdl_type
      return "boolean"
    end
    def std_logic_vector?
      return false
    end
    def generate_vhdl_convert_from_std_logic_vector(name, value_name)
      return "#{name} <= (#{value_name}(0) = '1');"
    end
    def generate_vhdl_convert_to_std_logic_vector(  name, value_name)
      return "#{value_name} <= (others => '1') when #{name} else (others => '0');"
    end
  end
end
