module MsgPack_RPC_Interface::VHDL::Memory::Arbitor
  extend MsgPack_RPC_Interface::VHDL::Util

  def generate_decl(indent, name, registory)
    addr_type = registory[:addr_type].generate_vhdl_type
    return string_to_lines(indent, <<"      EOT"
        signal    #{sprintf("%-17s",registory[:store_addr ])} :  #{addr_type};
        signal    #{sprintf("%-17s",registory[:store_ready])} :  std_logic;
        signal    #{sprintf("%-17s",registory[:store_start])} :  std_logic;
        signal    #{sprintf("%-17s",registory[:store_busy ])} :  std_logic;
        signal    #{sprintf("%-17s",registory[:query_addr ])} :  #{addr_type};
        signal    #{sprintf("%-17s",registory[:query_valid])} :  std_logic;
        signal    #{sprintf("%-17s",registory[:query_start])} :  std_logic;
        signal    #{sprintf("%-17s",registory[:query_busy ])} :  std_logic;
      EOT
    )
  end
  
  def generate_stmt(indent, name, registory)
    block_name = registory.fetch(:block_name, "PROC_ARB_" + name.upcase)
    return string_to_lines(indent, <<"      EOT"
        #{block_name} : block
            signal   proc_arb_state :  std_logic_vector(1 downto 0);
        begin
             process(#{registory[:clock]}, #{registory[:reset]}) begin
                 if (#{registory[:reset]} = '1') then
                         proc_arb_state <= (others => '0');
                 elsif (#{registory[:clock]}'event and #{registory[:clock]} = '1') then
                     if    (#{registory[:clear]} = '1') then
                         proc_arb_state <= (others => '0');
                     else
                         case proc_arb_state is
                             when "00" => 
                                 if    (#{registory[:store_start]} = '1') then
                                     proc_arb_state <= "01";
                                 elsif (#{registory[:query_start]} = '1') then
                                     proc_arb_state <= "10";
                                 else
                                     proc_arb_state <= "00";
                                 end if;
                             when "01" =>
                                 if    (#{registory[:store_busy ]} = '1') then
                                     proc_arb_state <= "01";
                                 else
                                     proc_arb_state <= "00";
                                 end if;
                             when "10" =>
                                 if    (#{registory[:query_busy ]} = '1') then
                                     proc_arb_state <= "10";
                                 else
                                     proc_arb_state <= "00";
                                 end if;
                             when others => 
                                     proc_arb_state <= "00";
                         end case;
                     end if;
                 end if;
             end process;
             #{registory[:store_ready]} <= proc_arb_state(0);
             #{registory[:query_valid]} <= proc_arb_state(1);
             #{registory[:addr       ]} <= #{registory[:store_addr]} when (proc_arb_state(0) = '1') else #{registory[:query_addr]};
        end block;
      EOT
    )
  end

  module_function :generate_decl
  module_function :generate_stmt
  
end
