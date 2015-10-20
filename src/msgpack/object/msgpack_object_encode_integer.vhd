-----------------------------------------------------------------------------------
--!     @file    msgpack_object_encode_integer.vhd
--!     @brief   MessagePack Object encode integer :
--!     @version 0.1.0
--!     @date    2015/10/19
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
library MsgPack;
use     MsgPack.MsgPack_Object;
entity  MsgPack_Object_Encode_Integer is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      : positive := 1;
        VALUE_WIDTH     : integer range 1 to 64;
        VALUE_SIGN      : boolean  := FALSE
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Control and Status Signals 
    -------------------------------------------------------------------------------
        START           : in  std_logic := '1';
        BUSY            : out std_logic;
    -------------------------------------------------------------------------------
    -- Object Code Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- Integer Value Input
    -------------------------------------------------------------------------------
        VALUE           : in  std_logic_vector(VALUE_WIDTH-1 downto 0)
    );
end MsgPack_Object_Encode_Integer;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
architecture RTL of MsgPack_Object_Encode_Integer is
    function  max(A,B:integer) return integer is begin
        if (A>B) then return A;
        else          return B;
        end if;
    end function;
    constant  VALUE_CODE_WIDTH  :  integer := max(2, CODE_WIDTH);
    signal    value_code        :  MsgPack_Object.Code_Vector(VALUE_CODE_WIDTH-1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    S_INT: if (VALUE_SIGN = TRUE ) generate
        value_code <= MsgPack_Object.New_Code_Vector_Integer(VALUE_CODE_WIDTH,   signed(VALUE));
    end generate;
    U_INT: if (VALUE_SIGN = FALSE) generate
        value_code <= MsgPack_Object.New_Code_Vector_Integer(VALUE_CODE_WIDTH, unsigned(VALUE));
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ONE_VEC: if (CODE_WIDTH >= 2 or VALUE_WIDTH <= MsgPack_Object.CODE_DATA_BITS) generate
        type      STATE_TYPE    is (IDLE_STATE, RUN_STATE);
        signal    curr_state    :  STATE_TYPE;
    begin
        process(CLK, RST) begin
            if (RST = '1') then
                    O_CODE     <= (others => MsgPack_Object.CODE_NULL);
                    curr_state <= IDLE_STATE;
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    O_CODE     <= (others => MsgPack_Object.CODE_NULL);
                    curr_state <= IDLE_STATE;
                else
                    case curr_state is
                        when IDLE_STATE =>
                            if (START = '1') then
                                curr_state <= RUN_STATE;
                            else
                                curr_state <= IDLE_STATE;
                            end if;
                        when RUN_STATE  =>
                            if (O_READY = '1') then
                                curr_state <= IDLE_STATE;
                            else
                                curr_state <= RUN_STATE;
                            end if;
                        when others =>
                                curr_state <= IDLE_STATE;
                    end case;
                    if (curr_state = IDLE_STATE and START = '1') then
                        O_CODE <= value_code(CODE_WIDTH-1 downto 0);
                    end if;
                end if;
            end if;
        end process;
        BUSY    <= '1' when (curr_state = RUN_STATE) else '0';
        O_VALID <= '1' when (curr_state = RUN_STATE) else '0';
        O_LAST  <= '1' when (curr_state = RUN_STATE) else '0';
        O_ERROR <= '0';
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    TWO_VEC: if (CODE_WIDTH < 2 and VALUE_WIDTH > MsgPack_Object.CODE_DATA_BITS) generate
        signal    lower_code    :  MsgPack_Object.Code_Vector(0 downto 0);
        type      STATE_TYPE    is (IDLE_STATE, RUN0_STATE, RUN1_STATE);
        signal    curr_state    :  STATE_TYPE;
    begin
        process(CLK, RST) begin
            if (RST = '1') then
                    O_CODE     <= (others => MsgPack_Object.CODE_NULL);
                    lower_code <= (others => MsgPack_Object.CODE_NULL);
                    curr_state <= IDLE_STATE;
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    O_CODE     <= (others => MsgPack_Object.CODE_NULL);
                    lower_code <= (others => MsgPack_Object.CODE_NULL);
                    curr_state <= IDLE_STATE;
                else
                    case curr_state is
                        when IDLE_STATE =>
                            if (START = '1') then
                                if (value_code(0).complete = '0') then
                                    O_CODE     <= value_code(0 downto 0);
                                    lower_code <= value_code(1 downto 1);
                                    curr_state <= RUN0_STATE;
                                else
                                    O_CODE     <= value_code(0 downto 0);
                                    lower_code <= value_code(1 downto 1);
                                    curr_state <= RUN1_STATE;
                                end if;
                            else
                                curr_state <= IDLE_STATE;
                            end if;
                        when RUN0_STATE  =>
                            if (O_READY = '1') then
                                O_CODE     <= lower_code;
                                curr_state <= RUN1_STATE;
                            else
                                curr_state <= RUN0_STATE;
                            end if;
                        when RUN1_STATE  =>
                            if (O_READY = '1') then
                                curr_state <= IDLE_STATE;
                            else
                                curr_state <= RUN1_STATE;
                            end if;
                        when others =>
                                curr_state <= IDLE_STATE;
                    end case;
                end if;
            end if;
        end process;
        BUSY    <= '1' when (curr_state = RUN0_STATE) or
                            (curr_state = RUN1_STATE) else '0';
        O_VALID <= '1' when (curr_state = RUN0_STATE) or
                            (curr_state = RUN1_STATE) else '0';
        O_LAST  <= '1' when (curr_state = RUN1_STATE) else '0';
        O_ERROR <= '0';
    end generate;
end RTL;
