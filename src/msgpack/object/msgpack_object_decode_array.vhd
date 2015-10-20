-----------------------------------------------------------------------------------
--!     @file    msgpack_object_decode_array.vhd
--!     @brief   MessagePack Object decode to array
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
entity  MsgPack_Object_Decode_Array is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1
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
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_ERROR         : out std_logic;
        I_DONE          : out std_logic;
        I_SHIFT         : out std_logic_vector(CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        ARRAY_START     : out std_logic;
        ARRAY_SIZE      : out std_logic_vector(31 downto 0);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        VALUE_START     : out std_logic;
        VALUE_VALID     : out std_logic;
        VALUE_CODE      : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        VALUE_LAST      : out std_logic;
        VALUE_ERROR     : in  std_logic;
        VALUE_DONE      : in  std_logic;
        VALUE_SHIFT     : in  std_logic_vector(CODE_WIDTH-1 downto 0)
    );
end  MsgPack_Object_Decode_Array;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
architecture RTL of MsgPack_Object_Decode_Array is
    signal    array_count       :  std_logic_vector(31 downto 0);
    signal    array_count_zero  :  boolean;
    type      STATE_TYPE        is (IDLE_STATE, START_STATE, VALUE_STATE);
    signal    curr_state        :  STATE_TYPE;
    signal    next_state        :  STATE_TYPE;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  to_shift(NUM:integer) return std_logic_vector is
        variable  shift     :  std_logic_vector(CODE_WIDTH-1 downto 0);
    begin
        for i in shift'range loop
            if (i < NUM) then
                shift(i) := '1';
            else
                shift(i) := '0';
            end if;
        end loop;
        return shift;
    end function;
begin 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (curr_state, I_VALID, I_CODE, I_LAST, VALUE_ERROR, VALUE_DONE, VALUE_SHIFT, array_count_zero)
        variable  ii_valid      :  std_logic_vector(CODE_WIDTH-1 downto 0);
        constant  II_ALL_0      :  std_logic_vector(CODE_WIDTH-1 downto 0) := (others => '0');
        impure function  i_nomore(SHIFT:  std_logic_vector) return boolean is begin
            return ((I_LAST = '1') and
                    ((ii_valid and not SHIFT) = II_ALL_0));
        end function;
    begin
        for i in ii_valid'range loop
            ii_valid(i) := I_CODE(i).valid;
        end loop;
        case curr_state is
            when IDLE_STATE =>
                if (I_VALID = '1' and I_CODE(0).valid = '1') then
                    if    (I_CODE(0).class /= MsgPack_Object.CLASS_ARRAY) then
                        I_ERROR     <= '1';
                        I_DONE      <= '1';
                        I_SHIFT     <= to_shift(0);
                        ARRAY_START <= '0';
                        VALUE_START <= '0';
                        next_state  <= IDLE_STATE;
                    else
                        I_ERROR     <= '0';
                        I_DONE      <= '0';
                        I_SHIFT     <= to_shift(0);
                        ARRAY_START <= '1';
                        VALUE_START <= '0';
                        next_state  <= START_STATE;
                    end if;
                else
                        I_ERROR     <= '0';
                        I_DONE      <= '0';
                        I_SHIFT     <= to_shift(0);
                        ARRAY_START <= '0';
                        VALUE_START <= '0';
                        next_state  <= IDLE_STATE;
                end if;
            when START_STATE =>
                if    (array_count_zero = TRUE) then
                        I_ERROR     <= '0';
                        I_DONE      <= '1';
                        I_SHIFT     <= to_shift(1);
                        ARRAY_START <= '0';
                        VALUE_START <= '0';
                        next_state  <= IDLE_STATE;
                elsif (i_nomore(to_shift(1))) then
                        I_ERROR     <= '1';
                        I_DONE      <= '1';
                        I_SHIFT     <= to_shift(0);
                        ARRAY_START <= '0';
                        VALUE_START <= '0';
                        next_state  <= IDLE_STATE;
                else
                        I_ERROR     <= '0';
                        I_DONE      <= '0';
                        I_SHIFT     <= to_shift(1);
                        ARRAY_START <= '0';
                        VALUE_START <= '1';
                        next_state  <= VALUE_STATE;
                end if;
            when VALUE_STATE =>
                if (VALUE_DONE = '1') then
                    if    (VALUE_ERROR = '1') or
                          (array_count_zero = FALSE and i_nomore(VALUE_SHIFT)) then
                        I_ERROR     <= '1';
                        I_DONE      <= '1';
                        I_SHIFT     <= VALUE_SHIFT;
                        ARRAY_START <= '0';
                        VALUE_START <= '0';
                        next_state  <= IDLE_STATE;
                    elsif (array_count_zero = TRUE) then
                        I_ERROR     <= '0';
                        I_DONE      <= '1';
                        ARRAY_START <= '0';
                        VALUE_START <= '0';
                        I_SHIFT     <= VALUE_SHIFT;
                        next_state  <= IDLE_STATE;
                    else
                        I_ERROR     <= '0';
                        I_DONE      <= '0';
                        ARRAY_START <= '0';
                        VALUE_START <= '1';
                        I_SHIFT     <= VALUE_SHIFT;
                        next_state  <= VALUE_STATE;
                    end if;
                else
                        I_ERROR     <= '0';
                        I_DONE      <= '0';
                        I_SHIFT     <= VALUE_SHIFT;
                        ARRAY_START <= '0';
                        VALUE_START <= '0';
                        next_state  <= VALUE_STATE;
                end if;
            when others =>
                        I_ERROR     <= '0';
                        I_DONE      <= '0';
                        I_SHIFT     <= to_shift(0);
                        ARRAY_START <= '0';
                        VALUE_START <= '0';
                        next_state  <= IDLE_STATE;
        end case;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                curr_state <= IDLE_STATE;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state <= IDLE_STATE;
            else
                curr_state <= next_state;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST)
        variable  next_count : unsigned(array_count'range);
    begin
        if (RST = '1') then
                array_count      <= (others => '0');
                array_count_zero <= TRUE;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                array_count      <= (others => '0');
                array_count_zero <= TRUE;
            else
                if (curr_state = IDLE_STATE) then
                    next_count := unsigned(I_CODE(0).data);
                else
                    next_count := unsigned(array_count   );
                end if;
                if (curr_state = START_STATE) or
                   (curr_state = VALUE_STATE and VALUE_DONE = '1') then
                    next_count := next_count - 1;
                end if;
                array_count      <= std_logic_vector(next_count);
                array_count_zero <= (next_count = 0);
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ARRAY_SIZE  <= I_CODE(0).data;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    VALUE_VALID <= '1' when (curr_state = VALUE_STATE) else '0';
    VALUE_LAST  <= '1' when (curr_state = VALUE_STATE and I_LAST = '1') else '0';
    process (I_CODE, curr_state) begin
        for i in 0 to CODE_WIDTH-1 loop
            VALUE_CODE(i) <= I_CODE(i);
            if (curr_state = VALUE_STATE) then
                VALUE_CODE(i).valid <= I_CODE(i).valid;
            else
                VALUE_CODE(i).valid <= '0';
            end if;
        end loop;
    end process;
end RTL;
