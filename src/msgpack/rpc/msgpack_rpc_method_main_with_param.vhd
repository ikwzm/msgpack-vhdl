-----------------------------------------------------------------------------------
--!     @file    msgpack_rpc_method_main_with_param.vhd
--!     @brief   MessagePack-RPC Method Main Module with Parameter :
--!     @version 0.2.2
--!     @date    2016/7/28
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
entity  MsgPack_RPC_Method_Main_with_Param is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        NAME            : string;
        PARAM_NUM       : positive := 1;
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
        MATCH_REQ       : in  std_logic_vector        (MATCH_PHASE-1 downto 0);
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
    -- MessagePack-RPC Method Set Parameter Interface
    -------------------------------------------------------------------------------
        SET_PARAM_CODE  : out MsgPack_RPC.Code_Type;
        SET_PARAM_LAST  : out std_logic;
        SET_PARAM_VALID : out std_logic_vector        (PARAM_NUM-1 downto 0);
        SET_PARAM_ERROR : in  std_logic_vector        (PARAM_NUM-1 downto 0);
        SET_PARAM_DONE  : in  std_logic_vector        (PARAM_NUM-1 downto 0);
        SET_PARAM_SHIFT : in  MsgPack_RPC.Shift_Vector(PARAM_NUM-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Request/Acknowledge/Busy/Done/Running
    -------------------------------------------------------------------------------
        RUN_REQ         : out std_logic;
        RUN_ACK         : in  std_logic := '1';
        RUN_BUSY        : in  std_logic := '1';
        RUN_DONE        : in  std_logic := '0';
        RUNNING         : out std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Return Interface
    -------------------------------------------------------------------------------
        RET_ID          : out MsgPack_RPC.MsgID_Type;
        RET_ERROR       : out std_logic;
        RET_START       : out std_logic;
        RET_DONE        : out std_logic;
        RET_BUSY        : in  std_logic
    );
end  MsgPack_RPC_Method_Main_with_Param;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_RPC;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Code_Reducer;
use     MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Key_Compare;
architecture RTL of MsgPack_RPC_Method_Main_with_Param is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    param_ready       :  std_logic;
    signal    param_select      :  std_logic_vector(PARAM_NUM    -1 downto 0);
    constant  PARAM_SEL_ALL_0   :  std_logic_vector(PARAM_NUM    -1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  I_PARAM_WIDTH     :  integer := MsgPack_RPC.Code_Length;
    signal    i_param_code      :  MsgPack_Object.Code_Vector(I_PARAM_WIDTH-1 downto 0);
    signal    i_param_enable    :  std_logic;
    signal    i_param_last      :  std_logic;
    signal    i_param_nomore    :  std_logic;
    signal    i_param_ready     :  std_logic;
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
                                    PARAM_SET_STATE   ,
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
    I_PARAM: MsgPack_Object_Code_Reducer                 --
        generic map (                                    -- 
            I_WIDTH         => MsgPack_RPC.Code_Length , -- 
            O_WIDTH         => I_PARAM_WIDTH           , -- 
            O_VALID_SIZE    => 1                       , -- 
            QUEUE_SIZE      => 0                         -- 
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            DONE            => '0'                     , -- In  :
            BUSY            => open                    , -- Out :
            I_ENABLE        => i_param_enable          , -- In  :
            I_CODE          => PARAM_CODE              , -- In  :
            I_DONE          => PARAM_LAST              , -- In  :
            I_VALID         => PARAM_VALID             , -- In  :
            I_READY         => param_ready             , -- Out :
            O_ENABLE        => '1'                     , -- In  :
            O_CODE          => i_param_code            , -- Out :
            O_DONE          => i_param_last            , -- Out :
            O_VALID         => open                    , -- Out :
            O_READY         => i_param_ready           , -- In  :
            O_SHIFT         => i_param_shift             -- In  :
        );                                               --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (PARAM_CODE, param_ready)
        variable valid :  std_logic_vector(PARAM_CODE'range);
    begin
        for i in valid'range loop
            valid(i) := PARAM_CODE(i).valid;
        end loop;
        if (param_ready = '1') then
            PARAM_SHIFT <= valid;
        else
            PARAM_SHIFT <= (others => '0');
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (i_param_code) begin
        for i in i_param_valid'range loop
            i_param_valid(i) <= i_param_code(i).valid;
        end loop;
    end process;
    i_param_nomore <= '1' when (i_param_last = '1') and
                               ((i_param_valid and not i_param_shift) = I_PARAM_ALL_0) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                curr_state   <= IDLE_STATE;
                param_select <= (others => '0');
                PROC_START   <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state   <= IDLE_STATE;
                param_select <= (others => '0');
                PROC_START   <= '0';
            else
                case curr_state is
                    when IDLE_STATE =>
                        if (PROC_REQ = '1') then
                            curr_state <= PARAM_BEGIN_STATE;
                        else
                            curr_state <= IDLE_STATE;
                        end if;
                        param_select <= (others => '0');
                    when PARAM_BEGIN_STATE =>
                        if (i_param_code(0).valid = '1') then
                            if (i_param_code(0).class = MsgPack_Object.CLASS_ARRAY) and
                               (i_param_code(0).data  = std_logic_vector(to_unsigned(PARAM_NUM, 32))) then
                                curr_state   <= PARAM_SET_STATE;
                                param_select <= (0 => '1', others => '0');
                            elsif (i_param_nomore = '1') then
                                curr_state   <= ERROR_RETURN_STATE;
                                param_select <= (others => '0');
                            else
                                curr_state   <= ERROR_SKIP_STATE;
                                param_select <= (others => '0');
                            end if;
                        else
                                curr_state   <= PARAM_BEGIN_STATE;
                                param_select <= (others => '0');
                        end if;
                    when PARAM_SET_STATE =>
                        if ((SET_PARAM_DONE and param_select) /= PARAM_SEL_ALL_0) then
                            if    ((SET_PARAM_ERROR and param_select) /= PARAM_SEL_ALL_0) then
                                if (i_param_nomore = '1') then
                                    curr_state   <= ERROR_RETURN_STATE;
                                    param_select <= (others => '0');
                                else
                                    curr_state   <= ERROR_SKIP_STATE;
                                    param_select <= (others => '0');
                                end if;
                            elsif (param_select(param_select'high) = '1') then
                                if (i_param_nomore = '0') then
                                    curr_state   <= ERROR_SKIP_STATE;
                                    param_select <= (others => '0');
                                else
                                    curr_state   <= PROC_BEGIN_STATE;
                                    param_select <= (others => '0');
                                end if;
                            else
                                curr_state   <= PARAM_SET_STATE;
                                for i in param_select'range loop
                                    if (i > 0) then
                                        param_select(i) <= param_select(i-1);
                                    else
                                        param_select(i) <= '0';
                                    end if;
                                end loop;
                            end if;
                        else
                                curr_state <= PARAM_SET_STATE;
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
                        elsif (RUN_ACK  = '1') then
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
                        param_select <= (others => '0');
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
    RUNNING   <= '1' when (curr_state  = PROC_BEGIN_STATE  ) or
                          (curr_state  = PROC_BUSY_STATE   ) else '0';
    RET_ERROR <= '1' when (curr_state  = ERROR_RETURN_STATE) else '0';
    RET_START <= '1' when (curr_state  = ERROR_RETURN_STATE) or
                          (curr_state  = PROC_BEGIN_STATE and RUN_DONE = '1') or
                          (curr_state  = PROC_BEGIN_STATE and RUN_ACK  = '1') else '0';
    RET_DONE  <= '1' when (curr_state  = ERROR_RETURN_STATE) or
                          (curr_state  = PROC_BEGIN_STATE and RUN_DONE = '1') or
                          (curr_state  = PROC_BUSY_STATE  and RUN_DONE = '1') or
                          (curr_state  = PROC_BUSY_STATE  and RUN_BUSY = '0') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (curr_state, param_select, PROC_REQ, SET_PARAM_SHIFT)
        variable shift : MsgPack_RPC.Shift_Type;
    begin
        case curr_state is
            when IDLE_STATE =>
                i_param_enable <= PROC_REQ;
                i_param_ready  <= '0';
                i_param_shift  <= to_i_param_shift(0);
            when PARAM_BEGIN_STATE =>
                i_param_enable <= '1';
                i_param_ready  <= '1';
                i_param_shift  <= to_i_param_shift(1);
            when PARAM_SET_STATE   =>
                shift := (others => '0');
                for i in 0 to PARAM_NUM-1 loop
                    if (param_select(i) = '1') then
                        shift := shift or SET_PARAM_SHIFT(i);
                    end if;
                end loop;
                i_param_enable <= '1';
                i_param_ready  <= '1';
                i_param_shift  <= shift;
            when ERROR_SKIP_STATE =>
                i_param_enable <= '1';
                i_param_ready  <= '1';
                i_param_shift  <= to_i_param_shift(I_PARAM_WIDTH);
            when others =>
                i_param_enable <= '0';
                i_param_ready  <= '0';
                i_param_shift  <= to_i_param_shift(0);
        end case;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    SET_PARAM_CODE  <= i_param_code;
    SET_PARAM_LAST  <= i_param_last;
    SET_PARAM_VALID <= param_select;
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
