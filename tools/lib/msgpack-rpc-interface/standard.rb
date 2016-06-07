require_relative 'vhdl'

module MsgPack_RPC_Interface::Standard

  CODE_WIDTH  = "MsgPack_RPC.Code_Length"
  MATCH_PHASE = "8"

  module Variable
  end

  module Procedure
  end

  module Module
  end

  class  Variable::Interface
    class Base
      attr_reader :name, :msg_class, :type, :read, :write, :kvmap, :full_name, :port_name

      def initialize(registory)
        @debug     = registory.fetch("debug", false)
        @name      = registory["name"     ]
        @msg_class = registory["class"    ]
        @type      = registory["type"     ]
        @full_name = registory["full_name"]
        @port_name = registory.fetch("port_name", @full_name.join("_"))
        @read      = registory.fetch("read"     , true)
        @write     = registory.fetch("write"    , true)
        @kvmap     = registory.fetch("kvmap"    , true)
      end

      def to_s
        return "#{self.class.name}: {name: #{@name}, full_name: #{@full_name}, class: #{@msg_class.to_s}, type: #{@type.to_s}, kvmap: #{kvmap}, read: #{@read}, write: #{@write}}"
      end

    end

    class  Register < Base

      attr_reader :generator, :port_rdata, :port_wdata, :port_we

      def initialize(registory)
        super(registory)
        @port_rdata = @port_name + "_rdata"
        @port_wdata = @port_name + "_wdata"
        @port_we    = @port_name + "_we"
        if registory.key?("port") then
          port_regs = registory["port"]
          @port_rdata = port_regs.fetch("rdata", @port_rdata)
          @port_wdata = port_regs.fetch("wdata", @port_wdata)
          @port_we    = port_regs.fetch("we"   , @port_we   )
        end
        @generator = MsgPack_RPC_Interface::VHDL::Register.const_get(@msg_class.class.to_s.split('::').last)
        puts to_s if @debug
      end
      
      def generate_vhdl_body_store(indent, registory)
        new_regs = registory.dup
        new_regs[:write_value] = registory.fetch(:write_value, @port_wdata)
        new_regs[:write_valid] = registory.fetch(:write_valid, @port_we   )
        return @generator::Store.generate_body(indent, @name, @type, @kvmap, new_regs)
      end

      def generate_vhdl_body_query(indent, registory)
        new_regs = registory.dup
        new_regs[:read_value]  = registory.fetch(:read_value , @port_rdata)
        return @generator::Query.generate_body(indent, @name, @type, @kvmap, new_regs)
      end

      def generate_vhdl_port_list(master)
        new_regs = Hash.new
        new_regs[:read_value ] = @port_rdata if @read  == true
        new_regs[:write_value] = @port_wdata if @write == true
        new_regs[:write_valid] = @port_we    if @write == true
        return @generator.generate_port_list(master, @type, @kvmap, new_regs)
      end

      def use_package_list
        use_list = Array.new
        if @read  then
          use_list.concat(@generator::Query.use_package_list(@kvmap))
        end
        if @write then
          use_list.concat(@generator::Store.use_package_list(@kvmap))
        end
        return use_list
      end

      def to_s
        return super + " port_rdata: #{port_rdata}, port_wdata: #{port_wdata}, port_we: #{port_we}"
      end
    end

    class  Signal   < Base

      attr_reader :generator, :port_rdata, :port_wdata, :port_we

      def initialize(registory)
        super(registory)
        if    @read == true  and @write == true  then
          @port_rdata = @port_name + "_rdata"
          @port_wdata = @port_name + "_wdata"
          @port_we    = @port_name + "_we"
        elsif @read == true  and @write == false then
          @port_rdata = @port_name
          @port_wdata = nil
          @port_we    = nil
        elsif @read == false and @write == true  then
          @port_rdata = nil
          @port_wdata = @port_name
          @port_we    = @port_name + "_we"
        else
          @port_rdata = nil
          @port_wdata = nil
          @port_we    = nil
        end
        if registory.key?("port") then
          if @read  == true then
            @port_rdata = registory["port"].fetch("rdata", @port_rdata)
          end
          if @write == true then
            @port_wdata = registory["port"].fetch("wdata", @port_wdata)
            @port_we    = registory["port"].fetch("we"   , @port_we   )
          end
        end
        @generator = MsgPack_RPC_Interface::VHDL::Signal.const_get(@msg_class.class.to_s.split('::').last)
        puts to_s if @debug
      end

      def generate_vhdl_body_store(indent, registory)
        new_regs = registory.dup
        new_regs[:write_value] = registory.fetch(:write_value, @port_wdata)
        return @generator::Store.generate_body(indent, @name, @type, @kvmap, new_regs)
      end

      def generate_vhdl_body_query(indent, registory)
        new_regs = registory.dup
        new_regs[:read_value]  = registory.fetch(:read_value , @port_rdata)
        return @generator::Query.generate_body(indent, @name, @type, @kvmap, new_regs)
      end

      def generate_vhdl_port_list(master)
        new_regs = Hash.new
        new_regs[:read_value ] = @port_rdata if @read  == true
        new_regs[:write_value] = @port_wdata if @write == true
        return @generator.generate_port_list(master, @type, @kvmap, new_regs)
      end

      def use_package_list
        use_list = Array.new
        if @read then
          use_list.concat(@generator::Query.use_package_list(@kvmap))
        end
        if @write then
          use_list.concat(@generator::Store.use_package_list(@kvmap))
        end
        puts "=== #{use_list}"
        return use_list
      end

    end

    class  Memory   < Base


    end
  end

  module Type

    class Base
      def to_s
        return "#{self.class.name}"
      end
      def initialize(registory)
      end
    end

    class Integer < Base
      attr_reader :width, :sign
      def initialize(registory)
        @width = registory.fetch("width", 32  )
        @sign  = registory.fetch("sign" , true)
      end
      def generate_vhdl_type
        return "std_logic_vector(#{@width}-1 downto 0)"
      end
      def generate_vhdl_convert(value)
        return value
      end
    end

    class Unsigned < Base
      attr_reader :width, :sign
      def initialize(registory)
        @width = registory.fetch("width", 32  )
        @sign  = false
      end
      def generate_vhdl_type
        return "unsigned(#{@width}-1 downto 0)"
      end
      def generate_vhdl_convert(value)
        return "unsigned(#{value})"
      end
    end

    class Signed < Base
      attr_reader :width, :sign
      def initialize(registory)
        @width = registory.fetch("width", 32  )
        @sign  = true
      end
      def generate_vhdl_type
        return "signed(#{@width}-1 downto 0)"
      end
      def generate_vhdl_convert(value)
        return "signed(#{value})"
      end
    end

    class Logic   < Base
      def initialize(registory)
      end
      def generate_vhdl_type
        return "std_logic"
      end
      def generate_vhdl_convert(value)
        return "signed(#{value})"
      end
    end

    class Logic_Vector < Base
      attr_reader :width
      def initialize(registory)
        @width = registory.fetch("width", nil)
      end
      def generate_vhdl_type
        return "std_logic_vector(#{@width}-1 downto 0)"
      end
    end

    class Boolean < Base
      def initialize(registory)
      end
      def generate_vhdl_type
        return "boolean"
      end
    end

    class Map     < Base
    end
  end

  class  Procedure::Interface

    class Method

      attr_reader :name, :full_name, :arguments, :return, :req_name, :busy_name, :return_name

      def initialize(registory)
        @debug       = registory.fetch("debug", false)
        @name        = registory["name"]
        @full_name   = registory["full_name"]
        @arguments   = registory["arguments"]
        @return      = registory["return"]
        @req_name    = @full_name.join("_") + "_REQ"
        @busy_name   = @full_name.join("_") + "_BUSY"
        @return_name = (@return != nil) ? (@full_name.join("_") + "_" + @return.name) : nil
        if registory.key?("port") then
          @req_name    = registory["port"].fetch("request", @req_name)
          @busy_name   = registory["port"].fetch("busy"   , @busy_name)
          @return_name = registory["port"].fetch("return" , @return_name)
        end
      end

      def generate_vhdl_body(indent, registory)
        new_regs = Hash({code_width:  CODE_WIDTH ,
                         match_phase: MATCH_PHASE,
                        }).update(registory)
        new_regs[:run_req    ] = @req_name
        new_regs[:run_busy   ] = @busy_name
        new_regs[:return_name] = @return_name
        return MsgPack_RPC_Interface::VHDL::Procedure::Method.generate_body(indent, name, @arguments, @return, new_regs)
      end

      def generate_vhdl_port_list(master)
        new_regs = Hash.new
        new_regs[:run_req    ] = @req_name
        new_regs[:run_busy   ] = @busy_name
        new_regs[:arguments  ] = @arguments
        new_regs[:return     ] = @return
        return MsgPack_RPC_Interface::VHDL::Procedure::Method.generate_port_list(master, new_regs)
      end
      
      def use_package_list
        return MsgPack_RPC_Interface::VHDL::Procedure::Method.use_package_list(@arguments, @return)
      end
    end

    class StoreVariables

      attr_reader :name, :full_name, :variables

      def initialize(registory)
        @debug     = registory.fetch("debug", false)
        @name      = registory["name"]
        @full_name = registory["full_name"]
        @variables = registory["variables"]
      end

      def generate_vhdl_body(indent, registory)
        new_regs = Hash({code_width:  CODE_WIDTH ,
                         match_phase: MATCH_PHASE,
                         key:         true
                        }).update(registory)
        return MsgPack_RPC_Interface::VHDL::Procedure::StoreVariables.generate_body(indent, name, @variables, new_regs)
      end

      def generate_vhdl_port_list(master)
        return []
      end

      def use_package_list
        return MsgPack_RPC_Interface::VHDL::Procedure::StoreVariables.use_package_list
      end

    end

    class QueryVariables

      attr_reader :name, :full_name, :variables

      def initialize(registory)
        @debug     = registory.fetch("debug", false)
        @name      = registory["name"]
        @full_name = registory["full_name"]
        @variables = registory["variables"]
      end

      def generate_vhdl_body(indent, registory)
        new_regs = Hash({code_width:  CODE_WIDTH ,
                         match_phase: MATCH_PHASE,
                         key:         true
                        }).update(registory)
        return MsgPack_RPC_Interface::VHDL::Procedure::QueryVariables.generate_body(indent, name, @variables, new_regs)
      end
      
      def generate_vhdl_port_list(master)
        return []
      end

      def use_package_list
        return MsgPack_RPC_Interface::VHDL::Procedure::QueryVariables.use_package_list
      end

    end
  end

  class Module::Interface
      attr_reader :name, :full_name, :methods, :variables

      def initialize(registory)
        @debug     = registory.fetch("debug", false)
        @name      = registory["name"]
        @full_name = registory["full_name"]
        @methods   = registory["methods"]
        @variables = registory["variables"]
      end

      def generate_vhdl_entity(indent, registory)
        name = registory.fetch(:name , @name)
        return MsgPack_RPC_Interface::VHDL::Module.generate_entity(indent, name, @methods, @variables, registory)
      end

      def generate_vhdl_body(indent, registory)
        name = registory.fetch(:name , @name)
        new_regs = Hash({code_width:  CODE_WIDTH ,
                         match_phase: MATCH_PHASE
                        }).update(registory)
        return MsgPack_RPC_Interface::VHDL::Module.generate_body(indent, name, @methods, new_regs)
      end

      def generate_vhdl_architecture(indent, registory)
        name = registory.fetch(:name , @name)
        new_regs = Hash({block_start: "architecture RTL of #{name} is",
                         block_end:   "end RTL"                       
                        }).update(registory)
        vhdl_lines = MsgPack_RPC_Interface::VHDL::Module.generate_use(@methods, @variables)
        vhdl_lines.concat(generate_vhdl_body(indent, new_regs))
        return vhdl_lines
      end
  end
  
end
