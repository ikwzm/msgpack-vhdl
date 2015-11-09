-----------------------------------------------------------------------------------
--!     @file    msgpack_object_encode_array.vhd
--!     @brief   MessagePack Object encode to array
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
entity  MsgPack_Object_Encode_Array is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH      :  positive := 1;
        SIZE_BITS       :  positive := 32
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        START           : in  std_logic;
        SIZE            : in  std_logic_vector(SIZE_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    -- Value Object Encode Input Interface
    -------------------------------------------------------------------------------
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic;
        I_ERROR         : in  std_logic;
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
    -------------------------------------------------------------------------------
    -- Array Object Encode Output Interface
    -------------------------------------------------------------------------------
        O_CODE          : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_LAST          : out std_logic;
        O_ERROR         : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic
    );
end MsgPack_Object_Encode_Array;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
architecture RTL of MsgPack_Object_Encode_Array is
    type      STATE_TYPE        is (IDLE_STATE, ARRAY_STATE, VALUE_STATE);
    signal    curr_state        :  STATE_TYPE;
    signal    array_count       :  unsigned(SIZE_BITS-1 downto 0);
    signal    array_count_zero  :  boolean;
begin
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
                case curr_state is
                    when IDLE_STATE =>
                        if (START = '1') then
                                curr_state <= ARRAY_STATE;
                        else
                                curr_state <= IDLE_STATE;
                        end if;
                    when ARRAY_STATE =>
                        if (O_READY = '1') then
                            if (array_count_zero) then
                                curr_state <= IDLE_STATE;
                            else
                                curr_state <= VALUE_STATE;
                            end if;
                        else
                                curr_state <= ARRAY_STATE;
                        end if;
                    when VALUE_STATE =>
                        if (I_VALID = '1' and I_LAST = '1' and O_READY = '1') then
                            if (array_count_zero) then
                                curr_state <= IDLE_STATE;
                            else
                                curr_state <= VALUE_STATE;
                            end if;
                        else
                                curr_state <= VALUE_STATE;
                        end if;
                    when others =>
                                curr_state <= IDLE_STATE;
                end case;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST)
        variable next_count :  unsigned(SIZE'range);
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
                    next_count := unsigned(SIZE);
                else
                    next_count := array_count;
                end if;
                if (curr_state = ARRAY_STATE and array_count_zero = FALSE and O_READY = '1') or
                   (curr_state = VALUE_STATE and array_count_zero = FALSE and I_VALID = '1' and I_LAST = '1' and O_READY = '1') then
                    next_count := next_count - 1;
                end if;
                array_count      <= next_count;
                array_count_zero <= (next_count = 0);
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    O_CODE  <= I_CODE  when (curr_state = VALUE_STATE) else
               MsgPack_Object.New_Code_Vector_ArraySize(CODE_WIDTH, array_count);
    O_VALID <= '1'     when (curr_state = ARRAY_STATE) else
               I_VALID when (curr_state = VALUE_STATE) else '0';
    O_LAST  <= '1'     when (curr_state = ARRAY_STATE and array_count_zero) or
                            (curr_state = VALUE_STATE and array_count_zero and I_LAST = '1') else '0';
    O_ERROR <= '0';
    I_READY <= O_READY when (curr_state = VALUE_STATE) else '0';
end RTL;


        
