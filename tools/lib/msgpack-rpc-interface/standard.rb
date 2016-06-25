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

      def registory_to_s(indent)
        list = Array.new
        @registory.each_pair do |k,v|
          list << indent + sprintf("%-16s : %s" , k.to_s , v.to_s)
        end
        return list.join("\n")
      end

      def to_s(indent)
        return [indent + sprintf("%-10s : %s" , "name"      , @name          ),
                indent + sprintf("%-10s : %s" , "class"     , self.class.name),
                indent + sprintf("%-10s : %s" , "port_name" , @port_name     ),
                indent + sprintf("%-10s : %s" , "full_name" , @full_name     ),
                indent + sprintf("%-10s : %s" , "class"     , @msg_class.to_s),
                indent + sprintf("%-10s : %s" , "type"      , @type.to_s     ),
                indent + sprintf("%-10s : %s" , "kvmap"     , @kvmap         ),
                indent + sprintf("%-10s : %s" , "read"      , @read          ),
                indent + sprintf("%-10s : %s" , "write"     , @write         ),
                indent + sprintf("%-10s : %s" , "generator" , @generator     ),
                indent + sprintf("%-10s : "   , "regisotry"                  ),
               ].join("\n") + "\n" + registory_to_s(indent + "  ")
      end

    end

    class  Register < Base

      def initialize(registory)
        super(registory)
        if    @read == true  and @write == true  then
          @registory[:query_data ] = @port_name + "_rdata"
          @registory[:store_data ] = @port_name + "_wdata"
          @registory[:store_valid] = @port_name + "_we"
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:query_data ] = port_regs.fetch("rdata", @registory[:query_data ])
            @registory[:store_data ] = port_regs.fetch("wdata", @registory[:store_data ])
            @registory[:store_valid] = port_regs.fetch("we"   , @registory[:store_valid])
          end
        elsif @read == true  and @write == false then
          @registory[:query_data ] = @port_name
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:query_data ] = port_regs.fetch("data" , @registory[:query_data ])
            @registory[:query_data ] = port_regs.fetch("rdata", @registory[:query_data ])
          end
        elsif @read == false and @write == true  then
          @registory[:store_data ] = @port_name
          @registory[:store_valid] = @port_name + "_we"
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:store_data ] = port_regs.fetch("data" , @registory[:store_data ])
            @registory[:store_data ] = port_regs.fetch("wdata", @registory[:store_data ])
            @registory[:store_valid] = port_regs.fetch("we"   , @registory[:store_valid])
          end
        end
        @registory[:width] = 1
        @registory.delete_if{|key,val| val == nil}
        @generator = MsgPack_RPC_Interface::VHDL::Register.const_get(@msg_class.class.to_s.split('::').last)
        puts to_s("") if @debug
      end
      
    end

    class  Signal   < Base

      def initialize(registory)
        super(registory)
        if    @read == true  and @write == true  then
          @registory[:query_data] = @port_name + "_rdata"
          @registory[:store_data] = @port_name + "_wdata"
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:query_data] = port_regs.fetch("rdata", @registory[:query_data])
            @registory[:store_data] = port_regs.fetch("wdata", @registory[:store_data])
          end
        elsif @read == true  and @write == false then
          @registory[:query_data ] = @port_name
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:query_data] = port_regs.fetch("data" , @registory[:query_data])
            @registory[:query_data] = port_regs.fetch("rdata", @registory[:query_data])
          end
        elsif @read == false and @write == true  then
          @registory[:store_data] = @port_name
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:store_data] = port_regs.fetch("data" , @registory[:store_data])
            @registory[:store_data] = port_regs.fetch("wdata", @registory[:store_data])
          end
        end
        @registory[:width] = 1
        @registory.delete_if{|key,val| val == nil}
        @generator = MsgPack_RPC_Interface::VHDL::Signal.const_get(@msg_class.class.to_s.split('::').last)
        puts to_s("") if @debug
      end

    end

    class  Memory   < Base

      attr_reader :arbitor
      
      def initialize(registory)
        super(registory)
        if    registory.key?("size") then
          @registory[:size     ] = registory["size"]
          @registory[:addr_type] = Type.new(registory.fetch("addr_type", Hash({"name" => "Logic_Vector", "width" => Math::log2(@registory[:size]).ceil})))
          @registory[:size_type] = Type.new(registory.fetch("size_type", Hash({"name" => "Logic_Vector", "width" => Math::log2(@registory[:size]).ceil+1})))
        elsif registory.key?("size_type") then
          @registory[:size_type] = Type.new(registory["size_type"])
          @registory[:addr_type] = Type.new(registory.fetch("addr_type", Hash({"name" => "Logic_Vector", "width" => @registory[:size_type].bits-1})))
          @registory[:size     ] = 2**(@registory[:size_type].bits-1)
        elsif registory.key?("addr_type") then
          @registory[:addr_type] = Type.new(registory["addr_type"])
          @registory[:size_type] = Type.new(Hash({"name" => "Logic_Vector", "width" => @registory[:addr_type].bits+1}))
          @registory[:size     ] = 2**(@registory[:addr_type].bits)
        else
          @registory[:addr_type] = Type.new(Hash({"name" => "Logic_Vector", "width" => 32}))
          @registory[:size_type] = Type.new(Hash({"name" => "Logic_Vector", "width" => 32}))
          @registory[:size     ] = 2**(@registory[:size_type].bits-1)
        end
        @registory[:width] = registory.fetch("width", 1)
        if    @read == true  and @write == true  then
          @registory[:query_addr ] = @port_name + "_raddr"
          @registory[:query_data ] = @port_name + "_rdata"
          @registory[:store_addr ] = @port_name + "_waddr"
          @registory[:store_data ] = @port_name + "_wdata"
          @registory[:store_valid] = @port_name + "_we"
          @registory[:store_strb ] = @port_name + "_strb"
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:query_addr  ] = port_regs.fetch("raddr" , @registory[:query_addr  ])
            @registory[:query_data  ] = port_regs.fetch("rdata" , @registory[:query_data  ])
            @registory[:store_addr  ] = port_regs.fetch("waddr" , @registory[:store_addr  ])
            @registory[:store_data  ] = port_regs.fetch("wdata" , @registory[:store_data  ])
            @registory[:store_valid ] = port_regs.fetch("we"    , @registory[:store_valid ])
            @registory[:store_strb  ] = port_regs.fetch("wstrb" , @registory[:store_strb  ])
            @registory[:query_addr  ] = port_regs.fetch("addr"  , @registory[:query_addr  ])
            @registory[:store_addr  ] = port_regs.fetch("addr"  , @registory[:store_addr  ])
            if port_regs.key?("oe") then
              @registory[:query_enable] = port_regs["oe"]
            end
          end
        elsif @read == true  and @write == false then
          @registory[:query_addr ] = @port_name + "_addr"
          @registory[:query_data ] = @port_name + "_data"
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:query_addr ] = port_regs.fetch("addr" , @registory[:query_addr ])
            @registory[:query_data ] = port_regs.fetch("data" , @registory[:query_data ])
            if port_regs.key?("oe") then
              @registory[:query_enable] = port_regs["oe"]
            end
          end
        elsif @read == false and @write == true  then
          @registory[:store_addr ] = @port_name + "_addr"
          @registory[:store_data ] = @port_name + "_data"
          @registory[:store_valid] = @port_name + "_we"
          @registory[:store_strb ] = @port_name + "_strb"
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:store_addr ] = port_regs.fetch("addr" , @registory[:store_addr ])
            @registory[:store_data ] = port_regs.fetch("data" , @registory[:store_data ])
            @registory[:store_valid] = port_regs.fetch("we"   , @registory[:store_valid])
            @registory[:store_strb ] = port_regs.fetch("strb" , @registory[:store_strb ])
          end
        end
        if registory.key?("port") then
          port_regs = registory["port"]
          if port_regs.key?("default_size") 
            @registory[:default_size] = port_regs["default_size"]
          end
        end
        @generator = MsgPack_RPC_Interface::VHDL::Memory.const_get(@msg_class.class.to_s.split('::').last)
        if @registory[:query_addr] == @registory[:store_addr] then
          arb_regs = Hash.new
          arb_regs[:name       ] = @port_name
          arb_regs[:addr       ] = @registory[:query_addr]
          arb_regs[:addr_type  ] = @registory[:addr_type]
          arb_regs[:store_addr ] = "proc_#{@port_name}_waddr"
          arb_regs[:store_valid] = "proc_#{@port_name}_wvalid"
          arb_regs[:store_ready] = "proc_#{@port_name}_wready"
          arb_regs[:store_start] = "proc_#{@port_name}_wstart"
          arb_regs[:store_busy ] = "proc_#{@port_name}_wbusy"
          arb_regs[:query_addr ] = "proc_#{@port_name}_raddr"
          arb_regs[:query_valid] = "proc_#{@port_name}_rvalid"
          arb_regs[:query_ready] = "proc_#{@port_name}_rready"
          arb_regs[:query_start] = "proc_#{@port_name}_rstart"
          arb_regs[:query_busy ] = "proc_#{@port_name}_rbusy"
          arb_regs[:we         ] = @registory[:store_valid]
          if @registory.key?(:query_enable) then
            arb_regs[:oe         ] = @registory[:query_enable]
          end
          @arbitor = Arbitor.new(arb_regs)
          @blocks << @arbitor
        end
        @registory.delete_if{|key,val| val == nil}
        puts to_s("") if @debug
      end

      def generate_vhdl_body_store(indent, registory)
        new_regs = registory.dup
        if @arbitor != nil then
          new_regs[:store_addr ] = @arbitor.registory[:store_addr ]
          new_regs[:store_valid] = @arbitor.registory[:store_valid]
          new_regs[:store_ready] = @arbitor.registory[:store_ready]
          new_regs[:store_start] = @arbitor.registory[:store_start]
          new_regs[:store_busy ] = @arbitor.registory[:store_busy ]
        else
          new_regs[:store_ready] = "'1'"
        end
        return super(indent, new_regs)
      end

      def generate_vhdl_body_query(indent, registory)
        new_regs = registory.dup
        if @arbitor != nil then
          new_regs[:query_addr  ] = @arbitor.registory[:query_addr  ]
          new_regs[:query_valid ] = @arbitor.registory[:query_valid ]
          new_regs[:query_ready ] = @arbitor.registory[:query_ready ]
          new_regs[:query_start ] = @arbitor.registory[:query_start ]
          new_regs[:query_busy  ] = @arbitor.registory[:query_busy  ]
        else
          new_regs[:query_valid ] =  "'1'"
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
        @registory[:width] = registory.fetch("width", 1)
        if registory.key?("max_size") then
          max_size  = registory["max_size"]
          size_bits = Math::log2(max_size+1).ceil
          @registory[:max_size ] = max_size
          @registory[:size     ] = max_size
          @registory[:size_type] = Type.new(registory.fetch("size_type", Hash({"name" => "Logic_Vector", "width" => size_bits})))
        else
          @registory[:size_type] = Type.new(registory.fetch("size_type", Hash({"name" => "Logic_Vector", "width" => 32})))
          @registory[:max_size ] = 2**(@registory[:size_type].bits-1)
          @registory[:size     ] = 2**(@registory[:size_type].bits-1)
        end
        if    @read == true  and @write == true  then
          @registory[:store_start] = nil
          @registory[:store_busy ] = nil
          @registory[:store_size ] = nil
          @registory[:store_data ] = @port_name + "_wdata"
          @registory[:store_strb ] = @port_name + "_wstrb"  
          @registory[:store_last ] = @port_name + "_wlast"  
          @registory[:store_valid] = @port_name + "_wvalid" 
          @registory[:store_ready] = @port_name + "_wready" 
          @registory[:query_start] = nil
          @registory[:query_busy ] = nil
          @registory[:query_size ] = nil
          @registory[:query_dsize] = nil
          @registory[:query_data ] = @port_name + "_rdata"
          @registory[:query_strb ] = @port_name + "_rstrb"  
          @registory[:query_last ] = @port_name + "_rlast"  
          @registory[:query_valid] = @port_name + "_rvalid" 
          @registory[:query_ready] = @port_name + "_rready" 
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:store_start] = port_regs.fetch("wstart", @registory[:store_start])
            @registory[:store_busy ] = port_regs.fetch("wbusy" , @registory[:store_busy ])
            @registory[:store_size ] = port_regs.fetch("wsize" , @registory[:store_size ])
            @registory[:store_data ] = port_regs.fetch("wdata" , @registory[:store_data ])
            @registory[:store_strb ] = port_regs.fetch("wstrb" , @registory[:store_strb ])
            @registory[:store_last ] = port_regs.fetch("wlast" , @registory[:store_last ])
            @registory[:store_valid] = port_regs.fetch("wvalid", @registory[:store_valid])
            @registory[:store_ready] = port_regs.fetch("wready", @registory[:store_ready])
            @registory[:query_start] = port_regs.fetch("rstart", @registory[:query_start ])
            @registory[:query_busy ] = port_regs.fetch("rbusy" , @registory[:query_busy  ])
            @registory[:query_size ] = port_regs.fetch("rsize" , @registory[:query_size  ])
            @registory[:query_dsize] = port_regs.fetch("rdsize", @registory[:query_dsize ])
            @registory[:query_data ] = port_regs.fetch("rdata" , @registory[:query_data  ])
            @registory[:query_strb ] = port_regs.fetch("rstrb" , @registory[:query_strb  ])
            @registory[:query_last ] = port_regs.fetch("rlast" , @registory[:query_last  ])
            @registory[:query_valid] = port_regs.fetch("rvalid", @registory[:query_valid ])
            @registory[:query_ready] = port_regs.fetch("rready", @registory[:query_ready ])
          end
        elsif @read == true  and @write == false then
          @registory[:query_start] = nil
          @registory[:query_busy ] = nil
          @registory[:query_size ] = nil
          @registory[:query_dsize] = nil
          @registory[:query_data ] = @port_name + "_data"
          @registory[:query_strb ] = @port_name + "_strb"  
          @registory[:query_last ] = @port_name + "_last"  
          @registory[:query_valid] = @port_name + "_valid" 
          @registory[:query_ready] = @port_name + "_ready" 
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:query_start] = port_regs.fetch("start", @registory[:query_start ])
            @registory[:query_busy ] = port_regs.fetch("busy" , @registory[:query_busy  ])
            @registory[:query_size ] = port_regs.fetch("size" , @registory[:query_size  ])
            @registory[:query_dsize] = port_regs.fetch("dsize", @registory[:query_dsize ])
            @registory[:query_data ] = port_regs.fetch("data" , @registory[:query_data  ])
            @registory[:query_strb ] = port_regs.fetch("strb" , @registory[:query_strb  ])
            @registory[:query_last ] = port_regs.fetch("last" , @registory[:query_last  ])
            @registory[:query_valid] = port_regs.fetch("valid", @registory[:query_valid ])
            @registory[:query_ready] = port_regs.fetch("ready", @registory[:query_ready ])
          end
        elsif @read == false and @write == true  then
          @registory[:store_start] = nil
          @registory[:store_busy ] = nil
          @registory[:store_size ] = nil
          @registory[:store_data ] = @port_name + "_data"
          @registory[:store_strb ] = @port_name + "_strb"  
          @registory[:store_last ] = @port_name + "_last"  
          @registory[:store_valid] = @port_name + "_valid" 
          @registory[:store_ready] = @port_name + "_ready" 
          if registory.key?("port") then
            port_regs = registory["port"]
            @registory[:store_start] = port_regs.fetch("start", @registory[:store_start])
            @registory[:store_busy ] = port_regs.fetch("busy" , @registory[:store_busy ])
            @registory[:store_size ] = port_regs.fetch("size" , @registory[:store_size ])
            @registory[:store_data ] = port_regs.fetch("data" , @registory[:store_data ])
            @registory[:store_strb ] = port_regs.fetch("strb" , @registory[:store_strb ])
            @registory[:store_last ] = port_regs.fetch("last" , @registory[:store_last ])
            @registory[:store_valid] = port_regs.fetch("valid", @registory[:store_valid])
            @registory[:store_ready] = port_regs.fetch("ready", @registory[:store_ready])
          end
        else
        end
        @registory.delete_if{|key,val| val == nil}
        @generator = MsgPack_RPC_Interface::VHDL::Stream.const_get(@msg_class.class.to_s.split('::').last)
        puts to_s("") if @debug
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
      attr_reader :bits
      def to_s
        return "#{self.class.name}"
      end
      def initialize(registory)
      end
    end

    class Integer < Base
      include MsgPack_RPC_Interface::VHDL::Type::Std_Logic_Vector
      attr_reader :sign
      def initialize(registory)
        super(registory)
        @bits = registory.fetch("width", 32  )
        @sign = registory.fetch("sign" , true)
      end
    end

    class Unsigned < Base
      include MsgPack_RPC_Interface::VHDL::Type::Unsigned
      attr_reader :sign
      def initialize(registory)
        super(registory)
        @bits = registory.fetch("width", 32  )
        @sign = false
      end
      def to_s
        return "#{self.class.name}(#{@bits})"
      end
    end

    class Signed < Base
      include MsgPack_RPC_Interface::VHDL::Type::Signed
      attr_reader :sign
      def initialize(registory)
        super(registory)
        @bits = registory.fetch("width", 32  )
        @sign = true
      end
      def to_s
        return "#{self.class.name}(#{@bits})"
      end
    end

    class Logic   < Base
      include MsgPack_RPC_Interface::VHDL::Type::Std_Logic
      def initialize(registory)
        super(registory)
        @bits = 1
      end
    end

    class Logic_Vector < Base
      include MsgPack_RPC_Interface::VHDL::Type::Std_Logic_Vector
      def initialize(registory)
        super(registory)
        @bits = registory.fetch("width", 1)
      end
      def to_s
        return "#{self.class.name}(#{@bits})"
      end
    end

    class Binary < Base
      include MsgPack_RPC_Interface::VHDL::Type::Std_Logic_Vector
      def initialize(registory)
        super(registory)
        @bits = 8
      end
    end
    
    class String < Base
      include MsgPack_RPC_Interface::VHDL::Type::Std_Logic_Vector
      def initialize(registory)
        super(registory)
        @bits = 8
      end
    end
    
    class Boolean < Base
      include MsgPack_RPC_Interface::VHDL::Type::Boolean
      def initialize(registory)
        @bits = 1
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
        @return_name = (@return != nil) ? (@return.interface.port_name) : nil
        @blocks      = []
        if registory.key?("port") then
          @req_name    = registory["port"].fetch("request", @req_name   )
          @busy_name   = registory["port"].fetch("busy"   , @busy_name  )
          @return_name = registory["port"].fetch("return" , @return_name)
        end
        puts to_s("") if @debug
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

      def to_s(indent)
        return [indent + sprintf("%-10s : %s" , "name"       , @name          ),
                indent + sprintf("%-10s : %s" , "class"      , self.class.name),
                indent + sprintf("%-10s : %s" , "port_name"  , @port_name     ),
                indent + sprintf("%-10s : %s" , "full_name"  , @full_name     ),
                indent + sprintf("%-10s : %s" , "req_name"   , @req_name      ),
                indent + sprintf("%-10s : %s" , "busy_name"  , @busy_name     ),
                indent + sprintf("%-10s : %s" , "return_name", @return_name   ),
                indent + sprintf("%-10s : \n" , "arguments"                   ),
               ].join("\n") +
               @arguments.map{|argument| argument.to_s(indent + "  ")}.join("\n") + "\n" +
               [indent + sprintf("%-10s : \n" , "return"                     ),
               ].join("\n") +
               ((@return != nil) ? @return.to_s(indent + "  ") : "")
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
        puts to_s("") if @debug
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

      def to_s(indent)
        return [indent + sprintf("%-10s : %s" , "name"       , @name          ),
                indent + sprintf("%-10s : %s" , "class"      , self.class.name),
                indent + sprintf("%-10s : %s" , "full_name"  , @full_name     ),
                indent + sprintf("%-10s : \n" , "variables"                   ),
               ].join("\n") + @variables.map{|v| v.to_s(indent + "  ")}.join("\n")
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
        puts to_s("") if @debug
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

      def to_s(indent)
        return [indent + sprintf("%-10s : %s" , "name"       , @name          ),
                indent + sprintf("%-10s : %s" , "class"      , self.class.name),
                indent + sprintf("%-10s : %s" , "full_name"  , @full_name     ),
               ].join("\n") + @variables.map{|v| v.to_s(indent + "  ")}.join("\n")
      end
    end
  end

  class Module::Interface
      attr_reader :name, :full_name, :methods, :variables, :port_regs

      DEFAULT_INTERFACE_REGISTORY = Hash({
        code_width:       CODE_WIDTH  ,
        match_phase:      MATCH_PHASE ,
        clock:            "CLK"       ,
        reset:            "RST"       ,
        clear:            "CLR"       ,
        intake_bytes:     "I_BYTES"   ,
        intake_data:      "I_DATA"    ,
        intake_strb:      "I_STRB"    ,
        intake_last:      "I_LAST"    ,
        intake_valid:     "I_VALID"   ,
        intake_ready:     "I_READY"   ,
        outlet_bytes:     "O_BYTES"   ,
        outlet_data:      "O_DATA"    ,
        outlet_strb:      "O_STRB"    ,
        outlet_last:      "O_LAST"    ,
        outlet_valid:     "O_VALID"   ,
        outlet_ready:     "O_READY"   ,
      })

      DEFAULT_SERVER_REGISTORY = Hash({
        clock:            "CLK"       ,
        reset_n:          "ARESETn"   ,
        clear:            "'0'"       ,
        intake_bytes:     "I_BYTES"   ,
        intake_data:      "I_TDATA"   ,
        intake_strb:      "I_TKEEP"   ,
        intake_last:      "I_TLAST"   ,
        intake_valid:     "I_TVALID"  ,
        intake_ready:     "I_TREADY"  ,
        outlet_bytes:     "O_BYTES"   ,
        outlet_data:      "O_TDATA"   ,
        outlet_strb:      "O_TKEEP"   ,
        outlet_last:      "O_TLAST"   ,
        outlet_valid:     "O_TVALID"  ,
        outlet_ready:     "O_TREADY"  ,
        internal_reset:   "reset"     ,
        internal_reset_n: "reset_n"   ,
      })

      DEFAULT_MODULE_REGISTORY = Hash({
        clock:            "CLK"       ,
        reset:            "RST"       ,
        clear:            "CLR"       ,
      })

      def initialize(registory)
        @debug     = registory.fetch("debug", false)
        @name      = registory["name"]
        @full_name = registory["full_name"]
        @methods   = registory["methods"]
        @variables = registory["variables"]
        @port_regs = DEFAULT_MODULE_REGISTORY.dup
        @port_regs[:clock  ] = registory["port"]["clock"  ] if registory["port"].key?("clock"  )
        @port_regs[:reset  ] = registory["port"]["reset"  ] if registory["port"].key?("reset"  )
        @port_regs[:reset_n] = registory["port"]["reset_n"] if registory["port"].key?("reset_n")
        @port_regs[:clear  ] = registory["port"]["clear"  ] if registory["port"].key?("clear"  )
      end

      def generate_vhdl_entity(indent, interface_registory)
        name = interface_registory.fetch(:name , @name)
        if_regs = DEFAULT_INTERFACE_REGISTORY.dup
        if_regs[:name] = name
        if_regs.update(interface_registory)
        return MsgPack_RPC_Interface::VHDL::Interface.generate_entity(indent, name, self, if_regs)
      end

      def generate_vhdl_component(indent, interface_registory)
        name = interface_registory.fetch(:name , @name)
        if_regs = DEFAULT_INTERFACE_REGISTORY.dup
        if_regs[:name] = name
        if_regs.update(interface_registory)
        return MsgPack_RPC_Interface::VHDL::Interface.generate_component(indent, name, self, if_regs)
      end
      
      def generate_vhdl_body(indent, interface_registory)
        name = interface_registory.fetch(:name , @name)
        if_regs = DEFAULT_INTERFACE_REGISTORY.dup
        if_regs[:name] = name
        if_regs.update(interface_registory)
        return MsgPack_RPC_Interface::VHDL::Interface.generate_body(indent, name, self, if_regs)
      end

      def generate_vhdl_architecture(indent, interface_registory)
        name = interface_registory.fetch(:name , @name)
        if_regs = DEFAULT_INTERFACE_REGISTORY.dup
        if_regs[:name       ] = name
        if_regs[:block_start] = "architecture RTL of #{name} is"
        if_regs[:block_end  ] = "end RTL"
        if_regs.update(interface_registory)
        vhdl_lines = MsgPack_RPC_Interface::VHDL::Interface.generate_use(self)
        vhdl_lines.concat(generate_vhdl_body(indent, if_regs))
        return vhdl_lines
      end

      def generate_vhdl_instance(indent, interface_registory, external_registory)
        name = interface_registory.fetch(:name , @name)
        return MsgPack_RPC_Interface::VHDL::Interface.generate_instance(indent, name, self, interface_registory, external_registory)
      end
      
      def generate_vhdl_server(indent, server_registory, interface_registory)
        name = server_registory[:name]
        sv_regs = DEFAULT_SERVER_REGISTORY.dup
        sv_regs[:block_start] = "architecture RTL of #{name} is"
        sv_regs[:block_end  ] = "end RTL"
        sv_regs.update(server_registory)
        if_regs = DEFAULT_INTERFACE_REGISTORY.dup
        if_regs.update(interface_registory)
        md_regs = Hash.new
        md_regs[:name] = @name
        md_regs.update(@port_regs)
        return MsgPack_RPC_Interface::VHDL::Server.generate_entity(indent, name, self, sv_regs, if_regs, md_regs) +
               MsgPack_RPC_Interface::VHDL::Server.generate_body(  indent, name, self, sv_regs, if_regs, md_regs)
      end        

  end
  
end
