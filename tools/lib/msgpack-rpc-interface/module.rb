require_relative 'variable'
require_relative 'method'
require_relative 'standard'

module MsgPack_RPC_Interface

  class Module
    attr_reader :name, :variables, :methods, :aliases, :interface, :generate, :port

    def initialize(registory)
      @debug     = registory.fetch("debug"   , false)
      @verbose   = registory.fetch("verbose" , false)
      @name      = registory["name"]
      @variables = Array.new
      @methods   = Array.new
      @aliases   = registory.fetch("aliases" , {})
      @generate  = registory.fetch("generate", {})
      @port      = registory.fetch("port"    , {})
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
      interface_regs["port"     ] = @port
      @interface = Standard::Module::Interface.new(interface_regs)
      puts "Module.new(#{@name}) done." if @debug
    end

    def generate_interface(interface_registory)
      return @interface.generate_vhdl_entity(       "", interface_registory) + 
             @interface.generate_vhdl_architecture( "", interface_registory)
    end

    def generate_server(server_registory, interface_registory)
      return @interface.generate_vhdl_server("", server_registory, interface_registory)
    end
  end
end
