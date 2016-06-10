-----------------------------------------------------------------------------------
--!     @file    msgpack_rpc_server_kvmap_set_value.vhd
--!     @brief   MessagePack-RPC Server Key Value Map Set Value Module :
--!     @version 0.2.0
--!     @date    2016/6/10
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
entity  MsgPack_RPC_Server_KVMap_Set_Value is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        NAME            : string;
        STORE_SIZE      : positive := 1;
        K_WIDTH         : positive := 1;
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
    -- MessagePack-RPC Method Match I/F
    -------------------------------------------------------------------------------
        MATCH_REQ       : in  std_logic_vector        (MATCH_PHASE-1 downto 0);
        MATCH_CODE      : in  MsgPack_RPC.Code_Type;
        MATCH_OK        : out std_logic;
        MATCH_NOT       : out std_logic;
        MATCH_SHIFT     : out MsgPack_RPC.Shift_Type;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Call Request I/F
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
    -- MessagePack-RPC Map Key Match I/F
    -------------------------------------------------------------------------------
        MAP_MATCH_REQ   : out std_logic_vector       (MATCH_PHASE-1 downto 0);
        MAP_MATCH_CODE  : out MsgPack_RPC.Code_Type;
        MAP_MATCH_OK    : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_MATCH_NOT   : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_MATCH_SHIFT : in  MsgPack_RPC.Shift_Vector(STORE_SIZE-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Map Value Object Decode Output I/F
    -------------------------------------------------------------------------------
        MAP_VALUE_VALID : out std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_VALUE_CODE  : out MsgPack_RPC.Code_Type;
        MAP_VALUE_LAST  : out std_logic;
        MAP_VALUE_ERROR : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_VALUE_DONE  : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_VALUE_SHIFT : in  MsgPack_RPC.Shift_Vector(STORE_SIZE-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Return I/F
    -------------------------------------------------------------------------------
        RES_ID          : out MsgPack_RPC.MsgID_Type;
        RES_CODE        : out MsgPack_RPC.Code_Type;
        RES_VALID       : out std_logic;
        RES_LAST        : out std_logic;
        RES_READY       : in  std_logic
    );
end  MsgPack_RPC_Server_KVMap_Set_Value;
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
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Decode_Array;
use     MsgPack.MsgPack_RPC_Components.MsgPack_RPC_Method_Return_Nil;
use     MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Store;
use     MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Key_Compare;
architecture RTL of MsgPack_RPC_Server_KVMap_Set_Value is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    param_ready       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  I_PARAM_WIDTH     :  integer := MsgPack_RPC.Code_Length;
    signal    i_param_code      :  MsgPack_Object.Code_Vector(I_PARAM_WIDTH-1 downto 0);
    signal    i_param_enable    :  std_logic;
    signal    i_param_last      :  std_logic;
    signal    i_param_ready     :  std_logic;
    signal    i_param_shift     :  std_logic_vector(I_PARAM_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    unpack_valid      :  std_logic;
    signal    unpack_done       :  std_logic;
    signal    unpack_error      :  std_logic;
    signal    unpack_shift      :  std_logic_vector(I_PARAM_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    set_kvmap_code    :  MsgPack_Object.Code_Vector(I_PARAM_WIDTH-1 downto 0);
    signal    set_kvmap_valid   :  std_logic;
    signal    set_kvmap_last    :  std_logic;
    signal    set_kvmap_error   :  std_logic;
    signal    set_kvmap_done    :  std_logic;
    signal    set_kvmap_shift   :  std_logic_vector(I_PARAM_WIDTH-1 downto 0);
    signal    set_match_shift   :  std_logic_vector(STORE_SIZE*I_PARAM_WIDTH-1 downto 0);
    signal    set_value_shift   :  std_logic_vector(STORE_SIZE*I_PARAM_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    return_error      :  std_logic;
    signal    return_start      :  std_logic;
    signal    return_done       :  std_logic;
    signal    return_busy       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      STATE_TYPE       is (IDLE_STATE, RUN_STATE, SKIP_STATE, DONE_STATE);
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
    DECODE_ARRAY: MsgPack_Object_Decode_Array            -- 
        generic map (                                    -- 
            CODE_WIDTH      => I_PARAM_WIDTH           , --
            SIZE_BITS       => 32                        -- 
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            I_CODE          => i_param_code            , -- In  :
            I_LAST          => i_param_last            , -- In  :
            I_VALID         => unpack_valid            , -- In  :
            I_ERROR         => unpack_error            , -- Out :
            I_DONE          => unpack_done             , -- Out :
            I_SHIFT         => unpack_shift            , -- Out :
            ARRAY_START     => open                    , -- Out :
            ARRAY_SIZE      => open                    , -- Out :
            ENTRY_START     => open                    , -- Out :
            ENTRY_BUSY      => open                    , -- Out :
            ENTRY_LAST      => open                    , -- Out :
            ENTRY_SIZE      => open                    , -- Out :
            VALUE_START     => open                    , -- Out :
            VALUE_CODE      => set_kvmap_code          , -- Out :
            VALUE_LAST      => set_kvmap_last          , -- Out :
            VALUE_VALID     => set_kvmap_valid         , -- Out :
            VALUE_ERROR     => set_kvmap_error         , -- In  :
            VALUE_DONE      => set_kvmap_done          , -- In  :
            VALUE_SHIFT     => set_kvmap_shift           -- In  :
        );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    STORE_MAP: MsgPack_KVMap_Store                       -- 
        generic map (                                    -- 
            CODE_WIDTH      => I_PARAM_WIDTH           , --
            STORE_SIZE      => STORE_SIZE              , --
            MATCH_PHASE     => MATCH_PHASE               --
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- in  :
            CLR             => CLR                     , -- In  :
            I_CODE          => set_kvmap_code          , -- In  :
            I_LAST          => set_kvmap_last          , -- In  :
            I_VALID         => set_kvmap_valid         , -- In  :
            I_ERROR         => set_kvmap_error         , -- Out :
            I_DONE          => set_kvmap_done          , -- Out :
            I_SHIFT         => set_kvmap_shift         , -- Out :
            MATCH_REQ       => MAP_MATCH_REQ           , -- Out :
            MATCH_CODE      => MAP_MATCH_CODE          , -- Out :
            MATCH_OK        => MAP_MATCH_OK            , -- In  :
            MATCH_NOT       => MAP_MATCH_NOT           , -- In  :
            MATCH_SHIFT     => set_match_shift         , -- In  :
            VALUE_VALID     => MAP_VALUE_VALID         , -- Out :
            VALUE_CODE      => MAP_VALUE_CODE          , -- Out :
            VALUE_LAST      => MAP_VALUE_LAST          , -- Out :
            VALUE_ERROR     => MAP_VALUE_ERROR         , -- In  :
            VALUE_DONE      => MAP_VALUE_DONE          , -- In  :
            VALUE_SHIFT     => set_value_shift           -- In  :
        );                                               --
    process(MAP_MATCH_SHIFT) begin
        for i in 0 to STORE_SIZE-1 loop
            set_match_shift(I_PARAM_WIDTH*(i+1)-1 downto I_PARAM_WIDTH*i) <= MAP_MATCH_SHIFT(i);
        end loop;
    end process;
    process(MAP_VALUE_SHIFT) begin
        for i in 0 to STORE_SIZE-1 loop
            set_value_shift(I_PARAM_WIDTH*(i+1)-1 downto I_PARAM_WIDTH*i) <= MAP_VALUE_SHIFT(i);
        end loop;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    RET : MsgPack_RPC_Method_Return_Nil                  -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            RET_ERROR       => return_error            , -- In  :
            RET_START       => return_start            , -- In  :
            RET_DONE        => return_done             , -- In  :
            RET_BUSY        => return_busy             , -- Out :
            RES_CODE        => RES_CODE                , -- Out :
            RES_VALID       => RES_VALID               , -- Out :
            RES_LAST        => RES_LAST                , -- Out :
            RES_READY       => RES_READY                 -- In  :
        );                                               -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                curr_state <= IDLE_STATE;
                PROC_START <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state <= IDLE_STATE;
                PROC_START <= '0';
            else
                case curr_state is
                    when IDLE_STATE =>
                        if (PROC_REQ = '1') then
                            curr_state <= RUN_STATE;
                        else
                            curr_state <= IDLE_STATE;
                        end if;
                    when RUN_STATE =>
                        if (unpack_done = '1') then
                            if  (unpack_error = '1') then
                                if (i_param_last = '0') then
                                   curr_state <= SKIP_STATE;
                                else
                                   curr_state <= DONE_STATE;
                                end if;
                            else
                                   curr_state <= DONE_STATE;
                            end if;
                        else
                                   curr_state <= RUN_STATE;
                        end if;
                    when SKIP_STATE =>
                        if (i_param_code(0).valid = '1' and i_param_last = '1') then
                            curr_state <= DONE_STATE;
                        else
                            curr_state <= SKIP_STATE;
                        end if;
                    when DONE_STATE =>
                        if (return_busy = '0') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= DONE_STATE;
                        end if;
                    when others =>
                            curr_state <= IDLE_STATE;
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
    return_start   <= '1' when (curr_state  = IDLE_STATE and PROC_REQ    = '1') else '0';
    return_done    <= '1' when (curr_state  = RUN_STATE  and unpack_done = '1') else '0';
    return_error   <= '1' when (curr_state  = RUN_STATE  and unpack_done = '1' and unpack_error = '1') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    unpack_valid   <= '1' when (curr_state  = RUN_STATE ) else '0';
    i_param_enable <= '1' when (curr_state  = IDLE_STATE and PROC_REQ = '1') or
                               (curr_state  = RUN_STATE ) or
                               (curr_state  = SKIP_STATE) else '0';
    i_param_ready  <= '1' when (curr_state  = RUN_STATE ) or
                               (curr_state  = SKIP_STATE) else '0';
    i_param_shift  <= unpack_shift when (curr_state = RUN_STATE ) else (others => '1');
    PROC_BUSY      <= '1' when (curr_state /= IDLE_STATE) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                RES_ID <= MsgPack_RPC.MsgID_Null;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                RES_ID <= MsgPack_RPC.MsgID_Null;
            elsif (curr_state = IDLE_STATE and PROC_REQ = '1') then
                RES_ID <= PROC_REQ_ID;
            end if;
        end if;
    end process;
end RTL;
