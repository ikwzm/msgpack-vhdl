-----------------------------------------------------------------------------------
--!     @file    msgpack_rpc_server_kvmap_get_value.vhd
--!     @brief   MessagePack-RPC Server Key Value Map Get Value Module :
--!     @version 0.2.0
--!     @date    2016/5/17
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
entity  MsgPack_RPC_Server_KVMap_Get_Value is
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
    -- MessagePack-RPC Map Parameter Object Decode Output I/F
    -------------------------------------------------------------------------------
        MAP_PARAM_START : out std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_PARAM_VALID : out std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_PARAM_CODE  : out MsgPack_RPC.Code_Type;
        MAP_PARAM_LAST  : out std_logic;
        MAP_PARAM_ERROR : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_PARAM_DONE  : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_PARAM_SHIFT : in  MsgPack_RPC.Shift_Vector(STORE_SIZE-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Map Value Object Encode Input I/F
    -------------------------------------------------------------------------------
        MAP_VALUE_VALID : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_VALUE_CODE  : in  MsgPack_RPC.Code_Vector (STORE_SIZE-1 downto 0);
        MAP_VALUE_LAST  : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_VALUE_ERROR : in  std_logic_vector        (STORE_SIZE-1 downto 0);
        MAP_VALUE_READY : out std_logic_vector        (STORE_SIZE-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Method Return I/F
    -------------------------------------------------------------------------------
        RES_ID          : out MsgPack_RPC.MsgID_Type;
        RES_CODE        : out MsgPack_RPC.Code_Type;
        RES_VALID       : out std_logic;
        RES_LAST        : out std_logic;
        RES_READY       : in  std_logic
    );
end  MsgPack_RPC_Server_KVMap_Get_Value;
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
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Encode_Array;
use     MsgPack.MsgPack_RPC_Components.MsgPack_RPC_Method_Return_Code;
use     MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Query;
use     MsgPack.MsgPack_KVMap_Components.MsgPack_KVMap_Key_Compare;
architecture RTL of MsgPack_RPC_Server_KVMap_Get_Value is
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
    signal    get_kvmap_code    :  MsgPack_Object.Code_Vector(I_PARAM_WIDTH-1 downto 0);
    signal    get_kvmap_valid   :  std_logic;
    signal    get_kvmap_last    :  std_logic;
    signal    get_kvmap_error   :  std_logic;
    signal    get_kvmap_done    :  std_logic;
    signal    get_kvmap_shift   :  std_logic_vector(I_PARAM_WIDTH-1 downto 0);
    signal    get_match_shift   :  std_logic_vector          (STORE_SIZE*I_PARAM_WIDTH-1 downto 0);
    signal    get_value_code    :  MsgPack_Object.Code_Vector(STORE_SIZE*I_PARAM_WIDTH-1 downto 0);
    signal    get_param_shift   :  std_logic_vector          (STORE_SIZE*I_PARAM_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    ret_value_code    :  MsgPack_Object.Code_Vector(I_PARAM_WIDTH-1 downto 0);
    signal    ret_value_last    :  std_logic;
    signal    ret_value_error   :  std_logic;
    signal    ret_value_valid   :  std_logic;
    signal    ret_value_ready   :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    ret_array_code    :  MsgPack_Object.Code_Vector(I_PARAM_WIDTH-1 downto 0);
    signal    ret_array_last    :  std_logic;
    signal    ret_array_error   :  std_logic;
    signal    ret_array_valid   :  std_logic;
    signal    ret_array_ready   :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    return_error      :  std_logic;
    signal    return_start      :  std_logic;
    signal    return_busy       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  SIZE_BITS         :  integer := 32;
    type      STATE_TYPE       is (IDLE_STATE, RUN_STATE, SKIP_STATE, DONE_STATE);
    signal    curr_state        :  STATE_TYPE;
    signal    array_start       :  std_logic;
    signal    array_size        :  std_logic_vector(SIZE_BITS-1 downto 0);
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
            CODE_WIDTH      => I_PARAM_WIDTH             -- 
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
            ARRAY_START     => array_start             , -- Out :
            ARRAY_SIZE      => array_size              , -- Out :
            VALUE_START     => open                    , -- Out :
            VALUE_CODE      => get_kvmap_code          , -- Out :
            VALUE_LAST      => get_kvmap_last          , -- Out :
            VALUE_VALID     => get_kvmap_valid         , -- Out :
            VALUE_ERROR     => get_kvmap_error         , -- In  :
            VALUE_DONE      => get_kvmap_done          , -- In  :
            VALUE_SHIFT     => get_kvmap_shift           -- In  :
        );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    QUERY_MAP: MsgPack_KVMap_Query                       -- 
        generic map (                                    -- 
            CODE_WIDTH      => I_PARAM_WIDTH           , -- 
            STORE_SIZE      => STORE_SIZE              , --
            MATCH_PHASE     => MATCH_PHASE               --
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            I_CODE          => get_kvmap_code          , -- In  :
            I_LAST          => get_kvmap_last          , -- In  :
            I_VALID         => get_kvmap_valid         , -- In  :
            I_ERROR         => get_kvmap_error         , -- Out :
            I_DONE          => get_kvmap_done          , -- Out :
            I_SHIFT         => get_kvmap_shift         , -- Out :
            O_CODE          => ret_value_code          , -- Out :
            O_VALID         => ret_value_valid         , -- Out :
            O_LAST          => ret_value_last          , -- Out :
            O_ERROR         => ret_value_error         , -- Out :
            O_READY         => ret_value_ready         , -- In  :
            MATCH_REQ       => MAP_MATCH_REQ           , -- Out :
            MATCH_CODE      => MAP_MATCH_CODE          , -- Out :
            MATCH_OK        => MAP_MATCH_OK            , -- In  :
            MATCH_NOT       => MAP_MATCH_NOT           , -- In  :
            MATCH_SHIFT     => get_match_shift         , -- In  :
            PARAM_START     => MAP_PARAM_START         , -- Out :
            PARAM_VALID     => MAP_PARAM_VALID         , -- Out :
            PARAM_CODE      => MAP_PARAM_CODE          , -- Out :
            PARAM_LAST      => MAP_PARAM_LAST          , -- Out :
            PARAM_ERROR     => MAP_PARAM_ERROR         , -- In  :
            PARAM_DONE      => MAP_PARAM_DONE          , -- In  :
            PARAM_SHIFT     => get_param_shift         , -- In  :
            VALUE_VALID     => MAP_VALUE_VALID         , -- In  :
            VALUE_CODE      => get_value_code          , -- In  :
            VALUE_LAST      => MAP_VALUE_LAST          , -- In  :
            VALUE_ERROR     => MAP_VALUE_ERROR         , -- In  :
            VALUE_READY     => MAP_VALUE_READY           -- Out :
        );
    process(MAP_MATCH_SHIFT) begin
        for i in 0 to STORE_SIZE-1 loop
            get_match_shift(I_PARAM_WIDTH*(i+1)-1 downto I_PARAM_WIDTH*i) <= MAP_MATCH_SHIFT(i);
        end loop;
    end process;
    process(MAP_VALUE_CODE) begin
        for i in 0 to STORE_SIZE-1 loop
            get_value_code (I_PARAM_WIDTH*(i+1)-1 downto I_PARAM_WIDTH*i) <= MAP_VALUE_CODE(i);
        end loop;
    end process;
    process(MAP_PARAM_SHIFT) begin
        for i in 0 to STORE_SIZE-1 loop
            get_param_shift(I_PARAM_WIDTH*(i+1)-1 downto I_PARAM_WIDTH*i) <= MAP_PARAM_SHIFT(i);
        end loop;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ENCODE_ARRAY: MsgPack_Object_Encode_Array            -- 
        generic map (                                    -- 
            CODE_WIDTH      => I_PARAM_WIDTH           , --
            SIZE_BITS       => SIZE_BITS                 -- 
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            START           => array_start             , -- In  :
            SIZE            => array_size              , -- In  :
            I_CODE          => ret_value_code          , -- In  :
            I_LAST          => ret_value_last          , -- In  :
            I_ERROR         => ret_value_error         , -- In  :
            I_VALID         => ret_value_valid         , -- In  :
            I_READY         => ret_value_ready         , -- Out :
            O_CODE          => ret_array_code          , -- Out :
            O_LAST          => ret_array_last          , -- Out :
            O_ERROR         => ret_array_error         , -- Out :
            O_VALID         => ret_array_valid         , -- Out :
            O_READY         => ret_array_ready           -- In  :
        );                                               -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    RET_CODE: MsgPack_RPC_Method_Return_Code             -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            RET_ERROR       => return_error            , -- In  :
            RET_START       => return_start            , -- In  :
            RET_BUSY        => return_busy             , -- Out :
            RES_CODE        => RES_CODE                , -- Out :
            RES_VALID       => RES_VALID               , -- Out :
            RES_LAST        => RES_LAST                , -- Out :
            RES_READY       => RES_READY               , -- In  :
            I_VALID         => ret_array_valid         , -- In  :
            I_CODE          => ret_array_code          , -- In  :
            I_LAST          => ret_array_last          , -- In  :
            I_READY         => ret_array_ready           -- Out :
        );
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
    return_start   <= '1' when (curr_state  = IDLE_STATE and PROC_REQ = '1') else '0';
    return_error   <= '0';
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
