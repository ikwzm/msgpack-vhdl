module MsgPack_RPC_Interface

  module Variable 
    def new(registory)
      if registory.key?("variables")
        return Variable::Map.new(registory)
      else
        return Variable::Node.new(registory)
      end
    end
    module_function :new
  end

  class Variable::Base
    attr_reader :name, :type
    def initialize(registory)
      @debug  = registory.fetch("debug" , false)
      @name   = registory["name"]
    end
  end

  class Variable::Node < Variable::Base
    attr_reader :type, :interface, :default_value

    def initialize(registory)
      super(registory)
      puts "Variable::Node.new(#{@name}) start." if @debug
      @default_value = registory.fetch("default", nil)
      @type          = make_type(registory)
      @interface     = make_interface(registory)
      puts "Variable::Node.new(#{@name}, #{@type}) done." if @debug
    end

    def collect_readable_variables
      return (@interface.read )? [self] : []
    end

    def collect_writeable_variables
      return (@interface.write)? [self] : []
    end

    def make_type(varibale_regs)
      aliases   = varibale_regs.fetch("aliases"   , {})
      type_regs = resolve_alias(varibale_regs["type"     ], aliases)
      return Standard::Type.new(type_regs)
    end

    def make_interface(varibale_regs)
      name      = varibale_regs["name"]
      debug     = varibale_regs.fetch("debug"     , false)
      full_name = varibale_regs.fetch("full_name" , [])
      aliases   = varibale_regs.fetch("aliases"   , {})
      kvmap     = varibale_regs.fetch("kvmap"     , true )
      interface = resolve_alias(varibale_regs["interface"], aliases)

      if interface.class == Hash then
        interface_name = interface["name"]
        interface_regs = interface.clone
      else
        interface_name = interface
        interface_regs = Hash.new
      end

      if interface_regs.key?("type") then
        interface_type = Standard::Type.new(interface_regs["type"])
      else
        interface_type = @type
      end
      interface_regs["name"     ] = name
      interface_regs["full_name"] = full_name.clone.push(name)
      interface_regs["class"    ] = @type
      interface_regs["type"     ] = interface_type
      interface_regs["debug"    ] = debug
      interface_regs["kvmap"    ] = kvmap
      interface_regs["read"     ] = interface_regs.fetch("read" , varibale_regs.fetch("read"  , true))
      interface_regs["write"    ] = interface_regs.fetch("write", varibale_regs.fetch("write" , true))
        
      if Synthesijer::Variable::Interface.const_defined?(interface_name) then
        return Synthesijer::Variable::Interface.const_get(interface_name).new(interface_regs)
      else
        abort "Undefined Interface::#{interface_name}"
      end
    end
  
    def resolve_alias(item, aliases)
      while aliases.key?(item) do
        item = aliases[item]
      end
      if item.class == Hash then
        item.each_pair do |key, value|
          item[key] = resolve_alias(value, aliases)
        end
      end
      return item
    end
  end

  class Variable::Map < Variable::Base
    attr_reader :map
    
    def initialize(registory)
      super(registory)
      puts "Variable::Map.new(#{@name}) start." if @debug
      @map      = Hash.new
      @type     = Standard::Type::Map.new
      aliases   = registory.fetch("aliases"   , {})
      full_name = registory.fetch("full_name" , []).clone.push(@name)
      variables = registory["variables"]
      variables.each do |var_regs|
        var_regs["aliases"  ] = aliases
        var_regs["full_name"] = full_name
        var_regs["debug"    ] = @debug
        variable = Variable.new(var_regs)
        map[variable.name] = variable
      end
      puts "Variable::Map.new(#{@name}) done. " if @debug
    end

    def collect_readable_variables
      variables = Array.new
      @map.each_value do |variable|
        variables.concat(variable.collect_readable_variables)
      end
      return (variables.size > 0) ? [self] : []
    end

    def collect_writeable_variables
      variables = Array.new
      @map.each_value do |variable|
        variables.concat(variable.collect_writeable_variables)
      end
      return (variables.size > 0) ? [self] : []
    end
  end

end
