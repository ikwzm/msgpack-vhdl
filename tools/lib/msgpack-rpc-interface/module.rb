require_relative 'variable'
require_relative 'method'
require_relative 'synthesijer'

module MsgPack_RPC_Interface

  class Module
    attr_reader :name, :variables, :methods, :aliases, :interface, :generate

    def initialize(registory)
      @debug     = registory.fetch("debug"   , false)
      @verbose   = registory.fetch("verbose" , false)
      @name      = registory["name"]
      @variables = Array.new
      @methods   = Array.new
      @aliases   = registory.fetch("aliases" , {})
      @generate  = registory.fetch("generate", {})
      puts "Module.new(#{@name}) start." if @debug
      if registory.key?("methods") then
        registory["methods"].each do |m|
          if m.key?("aliases") then
            m["aliases"] = @aliases.merge(m["aliases"])
          else
            m["aliases"] = @aliases
          end
          m["debug"] = @debug
          @methods   << Method.new(m)
        end
      end
      if registory.key?("variables") then
        registory["variables"].each do |v|
          if v.key?("aliases") then
            v["aliases"] = @aliases.merge(v["aliases"])
          else
            v["aliases"] = @aliases
          end
          v["debug"] = @debug
          v["kvmap"] = true
          @variables << Variable.new(v)
        end
      end
      read_variables = Array.new
      @variables.each do |variable|
        read_variables.concat(variable.collect_readable_variables)
      end
      if read_variables.size then
        @methods << QueryVariables.new(Hash({"debug" => @debug, "variables" => read_variables}))
      end
      write_variables = Array.new
      @variables.each do |variable|
        write_variables.concat(variable.collect_writeable_variables)
      end
      if write_variables.size then
        @methods << StoreVariables.new(Hash({"debug" => @debug, "variables" => write_variables}))
      end
      interface_regs = Hash.new
      interface_regs["name"     ] = @name
      interface_regs["full_name"] = []
      interface_regs["debug"    ] = @debug
      interface_regs["methods"  ] = @methods
      interface_regs["variables"] = @variables
      @interface = Synthesijer::Module::Interface.new(interface_regs)
      puts "Module.new(#{@name}) done." if @debug
    end

    DEFAULT_REGISTORY = Hash({
      clock:        "CLK"    ,
      reset:        "RST"    ,
      clear:        "CLR"    ,
      intake_bytes: "I_BYTES",
      intake_data:  "I_DATA" ,
      intake_strb:  "I_STRB" ,
      intake_last:  "I_LAST" ,
      intake_valid: "I_VALID",
      intake_ready: "I_READY",
      outlet_bytes: "O_BYTES",
      outlet_data:  "O_DATA" ,
      outlet_strb:  "O_STRB" ,
      outlet_last:  "O_LAST" ,
      outlet_valid: "O_VALID",
      outlet_ready: "O_READY"
    })

    def generate_interface(registory)
      name    = registory.fetch(:name, @name)
      if_regs = DEFAULT_REGISTORY.dup
      if_regs[:name       ] = name
      if_regs[:block_start] = "architecture RTL of #{name} is"
      if_regs[:block_end  ] = "end RTL"
      if_regs.update(registory)
      return @interface.generate_vhdl_entity(        "", if_regs) + 
             @interface.generate_vhdl_architecture(  "", if_regs)
    end
  end
end
