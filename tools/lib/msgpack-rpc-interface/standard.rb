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
      attr_reader :generator, :registory

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
        @registory = Hash.new
      end

      def generate_vhdl_body_store(indent, registory)
        new_regs = @registory.dup.update(registory).delete_if{|key,val| val == nil}
        return @generator::Store.generate_body(indent, @name, @type, @kvmap, new_regs)
      end

      def generate_vhdl_body_query(indent, registory)
        new_regs = @registory.dup.update(registory).delete_if{|key,val| val == nil}
        return @generator::Query.generate_body(indent, @name, @type, @kvmap, new_regs)
      end

      def generate_vhdl_port_list(master)
        return Set.new(@generator.generate_port_list(master, @type, @kvmap, @registory)).to_a
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
        return "#{self.class.name}: {name: #{@name}, full_name: #{@full_name}, class: #{@msg_class.to_s}, type: #{@type.to_s}, kvmap: #{kvmap}, read: #{@read}, write: #{@write}}, regisotry: #{@registory}"
      end

    end

    class  Register < Base

      def initialize(registory)
        super(registory)
        if    @read == true  and @write == true  then
          @registory[:read_value ] = @port_name + "_rdata"
          @registory[:write_value] = @port_name + "_wdata"
          @registory[:write_valid] = @port_name + "_we"
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:read_value ] = port_regs.fetch("rdata", @registory[:read_value ])
            @registory[:write_value] = port_regs.fetch("wdata", @registory[:write_value])
            @registory[:write_valid] = port_regs.fetch("we"   , @registory[:write_valid])
          end
        elsif @read == true  and @write == false then
          @registory[:read_value ] = @port_name
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:read_value ] = port_regs.fetch("data" , @registory[:read_value ])
            @registory[:read_value ] = port_regs.fetch("rdata", @registory[:read_value ])
          end
        elsif @read == false and @write == true  then
          @registory[:write_value] = @port_name
          @registory[:write_valid] = @port_name + "_we"
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:write_value] = port_regs.fetch("data" , @registory[:write_value])
            @registory[:write_value] = port_regs.fetch("wdata", @registory[:write_value])
            @registory[:write_valid] = port_regs.fetch("we"   , @registory[:write_valid])
          end
        end
        @registory.delete_if{|key,val| val == nil}
        @generator = MsgPack_RPC_Interface::VHDL::Register.const_get(@msg_class.class.to_s.split('::').last)
        puts to_s if @debug
      end
      
    end

    class  Signal   < Base

      def initialize(registory)
        super(registory)
        if    @read == true  and @write == true  then
          @registory[:read_value ] = @port_name + "_rdata"
          @registory[:write_value] = @port_name + "_wdata"
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:read_value ] = port_regs.fetch("rdata", @registory[:read_value ])
            @registory[:write_value] = port_regs.fetch("wdata", @registory[:write_value])
          end
        elsif @read == true  and @write == false then
          @registory[:read_value ] = @port_name
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:read_value ] = port_regs.fetch("data" , @registory[:read_value ])
            @registory[:read_value ] = port_regs.fetch("rdata", @registory[:read_value ])
          end
        elsif @read == false and @write == true  then
          @registory[:write_value] = @port_name
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:write_value] = port_regs.fetch("data" , @registory[:write_value])
            @registory[:write_value] = port_regs.fetch("wdata", @registory[:write_value])
          end
        end
        @registory.delete_if{|key,val| val == nil}
        @generator = MsgPack_RPC_Interface::VHDL::Signal.const_get(@msg_class.class.to_s.split('::').last)
        puts to_s if @debug
      end

    end

    class  Memory   < Base

      attr_reader :arbitor
      
      def initialize(registory)
        super(registory)
        if  registory.key?("size") then
          @registory[:size     ] = registory["size"]
          @registory[:addr_type] = Type.new(registory.fetch("addr_type", Hash({"name" => "Logic_Vector", "width" => Math::log2(@registory[:size]).ceil})))
        else
          @registory[:addr_type] = Type.new(registory.fetch("addr_type", Hash({"name" => "Logic_Vector", "width" => 32})))
          @registory[:size     ] = 2**(@registory[:addr_type].width)
        end
        @registory[:width] = registory.fetch("width", 1)
        if    @read == true  and @write == true  then
          @registory[:read_addr  ] = @port_name + "_raddr"
          @registory[:read_data  ] = @port_name + "_rdata"
          @registory[:write_addr ] = @port_name + "_waddr"
          @registory[:write_data ] = @port_name + "_wdata"
          @registory[:write_valid] = @port_name + "_we"
          @registory[:write_strb ] = @port_name + "_strb"
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:read_addr  ] = port_regs.fetch("raddr", @registory[:read_addr  ])
            @registory[:read_data  ] = port_regs.fetch("rdata", @registory[:read_data  ])
            @registory[:write_addr ] = port_regs.fetch("waddr", @registory[:write_addr ])
            @registory[:write_data ] = port_regs.fetch("wdata", @registory[:write_data ])
            @registory[:write_valid] = port_regs.fetch("we"   , @registory[:write_valid])
            @registory[:write_strb ] = port_regs.fetch("wstrb", @registory[:write_strb ])
            @registory[:read_addr  ] = port_regs.fetch("addr" , @registory[:read_addr  ])
            @registory[:write_addr ] = port_regs.fetch("addr" , @registory[:write_addr ])
          end
        elsif @read == true  and @write == false then
          @registory[:read_addr  ] = @port_name + "_addr"
          @registory[:read_data  ] = @port_name + "_data"
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:read_addr  ] = port_regs.fetch("addr" , @registory[:read_addr ])
            @registory[:read_data  ] = port_regs.fetch("data" , @registory[:read_data ])
          end
        elsif @read == false and @write == true  then
          @registory[:write_addr ] = @port_name + "_addr"
          @registory[:write_data ] = @port_name + "_data"
          @registory[:write_valid] = @port_name + "_we"
          @registory[:write_strb ] = @port_name + "_strb"
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:write_addr ] = port_regs.fetch("addr" , @registory[:write_addr ])
            @registory[:write_data ] = port_regs.fetch("data" , @registory[:write_data ])
            @registory[:write_valid] = port_regs.fetch("we"   , @registory[:write_valid])
            @registory[:write_strb ] = port_regs.fetch("strb" , @registory[:write_strb ])
          end
        end 
        @generator = MsgPack_RPC_Interface::VHDL::Memory.const_get(@msg_class.class.to_s.split('::').last)
        if @port_raddr == @port_waddr then
          arb_regs = Hash.new
          arb_regs[:name       ] = @port_name
          arb_regs[:addr       ] = @registory[:read_addr]
          arb_regs[:addr_type  ] = @registory[:addr_type]
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
        @registory.delete_if{|key,val| val == nil}
      end

      def generate_vhdl_body_store(indent, registory)
        new_regs = registory.dup
        if @arbitor != nil then
          new_regs[:write_addr ] = @arbitor.registory[:write_addr ]
          new_regs[:write_ready] = @arbitor.registory[:write_ready]
          new_regs[:write_start] = @arbitor.registory[:write_start]
          new_regs[:write_busy ] = @arbitor.registory[:write_busy ]
        else
          new_regs[:write_ready] = "'1'"
        end
        return super(indent, new_regs)
      end

      def generate_vhdl_body_query(indent, registory)
        new_regs = registory.dup
        if @arbitor != nil then
          new_regs[:read_addr  ] = @arbitor.registory[:read_addr  ]
          new_regs[:read_valid ] = @arbitor.registory[:read_valid ]
          new_regs[:read_start ] = @arbitor.registory[:read_start ]
          new_regs[:read_busy  ] = @arbitor.registory[:read_busy  ]
        else
          new_regs[:read_valid ] =  "'1'"
        end
        return super(indent, new_regs)
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

    class  Stream   < Base

      attr_reader :generator, :registory

      def initialize(registory)
        super(registory)
        @registory = Hash.new
        @registory[:max_size] = registory.fetch("max_size", 4096)
        @registory[:width   ] = registory.fetch("width"   , 1   )
        if    @read == true  and @write == true  then
          @registory[:write_start] = nil
          @registory[:write_busy ] = nil
          @registory[:write_data ] = @port_name + "_wdata"
          @registory[:write_strb ] = @port_name + "_wstrb"  
          @registory[:write_last ] = @port_name + "_wlast"  
          @registory[:write_valid] = @port_name + "_wvalid" 
          @registory[:write_ready] = @port_name + "_wready" 
          @registory[:read_start ] = nil
          @registory[:read_busy  ] = nil
          @registory[:read_data  ] = @port_name + "_rdata"
          @registory[:read_strb  ] = @port_name + "_rstrb"  
          @registory[:read_last  ] = @port_name + "_rlast"  
          @registory[:read_valid ] = @port_name + "_rvalid" 
          @registory[:read_ready ] = @port_name + "_rready" 
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:write_start] = port_regs.fetch("wstart", @registory[:write_start])
            @registory[:write_busy ] = port_regs.fetch("wbusy" , @registory[:write_busy ])
            @registory[:write_data ] = port_regs.fetch("wdata" , @registory[:write_data ])
            @registory[:write_strb ] = port_regs.fetch("wstrb" , @registory[:write_strb ])
            @registory[:write_last ] = port_regs.fetch("wlast" , @registory[:write_last ])
            @registory[:write_valid] = port_regs.fetch("wvalid", @registory[:write_valid])
            @registory[:write_ready] = port_regs.fetch("wready", @registory[:write_ready])
            @registory[:read_start ] = port_regs.fetch("rstart", @registory[:read_start ])
            @registory[:read_busy  ] = port_regs.fetch("rbusy" , @registory[:read_busy  ])
            @registory[:read_data  ] = port_regs.fetch("rdata" , @registory[:read_data  ])
            @registory[:read_strb  ] = port_regs.fetch("rstrb" , @registory[:read_strb  ])
            @registory[:read_last  ] = port_regs.fetch("rlast" , @registory[:read_last  ])
            @registory[:read_valid ] = port_regs.fetch("rvalid", @registory[:read_valid ])
            @registory[:read_ready ] = port_regs.fetch("rready", @registory[:read_ready ])
          end
        elsif @read == true  and @write == false then
          @registory[:read_start ] = nil
          @registory[:read_busy  ] = nil
          @registory[:read_data  ] = @port_name + "_data"
          @registory[:read_strb  ] = @port_name + "_strb"  
          @registory[:read_last  ] = @port_name + "_last"  
          @registory[:read_valid ] = @port_name + "_valid" 
          @registory[:read_ready ] = @port_name + "_ready" 
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:read_start ] = port_regs.fetch("start", @registory[:read_start ])
            @registory[:read_busy  ] = port_regs.fetch("busy" , @registory[:read_busy  ])
            @registory[:read_data  ] = port_regs.fetch("data" , @registory[:read_data  ])
            @registory[:read_strb  ] = port_regs.fetch("strb" , @registory[:read_strb  ])
            @registory[:read_last  ] = port_regs.fetch("last" , @registory[:read_last  ])
            @registory[:read_valid ] = port_regs.fetch("valid", @registory[:read_valid ])
            @registory[:read_ready ] = port_regs.fetch("ready", @registory[:read_ready ])
          end
        elsif @read == false and @write == true  then
          @registory[:write_start] = nil
          @registory[:write_busy ] = nil
          @registory[:write_data ] = @port_name + "_data"
          @registory[:write_strb ] = @port_name + "_strb"  
          @registory[:write_last ] = @port_name + "_last"  
          @registory[:write_valid] = @port_name + "_valid" 
          @registory[:write_ready] = @port_name + "_ready" 
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:write_start] = port_regs.fetch("start", @registory[:write_start])
            @registory[:write_busy ] = port_regs.fetch("busy" , @registory[:write_busy ])
            @registory[:write_data ] = port_regs.fetch("data" , @registory[:write_data ])
            @registory[:write_strb ] = port_regs.fetch("strb" , @registory[:write_strb ])
            @registory[:write_last ] = port_regs.fetch("last" , @registory[:write_last ])
            @registory[:write_valid] = port_regs.fetch("valid", @registory[:write_valid])
            @registory[:write_ready] = port_regs.fetch("ready", @registory[:write_ready])
          end
        else
        end
        @registory.delete_if{|key,val| val == nil}
        @generator = MsgPack_RPC_Interface::VHDL::Stream.const_get(@msg_class.class.to_s.split('::').last)
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
