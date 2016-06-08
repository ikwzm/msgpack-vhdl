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
      attr_reader :name, :msg_class, :type, :read, :write, :kvmap, :full_name, :port_name, :blocks

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
        @blocks    = []
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

      attr_reader :generator, :port_rdata, :port_wdata, :port_we, :port_wstrb, :port_waddr, :port_raddr, :addr_type, :size, :width, :arbitor
      
      def initialize(registory)
        super(registory)
        if  registory.key?("size") then
          @size = registory["size"]
          @addr_type = Type.new(registory.fetch("addr_type", Hash({"name" => "Logic_Vector", "width" => Math::log2(@size).ceil})))
        else
          @addr_type = Type.new(registory.fetch("addr_type", Hash({"name" => "Logic_Vector", "width" => 32})))
          @size      = 2**@addr_type.width
        end
        @width     = registory.fetch("width", 1)
        if    @read == true  and @write == true  then
          @port_raddr = @port_name + "_raddr"
          @port_rdata = @port_name + "_rdata"
          @port_waddr = @port_name + "_waddr"
          @port_wdata = @port_name + "_wdata"
          @port_we    = @port_name + "_we"
          @port_wstrb = @port_name + "_strb"
          if registory.key?("port") then
            port_regs = registory["port"]
            @port_raddr = port_regs.fetch("raddr", @port_raddr)
            @port_rdata = port_regs.fetch("rdata", @port_rdata)
            @port_waddr = port_regs.fetch("waddr", @port_waddr)
            @port_wdata = port_regs.fetch("wdata", @port_wdata)
            @port_we    = port_regs.fetch("we"   , @port_we   )
            @port_wstrb = port_regs.fetch("wstrb", @port_wstrb)
            @port_raddr = port_regs.fetch("addr" , @port_raddr)
            @port_waddr = port_regs.fetch("addr" , @port_waddr)
          end
        elsif @read == true  and @write == false then
          @port_raddr = @port_name + "_addr"
          @port_rdata = @port_name + "_data"
          @port_waddr = nil
          @port_wdata = nil
          @port_we    = nil
          @port_wstrb = nil
          if registory.key?("port") then
            port_regs = registory["port"]
            @port_raddr = port_regs.fetch("addr", @port_raddr)
            @port_rdata = port_regs.fetch("data", @port_rdata)
          end
        elsif @read == false and @write == true  then
          @port_raddr = nil
          @port_rdata = nil
          @port_waddr = @port_name + "_addr"
          @port_wdata = @port_name + "_data"
          @port_we    = @port_name + "_we"
          @port_wstrb = @port_name + "_wstrb"
          if registory.key?("port") then
            port_regs = registory["port"]
            @port_waddr = port_regs.fetch("addr" , @port_waddr)
            @port_wdata = port_regs.fetch("data" , @port_wdata)
            @port_we    = port_regs.fetch("we"   , @port_we   )
            @port_wstrb = port_regs.fetch("we"   , @port_wstrb)
          end
        else
          @port_raddr = nil
          @port_rdata = nil
          @port_waddr = nil
          @port_wdata = nil
          @port_we    = nil
          @port_wstrb = nil
        end 
        @generator = MsgPack_RPC_Interface::VHDL::Memory.const_get(@msg_class.class.to_s.split('::').last)
        if @port_raddr == @port_waddr then
          arb_regs = Hash.new
          arb_regs[:name       ] = @port_name
          arb_regs[:addr       ] = @port_raddr
          arb_regs[:addr_type  ] = @addr_type
          arb_regs[:write_addr ] = "proc_#{@port_name}_waddr"
          arb_regs[:write_ready] = "proc_#{@port_name}_wready"
          arb_regs[:write_start] = "proc_#{@port_name}_wstart"
          arb_regs[:write_busy ] = "proc_#{@port_name}_wbusy"
          arb_regs[:read_addr  ] = "proc_#{@port_name}_raddr"
          arb_regs[:read_valid ] = "proc_#{@port_name}_rvalid"
          arb_regs[:read_start ] = "proc_#{@port_name}_rstart"
          arb_regs[:read_busy  ] = "proc_#{@port_name}_rbusy"
          @arbitor = Arbitor.new(arb_regs)
          @blocks << @arbitor
        end        
      end
      
      def generate_vhdl_body_store(indent, registory)
        new_regs = registory.dup
        new_regs[:size       ] = @size
        new_regs[:width      ] = @width
        new_regs[:write_data ] = registory.fetch(:write_data, @port_wdata)
        new_regs[:write_strb ] = registory.fetch(:write_strb, @port_wstrb)
        new_regs[:write_valid] = registory.fetch(:write_ena , @port_we   )
        if @port_raddr == @port_waddr then
          new_regs[:write_addr ] = @arbitor.registory[:write_addr ]
          new_regs[:write_ready] = @arbitor.registory[:write_ready]
          new_regs[:write_start] = @arbitor.registory[:write_start]
          new_regs[:write_busy ] = @arbitor.registory[:write_busy ]
        else
          new_regs[:write_addr ] = registory.fetch(:write_addr, @port_waddr)
          new_regs[:write_ready] = "'1'"
        end
        return @generator::Store.generate_body(indent, @name, @type, @addr_type, @kvmap, new_regs)
      end

      def generate_vhdl_body_query(indent, registory)
        new_regs = registory.dup
        new_regs[:size      ] = @size
        new_regs[:width     ] = @width
        new_regs[:read_data ] = registory.fetch(:read_data , @port_rdata)
        if @port_raddr == @port_waddr then
          new_regs[:read_addr ] = @arbitor.registory[:read_addr ]
          new_regs[:read_valid] = @arbitor.registory[:read_valid]
          new_regs[:read_start] = @arbitor.registory[:read_start]
          new_regs[:read_busy ] = @arbitor.registory[:read_busy ]
        else
          new_regs[:read_addr ] = registory.fetch(:read_addr , @port_raddr)
          new_regs[:read_valid] =  "'1'"
        end
        return @generator::Query.generate_body(indent, @name, @type, @addr_type, @kvmap, new_regs)
      end

      def generate_vhdl_port_list(master)
        registory  = Hash.new
        registory[:size       ] = @size
        registory[:width      ] = @width
        registory[:write_addr ] = @port_waddr if @write == true
        registory[:write_data ] = @port_wdata if @write == true
        registory[:write_ena  ] = @port_we    if @write == true
        registory[:write_strb ] = @port_wstrb if @write == true
        registory[:read_addr  ] = @port_raddr if @read  == true
        registory[:read_data  ] = @port_rdata if @read  == true
        return Set.new(@generator.generate_port_list(master, @type, @addr_type, @kvmap, registory)).to_a
      end

      def use_package_list
        use_list   = Array.new
        if @read then
          use_list.concat(@generator::Query.use_package_list(@kvmap))
        end
        if @write then
          use_list.concat(@generator::Store.use_package_list(@kvmap))
        end
        return use_list
      end

      class Arbitor
        attr_reader :name, :registory
        def initialize(registory)
          @name      = registory[:name]
          @registory = registory
        end
        def generate_vhdl_decl(indent, registory)
          new_regs = @registory.dup
          new_regs[:clock] = registory[:clock]
          new_regs[:reset] = registory[:reset]
          new_regs[:clear] = registory[:clear]
          return MsgPack_RPC_Interface::VHDL::Memory::Arbitor.generate_decl(indent, @name, new_regs)
        end
        def generate_vhdl_stmt(indent, registory)
          new_regs = @registory.dup
          new_regs[:clock] = registory[:clock]
          new_regs[:reset] = registory[:reset]
          new_regs[:clear] = registory[:clear]
          return MsgPack_RPC_Interface::VHDL::Memory::Arbitor.generate_stmt(indent, @name, new_regs)
        end
      end

    end
  end

  module Type

    def new(registory)
      if registory.class == Hash then
        name = registory["name"]
      else
        name = registory
        registory = {"name" => name}
      end

      if self.const_defined?(name) then
        return self.const_get(name).new(registory)
      else
        abort "Undefined Type::#{name}"
      end
    end

    module_function :new

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
        super(registory)
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
        super(registory)
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
        super(registory)
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
        super(registory)
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
        super(registory)
        @width = registory.fetch("width", nil)
      end
      def generate_vhdl_type
        return "std_logic_vector(#{@width}-1 downto 0)"
      end
    end

    class Binary < Base
      attr_reader :width
      def initialize(registory)
        super(registory)
        @width = registory.fetch("width", nil)
      end
      def generate_vhdl_type
        return "std_logic_vector(8*#{@width}-1 downto 0)"
      end
    end
    
    class String < Base
      attr_reader :width
      def initialize(registory)
        super(registory)
        @width = registory.fetch("width", nil)
      end
      def generate_vhdl_type
        return "std_logic_vector(8*#{@width}-1 downto 0)"
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

      attr_reader :name, :full_name, :arguments, :return, :req_name, :busy_name, :return_name, :blocks

      def initialize(registory)
        @debug       = registory.fetch("debug", false)
        @name        = registory["name"]
        @full_name   = registory["full_name"]
        @arguments   = registory["arguments"]
        @return      = registory["return"]
        @req_name    = @full_name.join("_") + "_REQ"
        @busy_name   = @full_name.join("_") + "_BUSY"
        @return_name = (@return != nil) ? (@full_name.join("_") + "_" + @return.name) : nil
        @blocks      = []
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

      attr_reader :name, :full_name, :variables, :blocks

      def initialize(registory)
        @debug     = registory.fetch("debug", false)
        @name      = registory["name"]
        @full_name = registory["full_name"]
        @variables = registory["variables"]
        @blocks    = []
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

      attr_reader :name, :full_name, :variables, :blocks

      def initialize(registory)
        @debug     = registory.fetch("debug", false)
        @name      = registory["name"]
        @full_name = registory["full_name"]
        @variables = registory["variables"]
        @blocks    = []
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
        return MsgPack_RPC_Interface::VHDL::Module.generate_body(indent, name, @methods, @variables, new_regs)
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
