-----------------------------------------------------------------------------------
--!     @file    msgpack_rpc_method_no_param.vhd
--!     @brief   MessagePack-RPC Method Main Module without Parameter :
--!     @version 0.2.1
--!     @date    2016/7/26
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2015-2016 Ichiro Kawazome
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
use     MsgPack.MsgPack_RPC;
entity  MsgPack_RPC_Method_Main_No_Param is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        NAME            : string;
        MATCH_PHASE     : positive := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Match Interface
    -------------------------------------------------------------------------------
        MATCH_REQ       : in  std_logic_vector(MATCH_PHASE-1 downto 0);
        MATCH_CODE      : in  MsgPack_RPC.Code_Type;
        MATCH_OK        : out std_logic;
        MATCH_NOT       : out std_logic;
        MATCH_SHIFT     : out MsgPack_RPC.Shift_Type;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Call Request Interface
    -------------------------------------------------------------------------------
        PROC_REQ_ID     : in  MsgPack_RPC.MsgID_Type;
        PROC_REQ        : in  std_logic;
        PROC_BUSY       : out std_logic;
        PROC_START      : out std_logic;
        PARAM_CODE      : in  MsgPack_RPC.Code_Type;
        PARAM_VALID     : in  std_logic;
        PARAM_LAST      : in  std_logic;
        PARAM_SHIFT     : out MsgPack_RPC.Shift_Type;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Start/Busy/Done
    -------------------------------------------------------------------------------
        RUN_REQ         : out std_logic;
        RUN_BUSY        : in  std_logic := '1';
        RUN_DONE        : in  std_logic := '0';
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Return Interface
    -------------------------------------------------------------------------------
        RET_ID          : out MsgPack_RPC.MsgID_Type;
        RET_ERROR       : out std_logic;
        RET_START       : out std_logic;
        RET_DONE        : out std_logic;
        RET_BUSY        : in  std_logic
    );
end  MsgPack_RPC_Method_Main_No_Param;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_RPC;
use     MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Key_Compare;
architecture RTL of MsgPack_RPC_Method_Main_No_Param is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  I_PARAM_WIDTH     :  integer := MsgPack_RPC.Code_Length;
    signal    i_param_nomore    :  std_logic;
    signal    i_param_valid     :  std_logic_vector(I_PARAM_WIDTH-1 downto 0);
    signal    i_param_shift     :  std_logic_vector(I_PARAM_WIDTH-1 downto 0);
    constant  I_PARAM_ALL_0     :  std_logic_vector(I_PARAM_WIDTH-1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  to_i_param_shift(Num: integer) return std_logic_vector is
        variable param_shift    :  std_logic_vector(I_PARAM_WIDTH-1 downto 0);
    begin
        for i in param_shift'range loop
            if (i < Num) then
                param_shift(i) := '1';
            else
                param_shift(i) := '0';
            end if;
        end loop;
        return param_shift;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      STATE_TYPE        is (IDLE_STATE        ,
                                    PARAM_BEGIN_STATE ,
                                    ERROR_SKIP_STATE  ,
                                    ERROR_RETURN_STATE,
                                    ERROR_END_STATE   ,
                                    PROC_BEGIN_STATE  ,
                                    PROC_BUSY_STATE   ,
                                    PROC_END_STATE
                                   );
    signal    curr_state        :  STATE_TYPE;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    MATCH: MsgPack_KVMap_Key_Compare                     -- 
        generic map (                                    -- 
            CODE_WIDTH      => MsgPack_RPC.Code_Length , -- 
            I_MAX_PHASE     => MATCH_PHASE             , --
            KEYWORD         => NAME                      --
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- 
            RST             => RST                     , -- 
            CLR             => CLR                     , -- 
            I_CODE          => MATCH_CODE              , -- 
            I_REQ_PHASE     => MATCH_REQ               , -- 
            MATCH           => MATCH_OK                , -- 
            MISMATCH        => MATCH_NOT               , -- 
            SHIFT           => MATCH_SHIFT               -- 
        );                                               --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (PARAM_CODE, PARAM_VALID) begin
        for i in i_param_valid'range loop
            if (PARAM_VALID = '1') then
                i_param_valid(i) <= PARAM_CODE(i).valid;
            else
                i_param_valid(i) <= '0';
            end if;
        end loop;
    end process;
    i_param_nomore <= '1' when (PARAM_LAST = '1') and
                               ((i_param_valid and not i_param_shift) = I_PARAM_ALL_0) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                curr_state   <= IDLE_STATE;
                PROC_START   <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state   <= IDLE_STATE;
                PROC_START   <= '0';
            else
                case curr_state is
                    when IDLE_STATE =>
                        if (PROC_REQ = '1') then
                            curr_state <= PARAM_BEGIN_STATE;
                        else
                            curr_state <= IDLE_STATE;
                        end if;
                    when PARAM_BEGIN_STATE =>
                        if (PARAM_VALID = '1' and PARAM_CODE(0).valid = '1') then
                            if (PARAM_CODE(0).class = MsgPack_Object.CLASS_ARRAY) and
                               (PARAM_CODE(0).data  = std_logic_vector(to_unsigned(0, 32))) then
                                curr_state   <= PROC_BEGIN_STATE;
                            elsif (i_param_nomore = '1') then
                                curr_state   <= ERROR_RETURN_STATE;
                            else
                                curr_state   <= ERROR_SKIP_STATE;
                            end if;
                        else
                                curr_state   <= PARAM_BEGIN_STATE;
                        end if;
                    when ERROR_SKIP_STATE =>
                        if (i_param_nomore = '1') then
                            curr_state <= ERROR_RETURN_STATE;
                        else
                            curr_state <= ERROR_SKIP_STATE;
                        end if;
                    when ERROR_RETURN_STATE =>
                            curr_state <= ERROR_END_STATE;
                    when ERROR_END_STATE =>
                        if (RET_BUSY = '0') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= ERROR_END_STATE;
                        end if;
                    when PROC_BEGIN_STATE =>
                        if    (RUN_DONE = '1') then
                            curr_state <= PROC_END_STATE;
                        elsif (RUN_BUSY = '1') then
                            curr_state <= PROC_BUSY_STATE;
                        else
                            curr_state <= PROC_BEGIN_STATE;
                        end if;
                    when PROC_BUSY_STATE  =>
                        if    (RUN_DONE = '1') or
                              (RUN_BUSY = '0') then
                            curr_state <= PROC_END_STATE;
                        else
                            curr_state <= PROC_BUSY_STATE;
                        end if;
                    when PROC_END_STATE =>
                        if (RET_BUSY = '0') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= PROC_END_STATE;
                        end if;
                    when others =>
                        curr_state   <= IDLE_STATE;
                end case;
                if (curr_state = IDLE_STATE and PROC_REQ = '1') then
                    PROC_START <= '1';
                else
                    PROC_START <= '0';
                end if;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    PROC_BUSY <= '1' when (curr_state /= IDLE_STATE        ) else '0';
    RUN_REQ   <= '1' when (curr_state  = PROC_BEGIN_STATE  ) else '0';
    RET_ERROR <= '1' when (curr_state  = ERROR_RETURN_STATE) else '0';
    RET_START <= '1' when (curr_state  = ERROR_RETURN_STATE) or
                          (curr_state  = PROC_BEGIN_STATE and RUN_DONE = '1') or
                          (curr_state  = PROC_BEGIN_STATE and RUN_BUSY = '1') else '0';
    RET_DONE  <= '1' when (curr_state  = ERROR_RETURN_STATE) or
                          (curr_state  = PROC_BEGIN_STATE and RUN_DONE = '1') or
                          (curr_state  = PROC_BUSY_STATE  and RUN_DONE = '1') or
                          (curr_state  = PROC_BUSY_STATE  and RUN_BUSY = '0') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (curr_state) begin
        case curr_state is
            when PARAM_BEGIN_STATE =>
                i_param_shift  <= to_i_param_shift(1);
            when ERROR_SKIP_STATE =>
                i_param_shift  <= to_i_param_shift(I_PARAM_WIDTH);
            when others =>
                i_param_shift  <= to_i_param_shift(0);
        end case;
    end process;
    PARAM_SHIFT  <= i_param_shift;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                RET_ID <= MsgPack_RPC.MsgID_Null;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                RET_ID <= MsgPack_RPC.MsgID_Null;
            elsif (curr_state = IDLE_STATE and PROC_REQ = '1') then
                RET_ID <= PROC_REQ_ID;
            end if;
        end if;
    end process;
end RTL;
