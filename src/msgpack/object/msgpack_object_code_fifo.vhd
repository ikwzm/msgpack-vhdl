-----------------------------------------------------------------------------------
--!     @file    msgpack_object_code_fifo.vhd
--!     @brief   MessagePack Object Code FIFO
--!     @version 0.1.0
--!     @date    2015/10/19
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2015 Ichiro Kawazome
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
library MsgPack;
use     MsgPack.MsgPack_Object;
entity  MsgPack_Object_Code_FIFO is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        WIDTH           :  positive := 1;
        DEPTH           :  positive := 1
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack Object Code Input Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end MsgPack_Object_Code_FIFO;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
architecture RTL of MsgPack_Object_Code_FIFO is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   CODE_BITS_TYPE  is std_logic_vector(39 downto 0);
    function  to_bits(CODE: MsgPack_Object.Code_Type) return CODE_BITS_TYPE
    is
        variable  word :  CODE_BITS_TYPE;
    begin
        word(31 downto 0 ) := CODE.data;
        word(35 downto 32) := CODE.class;
        if (CODE.valid = '0') then
            word(39 downto 36) := "0000";
        else
            word(39) := CODE.complete;
            if    (CODE.STRB(3) = '1') then
                word(38 downto 36) := "111";
            elsif (CODE.STRB(2) = '1') then
                word(38 downto 36) := "110";
            elsif (CODE.STRB(1) = '1') then
                word(38 downto 36) := "101";
            elsif (CODE.STRB(0) = '1') then
                word(38 downto 36) := "100";
            else
                word(38 downto 36) := "011";
            end if;
        end if;
        return word;
    end function;
    function  to_code(WORD: CODE_BITS_TYPE) return MsgPack_Object.Code_Type is
        variable  code :  MsgPack_Object.Code_Type;
    begin
        code.data    := WORD(31 downto  0);
        code.class   := WORD(35 downto 32);
        if (WORD(39 downto 36) = "0000") then
            code.valid    := '0';
            code.complete := '0';
            code.strb     := "0000";
        else
            code.valid    := '1';
            code.complete := WORD(39);
            if    (WORD(38 downto 36) = "111") then
                code.strb := "1111";
            elsif (WORD(38 downto 36) = "110") then
                code.strb := "0111";
            elsif (WORD(38 downto 36) = "101") then
                code.strb := "0011";
            elsif (WORD(38 downto 36) = "100") then
                code.strb := "0001";
            else
                code.strb := "0000";
            end if;
        end if;
        return code;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  WORD_BITS       :  integer := 40*WIDTH;
    subtype   WORD_TYPE       is std_logic_vector(WORD_BITS-1 downto 0);
    function  to_word(CODE_VEC:  MsgPack_Object.Code_Vector) return WORD_TYPE is
        alias     i_code_vec  :  MsgPack_Object.Code_Vector(WIDTH-1 downto 0) is CODE_VEC;
        variable  word        :  WORD_TYPE;
    begin 
        for i in 0 to WIDTH-1 loop
            word(40*(i+1)-1 downto 40*i) := to_bits(i_code_vec(i));
        end loop;
        return word;
    end function;
    function  to_code(WORD: std_logic_vector) return MsgPack_Object.Code_Vector is
        variable  code_vec    :  MsgPack_Object.Code_Vector(WIDTH-1 downto 0);
    begin
        for i in 0 to WIDTH-1 loop
            code_vec(i) := to_code(word(40*(i+1)-1 downto 40*i));
        end loop;
        return code_vec;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    intake_ready    :  boolean;
    signal    outlet_valid    :  boolean;
    signal    outlet_last     :  boolean;
    signal    outlet_done     :  boolean;
    signal    wait_last       :  boolean;
    signal    curr_counter    :  unsigned(DEPTH   downto 0);
    signal    next_counter    :  unsigned(DEPTH   downto 0);
    signal    curr_wr_ptr     :  unsigned(DEPTH-1 downto 0);
    signal    next_wr_ptr     :  unsigned(DEPTH-1 downto 0);
    signal    curr_rd_ptr     :  unsigned(DEPTH-1 downto 0);
    signal    next_rd_ptr     :  unsigned(DEPTH-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type     RAM_TYPE         is array(integer range <>) of std_logic_vector(WORD_BITS-1 downto 0);
    signal   ram              :  RAM_TYPE(0 to 2**DEPTH-1);
    signal   ram_we           :  std_logic;
    signal   ram_waddr        :  std_logic_vector(DEPTH-1 downto 0);
    signal   ram_raddr        :  std_logic_vector(DEPTH-1 downto 0);
    signal   ram_wdata        :  std_logic_vector(WORD_BITS-1 downto 0);
    signal   ram_rdata        :  std_logic_vector(WORD_BITS-1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    I_READY <= '1' when (intake_ready) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    outlet_done <= (outlet_last and next_counter = 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (curr_counter, I_VALID, intake_ready, outlet_valid, O_READY)
        variable  temp_counter :  unsigned(DEPTH downto 0);
    begin
        temp_counter := curr_counter;
        if (I_VALID = '1' and intake_ready = TRUE) then
            temp_counter := temp_counter + 1;
        end if;
        if (outlet_valid = TRUE and O_READY = '1') then
            temp_counter := temp_counter - 1;
        end if;
        next_counter <= temp_counter;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (curr_wr_ptr, I_VALID, intake_ready) begin
        if (I_VALID = '1' and intake_ready = TRUE) then
            next_wr_ptr <= to_01(curr_wr_ptr) + 1;
        else
            next_wr_ptr <= to_01(curr_wr_ptr);
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (curr_rd_ptr, outlet_valid, O_READY) begin
        if (outlet_valid = TRUE and O_READY = '1') then
            next_rd_ptr <= to_01(curr_rd_ptr) + 1;
        else
            next_rd_ptr <= to_01(curr_rd_ptr);
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST)
        variable   next_last :  boolean;
    begin
        if   (RST = '1') then
                curr_counter <= (others => '0');
                curr_wr_ptr  <= (others => '0');
                curr_rd_ptr  <= (others => '0');
                intake_ready <= FALSE;
                wait_last    <= FALSE;
                outlet_valid <= FALSE;
                outlet_last  <= FALSE;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_counter <= (others => '0');
                curr_wr_ptr  <= (others => '0');
                curr_rd_ptr  <= (others => '0');
                intake_ready <= FALSE;
                wait_last    <= FALSE;
                outlet_valid <= FALSE;
                outlet_last  <= FALSE;
            else
                if (outlet_done = TRUE) then
                    curr_counter <= (others => '0');
                    curr_wr_ptr  <= (others => '0');
                    curr_rd_ptr  <= (others => '0');
                else
                    curr_counter <= next_counter;
                    curr_wr_ptr  <= next_wr_ptr;
                    curr_rd_ptr  <= next_rd_ptr;
                end if;

                if (outlet_done = TRUE) then
                    next_last    := FALSE;
                    wait_last    <= FALSE;
                    intake_ready <= TRUE;
                elsif (wait_last = TRUE) or
                      (I_VALID = '1' and I_LAST = '1' and intake_ready = TRUE) then
                    next_last    := TRUE;
                    wait_last    <= TRUE;
                    intake_ready <= FALSE;
                else
                    next_last    := FALSE;
                    wait_last    <= FALSE;
                    intake_ready <= (next_counter(next_counter'high) = '0');
                end if;

                outlet_last  <= (next_counter = 1 and next_last = TRUE);
                outlet_valid <= (next_counter > 0) and
                                (not (ram_we = '1' and ram_waddr = ram_raddr));
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ram_waddr <= std_logic_vector(curr_wr_ptr);
    ram_raddr <= std_logic_vector(next_rd_ptr);
    ram_we    <= '1' when (I_VALID = '1' and intake_ready = TRUE) else '0';
    ram_wdata <= to_word(I_CODE);
    process (CLK) begin
        if (CLK'event and CLK = '1') then
            if (ram_we = '1') then
                ram(to_integer(to_01(unsigned(ram_waddr)))) <= ram_wdata;
            end if;
            ram_rdata <= ram(to_integer(to_01(unsigned(ram_raddr))));
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    O_CODE  <= to_code(ram_rdata);
    O_VALID <= '1' when (outlet_valid) else '0';
    O_LAST  <= '1' when (outlet_last ) else '0';
            
end RTL;
