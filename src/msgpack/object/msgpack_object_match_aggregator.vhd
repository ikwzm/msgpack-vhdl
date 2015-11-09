-----------------------------------------------------------------------------------
--!     @file    msgpack_object_match_aggregator.vhd
--!     @brief   MessagePack Object Match Aggregator Module :
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
entity  MsgPack_Object_Match_Aggregator is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        CODE_WIDTH         : positive := 1;
        MATCH_NUM       : integer  := 1;
        MATCH_PHASE     : integer  := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Object Code Input Interface
    -------------------------------------------------------------------------------
        I_VALID         : in  std_logic;
        I_CODE          : in  MsgPack_Object.Code_Vector(CODE_WIDTH-1 downto 0);
        I_LAST          : in  std_logic := '0';
        I_SHIFT         : out std_logic_vector(          CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Phase Control Status Signals
    -------------------------------------------------------------------------------
        PHASE_NEXT      : out std_logic;
        PHASE_READY     : in  std_logic := '1';
    -------------------------------------------------------------------------------
    -- Object Code Compare Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : out std_logic_vector(         MATCH_PHASE-1 downto 0);
        MATCH_OK        : in  std_logic_vector(MATCH_NUM           -1 downto 0);
        MATCH_NOT       : in  std_logic_vector(MATCH_NUM           -1 downto 0);
        MATCH_SHIFT     : in  std_logic_vector(MATCH_NUM*CODE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- Aggregated Result Output
    -------------------------------------------------------------------------------
        MATCH_SEL       : out std_logic_vector(MATCH_NUM           -1 downto 0);
        MATCH_STATE     : out MsgPack_Object.Match_State_Type
    );
end MsgPack_Object_Match_Aggregator;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
architecture RTL of MsgPack_Object_Match_Aggregator is
    constant  MATCH_ALL_0   :  std_logic_vector( MATCH_NUM-1 downto 0) := (others => '0');
    constant  MATCH_ALL_1   :  std_logic_vector( MATCH_NUM-1 downto 0) := (others => '1');
    constant  SHIFT_ALL_0   :  std_logic_vector(CODE_WIDTH-1 downto 0) := (others => '0');
    constant  SHIFT_ALL_1   :  std_logic_vector(CODE_WIDTH-1 downto 0) := (others => '1');
    constant  VALID_ALL_0   :  std_logic_vector(CODE_WIDTH-1 downto 0) := (others => '0');
    signal    i_phase_next  :  std_logic;
    signal    curr_phase    :  std_logic_vector(MATCH_PHASE-1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (I_VALID, I_CODE, I_LAST, MATCH_OK, MATCH_NOT, MATCH_SHIFT, PHASE_READY, curr_phase)
        variable  i_match_shift :  std_logic_vector(CODE_WIDTH-1 downto 0);
        variable  i_code_valid  :  std_logic_vector(CODE_WIDTH-1 downto 0);
    begin
        i_match_shift := (others => '0');
        for i in 0 to MATCH_NUM-1 loop
            i_match_shift := i_match_shift or MATCH_SHIFT(CODE_WIDTH*(i+1)-1 downto CODE_WIDTH*i);
        end loop;
        for i in 0 to CODE_WIDTH-1 loop
            i_code_valid(i) := I_CODE(i).valid;
        end loop;
        if (I_VALID = '1') then
            if    (PHASE_READY = '0') then
                MATCH_STATE  <= MsgPack_Object.MATCH_BUSY_STATE;
                I_SHIFT      <= SHIFT_ALL_0;
                i_phase_next <= '0';
            elsif (MATCH_OK  /= MATCH_ALL_0) then
                if (I_LAST = '1' and ((i_code_valid and not i_match_shift) = VALID_ALL_0)) then
                    MATCH_STATE <= MsgPack_Object.MATCH_DONE_FOUND_LAST_STATE;
                else
                    MATCH_STATE <= MsgPack_Object.MATCH_DONE_FOUND_CONT_STATE;
                end if;
                I_SHIFT      <= i_match_shift;
                i_phase_next <= '0';
            elsif (curr_phase(curr_phase'high) = '1' and i_code_valid(i_code_valid'high) = '1') or
                  (I_LAST = '1') or
                  ((MATCH_NOT /= MATCH_ALL_0) and
                   ((MATCH_OK or MATCH_NOT) = MATCH_ALL_1)) then
                MATCH_STATE  <= MsgPack_Object.MATCH_DONE_NOT_FOUND_CONT_STATE;
                I_SHIFT      <= SHIFT_ALL_0;
                i_phase_next <= '0';
            elsif (i_code_valid(i_code_valid'high) = '1') then
                MATCH_STATE  <= MsgPack_Object.MATCH_BUSY_STATE;
                I_SHIFT      <= SHIFT_ALL_1;
                i_phase_next <= '1';
            else
                MATCH_STATE  <= MsgPack_Object.MATCH_BUSY_STATE;
                I_SHIFT      <= SHIFT_ALL_0;
                i_phase_next <= '0';
            end if;
        else
                MATCH_STATE  <= MsgPack_Object.MATCH_IDLE_STATE;
                I_SHIFT      <= SHIFT_ALL_0;
                i_phase_next <= '0';
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    MATCH_SEL  <= MATCH_OK;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    MATCH_REQ  <= curr_phase when (I_VALID = '1') else (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    PHASE_NEXT <= i_phase_next;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process(CLK, RST) begin
        if (RST = '1') then
                curr_phase <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') or
               (I_VALID = '0') then
                curr_phase <= (0 => '1', others => '0');
            elsif (i_phase_next = '1') then
                for i in curr_phase'range loop
                    if (i > 0) then
                        curr_phase(i) <= curr_phase(i-1);
                    else
                        curr_phase(i) <= '0';
                    end if;
                end loop;
             end if ;
        end if;
    end process;
end RTL;
