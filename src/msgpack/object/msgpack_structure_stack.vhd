-----------------------------------------------------------------------------------
--!     @file    msgpack_structre_stack.vhd
--!     @brief   MessagePack Array/Map Structure Stack :
--!     @version 0.1.0
--!     @date    2015/10/11
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2012-2015 Ichiro Kawazome
--      All rights reserved.
--
--      Redistribution and use in source and binary forms, with or without
--      modification, are permitted provided that the following conditions
--      are met:
--
--        1. Redistributions of source code must retain the above copyright
--           notice, this list of conditions and the following disclaimer.
--
--        2. Redistributions in binary form must reproduce the above copyright
--           notice, this list of conditions and the following disclaimer in
--           the documentation and/or other materials provided with the
--           distribution.
--
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
--      A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
--      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
--      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
entity  MsgPack_Structure_Stack is
    generic (
        DEPTH           : integer :=  4
    );
    port (
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
        I_SIZE          : in  std_logic_vector(31 downto 0);
        I_MAP           : in  std_logic;
        I_ARRAY         : in  std_logic;
        I_COMPLETE      : in  std_logic;
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
        O_LAST          : out std_logic;
        O_NONE          : out std_logic;
        O_FULL          : out std_logic
    );
end MsgPack_Structure_Stack;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
architecture RTL of MsgPack_Structure_Stack is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type     OP_TYPE        is (OP_NONE, OP_OVER, OP_LOAD, OP_PUSH, OP_POP1, OP_POP2, OP_DEC);
    signal   op             :  OP_TYPE;
    signal   complete       :  boolean;
    signal   stack_count    :  unsigned(DEPTH   downto 0);
    signal   stack_full     :  boolean;
    signal   stack_empty    :  boolean;
    signal   stack_last     :  boolean;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant COUNT_BITS     :  integer :=  I_SIZE'length+1;
    signal   object_count   :  unsigned(COUNT_BITS-1 downto 0);
    signal   object_map     :  std_logic;
    signal   object_last    :  boolean;
    signal   object_pop     :  boolean;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant RAM_COUNT_LO   :  integer := 0;
    constant RAM_COUNT_HI   :  integer := RAM_COUNT_LO + COUNT_BITS - 1;
    constant RAM_MAP_POS    :  integer := RAM_COUNT_HI + 1;
    constant RAM_BITS       :  integer := RAM_MAP_POS  - RAM_COUNT_LO + 1;
    type     RAM_TYPE       is array(integer range <>) of std_logic_vector(RAM_BITS-1 downto 0);
    signal   ram            :  RAM_TYPE(0 to 2**DEPTH-1);
    signal   ram_waddr      :  std_logic_vector(DEPTH-1 downto 0);
    signal   ram_raddr      :  std_logic_vector(DEPTH-1 downto 0);
    signal   ram_wdata      :  std_logic_vector(RAM_BITS-1 downto 0);
    signal   ram_rdata      :  std_logic_vector(RAM_BITS-1 downto 0);
    signal   ram_we         :  std_logic;
    signal   ram_wptr       :  unsigned(DEPTH downto 0);
    signal   ram_rptr       :  unsigned(DEPTH downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (I_VALID, I_SIZE, I_MAP, I_ARRAY, I_COMPLETE, object_pop, object_last, stack_empty, stack_full) begin
        if    (object_pop = TRUE) then
                op       <= OP_POP2;
                complete <= FALSE;
        elsif (I_VALID = '1') then
            if    (I_MAP = '1' or I_ARRAY = '1') and
                  (to_01(unsigned(I_SIZE)) /= 0 ) then
                if    (stack_empty = FALSE and object_last = TRUE) then
                    op <= OP_LOAD;
                elsif (stack_full  = FALSE) then
                    op <= OP_PUSH;
                else
                    op <= OP_OVER;
                end if;
                complete <= FALSE;
            elsif (I_COMPLETE = '1') then
                if    (stack_empty = TRUE) then
                    op <= OP_NONE;
                elsif (object_last = TRUE) then
                    op <= OP_POP1;
                else
                    op <= OP_DEC;
                end if;
                complete <= TRUE;
            else
                op       <= OP_NONE;
                complete <= FALSE;
            end if;
        else
                op       <= OP_NONE;
                complete <= FALSE;
        end if;
    end process;
    I_READY <= '1' when (object_pop = FALSE) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST)
        variable next_count : unsigned(COUNT_BITS-1 downto 0);
    begin
        if (RST = '1') then
                object_count <= (others => '0');
                object_map   <= '0';
                object_last  <= TRUE;
                object_pop   <= FALSE;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                object_count <= (others => '0');
                object_map   <= '0';
                object_last  <= TRUE;
                object_pop   <= FALSE;
            else
                case op is
                    when OP_PUSH | OP_LOAD =>
                        if (I_MAP = '1') then
                            next_count := unsigned(I_SIZE) & "0";
                            object_map <= '1';
                        else
                            next_count := "0" & unsigned(I_SIZE);
                            object_map <= '0';
                        end if;
                    when OP_POP1 =>
                            next_count := object_count;
                            object_pop <= TRUE;
                    when OP_POP2 =>
                            next_count := unsigned(ram_rdata(RAM_COUNT_HI downto RAM_COUNT_LO)) - 1;
                            object_map <= ram_rdata(RAM_MAP_POS);
                            object_pop <= FALSE;
                    when OP_DEC  =>
                            next_count := object_count - 1;
                    when others  =>
                            next_count := object_count;
                end case;
                object_count <= next_count;
                object_last  <= (next_count = 0 or next_count = 1);
             -- assert (op /= OP_OVER) report "stack error" severity error;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    STACK_CTRL: block
        signal   next_count :  unsigned(DEPTH   downto 0);
    begin 
        process (stack_count, CLR, op) begin
            if    (CLR  = '1') then
                next_count <= (others => '0');
            elsif (op = OP_PUSH) then
                next_count <= to_01(stack_count) + 1;
            elsif (op = OP_POP1) then
                next_count <= to_01(stack_count) - 1;
            else
                next_count <= stack_count;
            end if;
        end process;

        process (CLK, RST) begin
            if (RST = '1') then
                stack_count <= (others => '0');
                stack_full  <= FALSE;
                stack_empty <= TRUE;
            elsif (CLK'event and CLK = '1') then
                stack_count <= next_count;
                stack_full  <= (to_01(next_count) >= 2**DEPTH);
                stack_empty <= (to_01(next_count)  =        0);
            end if;
        end process;
        ram_wptr   <= stack_count;
        ram_rptr   <= stack_count-1;
        stack_last <= (to_01(next_count) <= 0);
    end block;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    O_LAST  <= '1' when (stack_empty = TRUE and complete = TRUE) or
                        (stack_last  = TRUE and complete = TRUE) else '0';
    O_FULL  <= '1' when (stack_full  = TRUE) else '0';
    O_NONE  <= '1' when (stack_empty = TRUE) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ram_wdata(RAM_MAP_POS                     ) <= object_map;
    ram_wdata(RAM_COUNT_HI downto RAM_COUNT_LO) <= std_logic_vector(object_count);
    ram_waddr   <= std_logic_vector(ram_wptr(ram_waddr'range));
    ram_raddr   <= std_logic_vector(ram_rptr(ram_raddr'range));
    ram_we      <= '1' when (op = OP_PUSH and stack_full = FALSE) else '0';

    process (CLK) begin
        if (CLK'event and CLK = '1') then
            if (ram_we = '1') then
                ram(to_integer(to_01(unsigned(ram_waddr)))) <= ram_wdata;
            end if;
            ram_rdata <= ram(to_integer(to_01(unsigned(ram_raddr))));
        end if;
    end process;
end RTL;
