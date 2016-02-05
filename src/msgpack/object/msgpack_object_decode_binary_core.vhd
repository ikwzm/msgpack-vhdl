-----------------------------------------------------------------------------------
--!     @file    msgpack_object_decode_binary_core.vhd
--!     @brief   MessagePack Object decode to binary/string core module
--!     @version 0.2.0
--!     @date    2015/11/9
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
entity  MsgPack_Object_Decode_Binary_Core is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        DECODE_BINARY   :  boolean  := TRUE;
        DECODE_STRING   :  boolean  := FALSE
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
        I_SHIFT         : out std_logic_vector(CODE_WIDTH -1 downto 0);
    -------------------------------------------------------------------------------
    -- Integer Value Output Interface
    -------------------------------------------------------------------------------
        O_ENABLE        : out std_logic;
        O_START         : out std_logic;
        O_SIZE          : out std_logic_vector(MsgPack_Object.CODE_DATA_BITS           -1 downto 0);
        O_DATA          : out std_logic_vector(MsgPack_Object.CODE_DATA_BITS*CODE_WIDTH-1 downto 0);
        O_STRB          : out std_logic_vector(MsgPack_Object.CODE_STRB_BITS*CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end  MsgPack_Object_Decode_Binary_Core;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
architecture RTL of MsgPack_Object_Decode_Binary_Core is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  CODE_DATA_BITS    :  integer := MsgPack_Object.CODE_DATA_BITS;
    constant  CODE_DATA_BYTES   :  integer := MsgPack_Object.CODE_DATA_BYTES;
    constant  CODE_STRB_BITS    :  integer := MsgPack_Object.CODE_STRB_BITS;
    constant  CODE_STRB_NULL    :  std_logic_vector(CODE_STRB_BITS-1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  OUTLET_BITS       :  integer := MsgPack_Object.CODE_DATA_BITS*CODE_WIDTH;
    constant  OUTLET_BYTES      :  integer := OUTLET_BITS/8;
    signal    outlet_start      :  std_logic;
    signal    outlet_enable     :  std_logic;
    signal    outlet_valid      :  std_logic;
    signal    outlet_last       :  std_logic;
    signal    outlet_ready      :  std_logic;
    signal    outlet_strb       :  std_logic_vector(OUTLET_BYTES-1 downto 0);
    signal    outlet_data       :  std_logic_vector(OUTLET_BITS -1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      STATE_TYPE       is (IDLE_STATE, BINARY_DATA_STATE, STRING_DATA_STATE);
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
    process (curr_state, I_VALID, I_LAST, I_CODE, outlet_ready)
        variable  valid   :  std_logic;
        variable  last    :  std_logic;
        variable  shift   :  std_logic_vector(CODE_WIDTH-1 downto 0);
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        last  := '0';
        valid := '0';
        for i in 0 to CODE_WIDTH-1 loop
            if (I_CODE(i).valid = '1' and last = '0') then
                shift(i) := '1';
                valid    := '1';
            else
                shift(i) := '0';
            end if;
            if (I_CODE(i).valid = '1' and I_CODE(i).complete = '1') then
                last := '1';
            end if;
            if (shift(i) = '1') then
                outlet_strb(CODE_STRB_BITS*(i+1)-1 downto CODE_STRB_BITS*i) <= I_CODE(i).strb;
            else
                outlet_strb(CODE_STRB_BITS*(i+1)-1 downto CODE_STRB_BITS*i) <= CODE_STRB_NULL;
            end if;
            outlet_data(CODE_DATA_BITS*(i+1)-1 downto CODE_DATA_BITS*i) <= I_CODE(i).data;
        end loop;
        valid := valid and I_VALID;
        last  := last  or  I_LAST;
        outlet_last <= last;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        case curr_state is
            when IDLE_STATE =>
                if (I_VALID = '1' and I_CODE(0).valid = '1') then
                    if    (I_CODE(0).class = MsgPack_Object.CLASS_STRING_SIZE and DECODE_STRING = TRUE) then
                        if (I_CODE(0).complete = '1') then
                            I_ERROR       <= '0';
                            I_DONE        <= '1';
                            I_SHIFT       <= to_shift(1);
                            next_state    <= IDLE_STATE;
                            outlet_start  <= '0';
                            outlet_enable <= '0';
                        else
                            I_ERROR       <= '0';
                            I_DONE        <= '0';
                            I_SHIFT       <= to_shift(1);
                            next_state    <= STRING_DATA_STATE;
                            outlet_start  <= '1';
                            outlet_enable <= '1';
                        end if;
                    elsif (I_CODE(0).class = MsgPack_Object.CLASS_BINARY_SIZE and DECODE_BINARY = TRUE) then
                        if (I_CODE(0).complete = '1') then
                            I_ERROR       <= '0';
                            I_DONE        <= '1';
                            I_SHIFT       <= to_shift(1);
                            next_state    <= IDLE_STATE;
                            outlet_start  <= '0';
                            outlet_enable <= '0';
                        else
                            I_ERROR       <= '0';
                            I_DONE        <= '0';
                            I_SHIFT       <= to_shift(1);
                            next_state    <= BINARY_DATA_STATE;
                            outlet_start  <= '1';
                            outlet_enable <= '1';
                        end if;
                    else
                            I_ERROR       <= '1';
                            I_DONE        <= '1';
                            I_SHIFT       <= to_shift(0);
                            next_state    <= IDLE_STATE;
                            outlet_start  <= '0';
                            outlet_enable <= '0';
                    end if;
                else
                            I_ERROR       <= '0';
                            I_DONE        <= '0';
                            I_SHIFT       <= to_shift(0);
                            next_state    <= IDLE_STATE;
                            outlet_start  <= '0';
                            outlet_enable <= '0';
                end if;
                outlet_valid <= '0';
            when STRING_DATA_STATE |
                 BINARY_DATA_STATE =>
                if (outlet_ready = '1') then
                    if (last = '1') then
                        I_ERROR <= '0';
                        I_DONE  <= '1';
                        I_SHIFT <= shift;
                    else
                        I_ERROR <= '0';
                        I_DONE  <= '0';
                        I_SHIFT <= shift;
                    end if;
                else
                        I_ERROR <= '0';
                        I_DONE  <= '0';
                        I_SHIFT <= to_shift(0);
                end if;
                if (valid = '1' and outlet_ready = '1' and last = '1') then
                    next_state <= IDLE_STATE;
                else
                    next_state <= curr_state;
                end if;
                outlet_valid  <= valid;
                outlet_start  <= '0';
                outlet_enable <= '1';
            when others =>
                I_ERROR       <= '0';
                I_DONE        <= '0';
                I_SHIFT       <= to_shift(0);
                next_state    <= IDLE_STATE;
                outlet_valid  <= '0';
                outlet_start  <= '0';
                outlet_enable <= '0';
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
    O_SIZE   <= I_CODE(0).data;
    O_START  <= outlet_start;
    O_ENABLE <= outlet_enable;
    O_VALID  <= outlet_valid;
    O_DATA   <= outlet_data;
    O_STRB   <= outlet_strb;
    O_LAST   <= outlet_last;
    outlet_ready <= O_READY;
end RTL;
