require_relative 'variable'

module MsgPack_RPC_Interface

  class Method

    attr_reader :name, :full_name, :interface, :arguments, :returns

    def initialize(registory)
      @debug     = registory.fetch("debug"    , false)
      aliases    = registory.fetch("aliases"  , {})
      @name      = registory["name"]
      @full_name = registory.fetch("full_name", []).clone.push(@name)
      puts "Method.new(#{@name}) start." if @debug
      @arguments = registory.fetch("arguments", []).map do |arg_regs|
        arg_regs["debug"    ] = @debug
        arg_regs["aliases"  ] = aliases
        arg_regs["full_name"] = @full_name
        arg_regs["write"    ] = true
        arg_regs["read"     ] = false
        arg_regs["kvmap"    ] = false
        arg_regs["interface"] = arg_regs.fetch("interface", "Signal")
        Variable.new(arg_regs)
      end
      @returns   = registory.fetch("returns"  , []).map do |ret_regs|
        ret_regs["debug"    ] = @debug
        ret_regs["aliases"  ] = aliases
        ret_regs["full_name"] = @full_name
        ret_regs["write"    ] = false
        ret_regs["read"     ] = true
        ret_regs["kvmap"    ] = false
        ret_regs["interface"] = ret_regs.fetch("interface", "Signal")
        if registory.key?("interface") then
          if registory["interface"].key?("port") then
            if registory["interface"]["port"].key?("return") then
              ret_regs["port_name"] = registory["interface"]["port"]["return"]
            end
          end
        end
        Variable.new(ret_regs)
      end
      met_regs = registory.fetch("interface" , Hash.new)
      met_regs["debug"         ] = @debug
      met_regs["name"          ] = @name
      met_regs["full_name"     ] = @full_name
      met_regs["arguments"     ] = @arguments
      met_regs["return"        ] = (@returns.size > 0) ? @returns[0] : nil
      @interface = Standard::Procedure::Interface::Method.new(met_regs)
      puts "Method.new(#{@name}) done." if @debug
    end

  end

  class QueryVariables

    attr_reader :name, :full_name, :variables, :interface

    def initialize(registory)
      @name      = registory.fetch("name", "$GET")
      @full_name = registory.fetch("full_name", []).clone.push(@name)
      @variables = registory["variables"]
      met_regs = Hash.new
      met_regs["debug"         ] = @debug
      met_regs["name"          ] = @name
      met_regs["full_name"     ] = @full_name
      met_regs["variables"     ] = @variables
      @interface = Standard::Procedure::Interface::QueryVariables.new(met_regs)
    end

  end
  
  class StoreVariables

    attr_reader :name, :full_name, :variables, :interface

    def initialize(registory)
      @name      = registory.fetch("name", "$SET")
      @full_name = registory.fetch("full_name", []).clone.push(@name)
      @variables = registory["variables"]
      met_regs = Hash.new
      met_regs["debug"         ] = @debug
      met_regs["name"          ] = @name
      met_regs["full_name"     ] = @full_name
      met_regs["variables"     ] = @variables
      @interface = Standard::Procedure::Interface::StoreVariables.new(met_regs)
    end

  end
  
end
