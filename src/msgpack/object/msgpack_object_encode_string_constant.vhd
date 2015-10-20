-----------------------------------------------------------------------------------
--!     @file    msgpack_object_encode_string_constant.vhd
--!     @brief   MessagePack Object encode string constant :
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
entity  MsgPack_Object_Encode_String_Constant is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        VALUE           : string;
        CODE_WIDTH      : positive := 1
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
        O_READY         : in  std_logic
    );
end MsgPack_Object_Encode_String_Constant;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
architecture RTL of MsgPack_Object_Encode_String_Constant is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  CODE_DATA_BYTES    :  integer := MsgPack_Object.CODE_DATA_BYTES;
    constant  STR_CODE_SIZE      :  integer := (VALUE'length+CODE_DATA_BYTES-1)/CODE_DATA_BYTES + 1;
    constant  PHASE_NUM          :  integer := (STR_CODE_SIZE+CODE_WIDTH-1)/CODE_WIDTH;
    constant  PHASE_MAX          :  integer := PHASE_NUM - 1;
    constant  STR_CODE_WIDTH     :  integer := PHASE_NUM*CODE_WIDTH;
    constant  STR_CODE           :  MsgPack_Object.Code_Vector(STR_CODE_WIDTH-1 downto 0)
                                 := MsgPack_Object.New_Code_Vector_String(STR_CODE_WIDTH, VALUE);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    curr_phase         :  integer range 0 to PHASE_MAX;
    signal    last_phase         :  boolean;
    type      STATE_TYPE         is (IDLE_STATE, RUN_STATE);
    signal    curr_state         :  STATE_TYPE;
    signal    curr_code          :  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST)
        variable  next_phase     :  integer range 0 to PHASE_MAX;
        variable  next_code      :  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
    begin
        if (RST = '1') then
                curr_state <= IDLE_STATE;
                curr_phase <= 0;
                last_phase <= false;
                curr_code  <= (others => MsgPack_Object.CODE_NULL);
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state <= IDLE_STATE;
                curr_phase <= 0;
                last_phase <= false;
                curr_code  <= (others => MsgPack_Object.CODE_NULL);
            else
                case curr_state is
                    when IDLE_STATE =>
                        if (START = '1') then
                            curr_state <= RUN_STATE;
                        else
                            curr_state <= IDLE_STATE;
                        end if;
                        next_phase := 0;
                    when RUN_STATE =>
                        if (last_phase = TRUE  and O_READY = '1') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= RUN_STATE;
                        end if;
                        if (last_phase = FALSE and O_READY = '1') then
                            next_phase := curr_phase + 1;
                        else
                            next_phase := curr_phase;
                        end if;
                    when others =>
                            curr_state <= IDLE_STATE;
                            next_phase := 0;
                end case;
                next_code  := (others => MsgPack_Object.CODE_NULL);
                for i in 0 to PHASE_MAX loop
                    if (i = next_phase) then
                        next_code(CODE_WIDTH-1 downto 0) := STR_CODE(CODE_WIDTH*(i+1)-1 downto CODE_WIDTH*i);
                    end if;
                end loop;
                curr_code  <= next_code;
                last_phase <= (next_phase >= PHASE_MAX);
                curr_phase <= next_phase;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    BUSY    <= '1' when (curr_state = RUN_STATE) else '0';
    O_VALID <= '1' when (curr_state = RUN_STATE) else '0';
    O_LAST  <= '1' when (last_phase = TRUE     ) else '0';
    O_ERROR <= '0';
    O_CODE  <= curr_code;
end RTL;
                
