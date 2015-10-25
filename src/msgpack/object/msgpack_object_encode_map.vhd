-----------------------------------------------------------------------------------
--!     @file    msgpack_object_encode_map.vhd
--!     @brief   MessagePack Object encode to map
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
entity  MsgPack_Object_Encode_Map is
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
    -- Key Object Encode Input Interface
    -------------------------------------------------------------------------------
        I_KEY_CODE      : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_KEY_LAST      : in  std_logic;
        I_KEY_ERROR     : in  std_logic;
        I_KEY_VALID     : in  std_logic;
        I_KEY_READY     : out std_logic;
    -------------------------------------------------------------------------------
    -- Value Object Encode Input Interface
    -------------------------------------------------------------------------------
        I_VAL_CODE      : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_VAL_LAST      : in  std_logic;
        I_VAL_ERROR     : in  std_logic;
        I_VAL_VALID     : in  std_logic;
        I_VAL_READY     : out std_logic;
    -------------------------------------------------------------------------------
    -- Key Value Map Object Encode Output Interface
    -------------------------------------------------------------------------------
        O_MAP_CODE      : out MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        O_MAP_LAST      : out std_logic;
        O_MAP_ERROR     : out std_logic;
        O_MAP_VALID     : out std_logic;
        O_MAP_READY     : in  std_logic
    );
end MsgPack_Object_Encode_Map;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
architecture RTL of MsgPack_Object_Encode_Map is
    type      STATE_TYPE        is (IDLE_STATE, MAP_STATE, KEY_STATE, VAL_STATE);
    signal    curr_state        :  STATE_TYPE;
    signal    map_count         :  unsigned(SIZE_BITS-1 downto 0);
    signal    map_count_zero    :  boolean;
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
                                curr_state <= MAP_STATE;
                        else
                                curr_state <= IDLE_STATE;
                        end if;
                    when MAP_STATE =>
                        if (O_MAP_READY = '1') then
                            if (map_count_zero) then
                                curr_state <= IDLE_STATE;
                            else
                                curr_state <= KEY_STATE;
                            end if;
                        else
                                curr_state <= MAP_STATE;
                        end if;
                    when KEY_STATE =>
                        if (I_KEY_VALID = '1' and I_KEY_LAST = '1' and O_MAP_READY = '1') then
                                curr_state <= VAL_STATE;
                        else
                                curr_state <= KEY_STATE;
                        end if;
                    when VAL_STATE =>
                        if (I_VAL_VALID = '1' and I_VAL_LAST = '1' and O_MAP_READY = '1') then
                            if (map_count_zero) then
                                curr_state <= IDLE_STATE;
                            else
                                curr_state <= KEY_STATE;
                            end if;
                        else
                                curr_state <= VAL_STATE;
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
        variable next_count :  unsigned(SIZE_BITS-1 downto 0);
    begin 
        if (RST = '1') then
                map_count      <= (others => '0');
                map_count_zero <= TRUE;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                map_count      <= (others => '0');
                map_count_zero <= TRUE;
            else
                if (curr_state = IDLE_STATE) then
                    next_count := unsigned(SIZE);
                else
                    next_count := map_count;
                end if;
                if (curr_state = MAP_STATE and map_count_zero = FALSE and O_MAP_READY = '1') or
                   (curr_state = VAL_STATE and map_count_zero = FALSE and I_VAL_VALID = '1' and I_VAL_LAST = '1' and O_MAP_READY = '1') then
                    next_count := next_count - 1;
                end if;
                map_count      <= next_count;
                map_count_zero <= (next_count = 0);
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    O_MAP_CODE  <= I_KEY_CODE  when (curr_state = KEY_STATE) else
                   I_VAL_CODE  when (curr_state = VAL_STATE) else
                   MsgPack_Object.New_Code_Vector_MapSize(CODE_WIDTH, map_count);
    O_MAP_VALID <= '1'         when (curr_state = MAP_STATE) else
                   I_KEY_VALID when (curr_state = KEY_STATE) else
                   I_VAL_VALID when (curr_state = VAL_STATE) else '0';
    O_MAP_LAST  <= '1'         when (curr_state = MAP_STATE and map_count_zero) or
                                    (curr_state = VAL_STATE and map_count_zero and I_VAL_LAST = '1') else '0';
    O_MAP_ERROR <= '0';
    I_KEY_READY <= O_MAP_READY when (curr_state = KEY_STATE) else '0';
    I_VAL_READY <= O_MAP_READY when (curr_state = VAL_STATE) else '0';
end RTL;


        
