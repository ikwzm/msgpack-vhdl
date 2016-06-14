module MsgPack_RPC_Interface::VHDL::Util

  def string_to_lines(indent, str)
    first_line_indent = str.slice(/^\s*/)
    vhdl_code_list    = Array.new
    str.split(/\n/).each do |line|
      vhdl_code_list.push(line.sub(/^#{first_line_indent}/, indent))
    end
    return vhdl_code_list
  end

  def add_generic_line(list, registory, name, type)
    if registory.key?(name) then
      if registory[name].to_s.match(/^[a-zA-Z]+/) then
        list << sprintf("%-20s : %s", registory[name], type)
      end
    end
  end
      
  def add_port_line(list, registory, name, io, type)
    if registory.key?(name) then
      if registory[name].to_s.match(/^[a-zA-Z]+/) then
        list << sprintf("%-20s : %-3s %s", registory[name], io, type)
      end
    end
  end
      
  module_function :string_to_lines
  module_function :add_generic_line
  module_function :add_port_line

  module Store

    def instance_name(name, data_type, registory)
      if sub_block?(data_type, registory) then
        return "PROC_0"
      else
        return registory.fetch(:instance_name, "PROC_STORE_" + name.upcase)
      end
    end

    def interface_signals(data_type, registory)
      signals = Hash.new
      if registory.key?(:store_data) then
        if data_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          signals[:data] = "proc_0_data"
        else
          signals[:data] = registory[:store_data]
        end
      else
          signals[:data] = "open"
      end
      if registory.key?(:store_addr) then
        addr_type = registory[:addr_type]
        if addr_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          signals[:addr] = "proc_0_addr"
        else
          signals[:addr] = registory[:store_addr]
        end
      else
          signals[:addr] = "open"
      end
      if registory.key?(:store_size) then
        size_type = registory[:size_type]
        signals[:size_bits] = addr_type.bits
        if size_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          signals[:size] = "proc_0_size"
        else
          signals[:size] = registory[:store_size]
        end
      else
          signals[:size] = "open"
      end
      if registory.key?(:addr_type) then
        signals[:addr_bits] = registory[:addr_type].bits
      else
        signals[:addr_bits] = 32
      end
      if registory.key?(:size_type) then
        signals[:size_bits] = registory[:size_type].bits
      else
        signals[:size_bits] = 32
      end
      signals[:data_bits] = registory[:width]*data_type.bits
      signals[:strb_bits] = registory[:width]
      signals[:start    ] = registory.fetch(:store_start, "open")
      signals[:busy     ] = registory.fetch(:store_busy , "open")
      signals[:last     ] = registory.fetch(:store_last , "open")
      signals[:strb     ] = registory.fetch(:store_strb , "open")
      signals[:valid    ] = registory.fetch(:store_valid, "open")
      signals[:ready    ] = registory.fetch(:store_ready, "'1'" )
      return signals
    end

    def sub_block?(data_type, registory)
      sub_block = false
      if registory.key?(:store_data) then
        if data_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          sub_block = true
        end
      end
      if registory.key?(:store_addr) then
        addr_type = registory[:addr_type]
        if addr_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          sub_block = true
        end
      end
      if registory.key?(:store_size) then
        size_type = registory[:size_type]
        if size_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          sub_block = true
        end
      end
      return sub_block
    end

    def generate_decl(indent, name, data_type, kvmap, registory)
      vhdl_lines = Array.new
      if registory.key?(:store_data) then
        if data_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          vhdl_lines.concat(string_to_lines(indent, 
            "signal    proc_0_data      :  std_logic_vector(#{data_type.bits-1} downto 0);"
          ))
        end
      end
      if registory.key?(:store_addr) then
        addr_type = registory[:addr_type]
        if addr_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          vhdl_lines.concat(string_to_lines(indent,
            "signal    proc_0_addr      :  std_logic_vector(#{addr_type.bits-1} downto 0);"
          ))
        end
      end
      if registory.key?(:store_size) then
        size_type = registory[:size_type]
        if size_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          vhdl_lines.concat(string_to_lines(indent,
            "signal    proc_0_size      :  std_logic_vector(#{size_type.bits-1} downto 0);"
          ))
        end
      end
      return vhdl_lines
    end

    def generate_stmt_post(indent, name, data_type, kvmap, registory)
      vhdl_lines = Array.new
      if registory.key?(:store_data) then
        if data_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          converted_data = data_type.generate_vhdl_convert("proc_0_data")
          vhdl_lines.concat(string_to_lines(indent, 
            "#{registory[:store_data]} <= #{converted_data};"
          ))
        end
      end
      if registory.key?(:store_addr) then
        addr_type = registory[:addr_type]
        if addr_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          converted_addr = addr_type.generate_vhdl_convert("proc_0_addr")
          vhdl_lines.concat(string_to_lines(indent, 
            "#{registory[:store_addr]} <= #{converted_addr};"
          ))
        end
      end
      if registory.key?(:store_size) then
        size_type = registory[:size_type]
        if size_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          converted_size = size_type.generate_vhdl_convert("proc_0_size")
          vhdl_lines.concat(string_to_lines(indent, 
            "#{registory[:store_size]} <= #{converted_size};"
          ))
        end
      end
      return vhdl_lines
    end

    def generate_body(indent, name, data_type, kvmap, registory)
      if sub_block?(data_type, registory) then
        block_name = registory.fetch(:instance_name, "PROC_STORE_" + name.upcase)
        decl_lines = generate_decl(indent + "    ", name, data_type, kvmap, registory)
        stmt_lines = generate_stmt(indent + "    ", name, data_type, kvmap, registory)
        return ["#{indent}#{block_name}: block"] + 
               decl_lines + 
               ["#{indent}begin"] +
               stmt_lines +
               ["#{indent}end block;"]
      else
        return generate_stmt(indent, name, data_type, kvmap, registory)
      end
    end

    module_function :instance_name
    module_function :interface_signals
    module_function :sub_block?
    module_function :generate_decl
    module_function :generate_body
    module_function :generate_stmt_post
  end

  module Query

    def instance_name(name, data_type, registory)
      if sub_block?(data_type, registory) then
        return "PROC_1"
      else
        return registory.fetch(:instance_name, "PROC_QUERY_" + name.upcase)
      end
    end

    def sub_block?(data_type, registory)
      sub_block = false
      if registory.key?(:query_data) then
        if data_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          sub_block = true
        end
      end
      if registory.key?(:query_addr) then
        addr_type = registory[:addr_type]
        if addr_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          sub_block = true
        end
      end
      if registory.key?(:query_size) then
        size_type = registory[:size_type]
        if size_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          sub_block = true
        end
      end
      return sub_block
    end

    def interface_signals(data_type, registory)
      signals = Hash.new
      if registory.key?(:query_data) then
        if data_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          signals[:data] = "proc_1_data"
        else
          signals[:data] = registory[:query_data]
        end
      else
          signals[:data] = "open"
      end
      if registory.key?(:query_addr) then
        addr_type = registory[:addr_type]
        if addr_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          signals[:addr] = "proc_1_addr"
        else
          signals[:addr] = registory[:query_addr]
        end
      else
          signals[:addr] = "open"
      end
      if registory.key?(:query_size) then
        size_type = registory[:size_type]
        signals[:size_bits] = addr_type.bits
        if size_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          signals[:size] = "proc_1_size"
        else
          signals[:size] = registory[:query_size]
        end
      else
          signals[:size] = "open"
      end
      if registory.key?(:addr_type) then
        signals[:addr_bits] = registory[:addr_type].bits
      else
        signals[:addr_bits] = 32
      end
      if registory.key?(:size_type) then
        signals[:size_bits] = registory[:size_type].bits
      else
        signals[:size_bits] = 32
      end
      signals[:data_bits] = registory[:width]*data_type.bits
      signals[:strb_bits] = registory[:width]
      signals[:start    ] = registory.fetch(:query_start, "open")
      signals[:busy     ] = registory.fetch(:query_busy , "open")
      signals[:last     ] = registory.fetch(:query_last , "'1'" )
      signals[:strb     ] = registory.fetch(:query_strb , '"' + Array.new(registory[:width],1).join + '"')
      signals[:valid    ] = registory.fetch(:query_valid, "'1'" )
      signals[:ready    ] = registory.fetch(:query_ready, "open")
      return signals
    end

    def generate_decl(indent, name, data_type, kvmap, registory)
      vhdl_lines = Array.new
      if registory.key?(:query_data) then
        if data_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          vhdl_lines.concat(string_to_lines(indent, 
            "signal    proc_1_data      :  std_logic_vector(#{data_type.bits-1} downto 0);"
          ))
        end
      end
      if registory.key?(:query_addr) then
        addr_type = registory[:addr_type]
        if addr_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          vhdl_lines.concat(string_to_lines(indent,
            "signal    proc_1_addr      :  std_logic_vector(#{addr_type.bits-1} downto 0);"
          ))
        end
      end
      if registory.key?(:query_size) then
        size_type = registory[:size_type]
        if size_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          vhdl_lines.concat(string_to_lines(indent,
            "signal    proc_1_size      :  std_logic_vector(#{size_type.bits-1} downto 0);"
          ))
        end
      end
      return vhdl_lines
    end

    def generate_stmt_post(indent, name, data_type, kvmap, registory)
      vhdl_lines = Array.new
      if registory.key?(:query_data) then
        if data_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          vhdl_lines.concat(string_to_lines(indent, 
            "proc_1_data <= std_logic_vector(#{registory[:query_data]});"
          ))
        end
      end
      if registory.key?(:query_addr) then
        addr_type = registory[:addr_type]
        if addr_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          converted_addr = addr_type.generate_vhdl_convert("proc_1_addr")
          vhdl_lines.concat(string_to_lines(indent,
            "#{registory[:query_addr]} <= #{converted_addr};"
          ))
        end
      end
      if registory.key?(:query_size) then
        size_type = registory[:size_type]
        if size_type.generate_vhdl_type.match(/^std_logic_vector/) == nil then
          converted_size = size_type.generate_vhdl_convert("proc_1_size")
          vhdl_lines.concat(string_to_lines(indent,
            "#{registory[:query_size]} <= #{converted_size};"
          ))
        end
      end
      return vhdl_lines
    end

    def generate_body(indent, name, data_type, kvmap, registory)
      if sub_block?(data_type, registory) then
        block_name = registory.fetch(:instance_name, "PROC_QUERY_" + name.upcase)
        decl_lines = generate_decl(indent + "    ", name, data_type, kvmap, registory)
        stmt_lines = generate_stmt(indent + "    ", name, data_type, kvmap, registory)
        return ["#{indent}#{block_name}: block"] + 
               decl_lines + 
               ["#{indent}begin"] +
               stmt_lines +
               ["#{indent}end block;"]
      else
        return generate_stmt(indent, name, data_type, kvmap, registory)
      end
    end

    module_function :instance_name
    module_function :interface_signals
    module_function :sub_block?
    module_function :generate_decl
    module_function :generate_body
    module_function :generate_stmt_post
  end

end
