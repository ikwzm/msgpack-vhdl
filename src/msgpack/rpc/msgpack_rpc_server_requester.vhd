-----------------------------------------------------------------------------------
--!     @file    msgpack_rpc_server_requester.vhd
--!     @brief   MessagePack-RPC Server Requester Module :
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
use     MsgPack.MsgPack_RPC;
entity  MsgPack_RPC_Server_Requester is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        I_BYTES         : integer range 1 to 32 := 1;
        PROC_NUM        : integer := 1;
        MATCH_PHASE     : integer := 8
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Byte Stream Input Interface
    -------------------------------------------------------------------------------
        I_DATA          : in  std_logic_vector(8*I_BYTES-1 downto 0);
        I_STRB          : in  std_logic_vector(  I_BYTES-1 downto 0);
        I_LAST          : in  std_logic := '0';
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Match I/F
    -------------------------------------------------------------------------------
        MATCH_REQ       : out std_logic_vector     (MATCH_PHASE-1 downto 0);
        MATCH_CODE      : out MsgPack_RPC.Code_Type;
        MATCH_OK        : in  std_logic_vector        (PROC_NUM-1 downto 0);
        MATCH_NOT       : in  std_logic_vector        (PROC_NUM-1 downto 0);
        MATCH_SHIFT     : in  MsgPack_RPC.Shift_Vector(PROC_NUM-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Call Request I/F
    -------------------------------------------------------------------------------
        PROC_REQ_ID     : out MsgPack_RPC.MsgID_Type;
        PROC_REQ        : out std_logic_vector        (PROC_NUM-1 downto 0);
        PROC_BUSY       : in  std_logic_vector        (PROC_NUM-1 downto 0);
        PARAM_VALID     : out std_logic_vector        (PROC_NUM-1 downto 0);
        PARAM_CODE      : out MsgPack_RPC.Code_Vector (PROC_NUM-1 downto 0);
        PARAM_LAST      : out std_logic_vector        (PROC_NUM-1 downto 0);
        PARAM_SHIFT     : in  MsgPack_RPC.Shift_Vector(PROC_NUM-1 downto 0);
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Call Error Response I/F
    -------------------------------------------------------------------------------
        ERROR_RES_ID    : out MsgPack_RPC.MsgID_Type;
        ERROR_RES_CODE  : out MsgPack_RPC.Code_Type;
        ERROR_RES_VALID : out std_logic;
        ERROR_RES_LAST  : out std_logic;
        ERROR_RES_READY : in  std_logic
    );
end  MsgPack_RPC_Server_Requester;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_RPC;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Unpacker;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Match_Aggregator;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Code_Compare;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Code_Reducer;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Code_FIFO;
use     MsgPack.MsgPack_KVMap_Components .MsgPack_KVMap_Key_Match_Aggregator;
architecture RTL of MsgPack_RPC_Server_Requester is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  INTAKE_WIDTH      :  integer := MsgPack_RPC.Code_Length;
    constant  DECODE_UNIT       :  integer := 0;
    constant  SHORT_STR_SIZE    :  integer := 0;
    constant  STACK_DEPTH       :  integer := 4;
    constant  VALID_ALL_0       :  std_logic_vector(INTAKE_WIDTH-1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    intake_code       :  MsgPack_Object.Code_Vector(INTAKE_WIDTH-1 downto 0);
    signal    intake_last       :  std_logic;
    signal    intake_ready      :  std_logic;
    signal    intake_valid      :  std_logic_vector(INTAKE_WIDTH-1 downto 0);
    signal    intake_shift      :  std_logic_vector(INTAKE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    type_match_run    :  std_logic;
    signal    type_match_state  :  MsgPack_Object.Match_State_Type;
    signal    type_match_shift  :  std_logic_vector(INTAKE_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    proc_match_run    :  std_logic;
    signal    proc_match_state  :  MsgPack_Object.Match_State_Type;
    signal    proc_match_shift  :  std_logic_vector(INTAKE_WIDTH-1 downto 0);
    signal    proc_match_select :  std_logic_vector(PROC_NUM    -1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    msgid_match_run   :  std_logic;
    signal    msgid_match_state :  MsgPack_Object.Match_State_Type;
    signal    msgid_match_shift :  std_logic_vector(INTAKE_WIDTH-1 downto 0);
    signal    msgid_match_value :  MsgPack_RPC.MsgID_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      STATE_TYPE        is (IDLE_STATE           ,
                                    SKIP_STATE           ,
                                    CHECK_MSGID_STATE    ,
                                    MATCH_PROC_STATE     ,
                                    CHECK_PROC_STATE     ,
                                    PROC_PARAM_STATE     ,
                                    WAIT_ERROR_DONE_STATE,
                                    DONE_STATE
                                   );
    signal    curr_state        :  STATE_TYPE;
    signal    skip_next_state   :  STATE_TYPE;
    signal    message_id        :  MsgPack_RPC.MsgID_Type;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    proc_check_select :  std_logic_vector(PROC_NUM-1 downto 0);
    signal    proc_req_start    :  std_logic_vector(PROC_NUM-1 downto 0);
    signal    proc_req_on       :  std_logic_vector(PROC_NUM-1 downto 0);
    signal    proc_param_select :  std_logic_vector(PROC_NUM-1 downto 0);
    constant  PROC_ALL_0        :  std_logic_vector(PROC_NUM-1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    proc_name_code    :  MsgPack_Object.Code_Vector(INTAKE_WIDTH-1 downto 0);
    signal    proc_name_valid   :  std_logic;
    signal    proc_name_last    :  std_logic;
    signal    proc_name_ready   :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    skip_state_shift  :  std_logic_vector(INTAKE_WIDTH-1 downto 0);
    signal    skip_state_done   :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    proc_param_shift  :  std_logic_vector(INTAKE_WIDTH-1 downto 0);
    signal    proc_param_done   :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      ERROR_REQ_TYPE    is (ERROR_REQ_NONE       ,
                                    ERROR_REQ_PROC_BUSY  ,
                                    ERROR_REQ_NO_METHOD  ,
                                    ERROR_REQ_INVALID_MSG);
    signal    error_request     :  ERROR_REQ_TYPE;
    signal    error_busy        :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  priority_selector(
                 Data    : std_logic_vector
    )            return    std_logic_vector
    is
        variable result  : std_logic_vector(Data'range);
    begin
        for i in Data'range loop
            if (i = Data'low) then
                result(i) := Data(i);
            else
                result(i) := Data(i) and (not Data(i-1));
            end if;
        end loop;
        return result;
    end function;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    UNPACK: MsgPack_Object_Unpacker                  -- 
        generic map (                                -- 
            I_BYTES         => I_BYTES             , --
            CODE_WIDTH      => INTAKE_WIDTH        , -- 
            O_VALID_SIZE    => 1                   , -- 
            DECODE_UNIT     => DECODE_UNIT         , -- 
            SHORT_STR_SIZE  => SHORT_STR_SIZE      , -- 
            STACK_DEPTH     => STACK_DEPTH           -- 
        )                                            -- 
        port map (                                   -- 
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
            I_DATA          => I_DATA              , -- In  :
            I_STRB          => I_STRB              , -- In  :
            I_LAST          => I_LAST              , -- In  :
            I_VALID         => I_VALID             , -- In  :
            I_READY         => I_READY             , -- Out :
            O_CODE          => intake_code         , -- Out :
            O_LAST          => intake_last         , -- Out :
            O_VALID         => open                , -- Out :
            O_READY         => intake_ready        , -- In  :
            O_SHIFT         => intake_shift          -- In  :
        );                                           --
    process (intake_code) begin                      --
        for i in intake_valid'range loop             -- 
            intake_valid(i) <= intake_code(i).valid; -- 
        end loop;                                    --
    end process;                                     -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    TYPE_MATCH: block
        constant  Req_Type_Code :  MsgPack_Object.Code_Vector(1 downto 0) := (
                      0 => MsgPack_Object.New_Code_ArraySize(4),
                      1 => MsgPack_Object.New_Code_Unsigned(0)
                  );
        signal    match_req   :  std_logic_vector(1 downto 0);
        signal    match_ok    :  std_logic_vector(0 downto 0);
        signal    match_not   :  std_logic_vector(0 downto 0);
        signal    match_shift :  MsgPack_RPC.Shift_Vector(0 downto 0);
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        COMPARE: MsgPack_Object_Code_Compare             -- 
            generic map (                                -- 
                C_WIDTH       => Req_Type_Code'length  , -- 
                I_WIDTH       => INTAKE_WIDTH          , --
                I_MAX_PHASE   => match_req'length        -- 
            )                                            -- 
            port map (                                   -- 
                CLK           => CLK                   , -- In  :
                RST           => RST                   , -- In  :
                CLR           => CLR                   , -- In  :
                I_CODE        => intake_code           , -- In  :
                I_REQ_PHASE   => match_req             , -- In  :
                C_CODE        => Req_Type_Code         , -- In  :
                MATCH         => match_ok   (0)        , -- Out :
                MISMATCH      => match_not  (0)        , -- Out :
                SHIFT         => match_shift(0)          -- Out :
            );                                           --
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        AGGREGATE: MsgPack_Object_Match_Aggregator       -- 
            generic map (                                -- 
                CODE_WIDTH    => INTAKE_WIDTH          , --
                MATCH_NUM     => 1                     , -- 
                MATCH_PHASE   => match_req'length        -- 
            )                                            -- 
            port map (                                   -- 
                CLK           => CLK                   , -- In  :
                RST           => RST                   , -- In  :
                CLR           => CLR                   , -- In  :
                I_VALID       => type_match_run        , -- In  :
                I_CODE        => intake_code           , -- In  :
                I_LAST        => intake_last           , -- In  :
                I_SHIFT       => type_match_shift      , -- Out :
                PHASE_NEXT    => open                  , -- Out :
                PHASE_READY   => '1'                   , -- In  :
                MATCH_REQ     => match_req             , -- Out :
                MATCH_OK      => match_ok              , -- In  :
                MATCH_NOT     => match_not             , -- In  :
                MATCH_SHIFT   => match_shift(0)        , -- In  :
                MATCH_SEL     => open                  , -- Out :
                MATCH_STATE   => type_match_state        -- Out :
            );
    end block;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    PROC_MATCH: block
        signal    match_shift_vector :  std_logic_vector( PROC_NUM*INTAKE_WIDTH-1 downto 0);
        signal    fifo_clear         :  std_logic;
        signal    key_code           :  MsgPack_Object.Code_Vector(INTAKE_WIDTH-1 downto 0);
        signal    key_valid          :  std_logic;
        signal    key_ready          :  std_logic;
        signal    key_last           :  std_logic;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (MATCH_SHIFT) begin
            for i in 0 to PROC_NUM-1 loop
                match_shift_vector(INTAKE_WIDTH*(i+1)-1 downto INTAKE_WIDTH*i) <= MATCH_SHIFT(i);
            end loop;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        AGGREGATE: MsgPack_KVMap_Key_Match_Aggregator    -- 
            generic map (                                -- 
                CODE_WIDTH    => INTAKE_WIDTH          , --
                MATCH_NUM     => PROC_NUM              , -- 
                MATCH_PHASE   => MATCH_REQ'length        -- 
            )                                            -- 
            port map (                                   -- 
                CLK           => CLK                   , -- In  :
                RST           => RST                   , -- In  :
                CLR           => CLR                   , -- In  :
                I_KEY_VALID   => proc_match_run        , -- In  :
                I_KEY_CODE    => intake_code           , -- In  :
                I_KEY_LAST    => intake_last           , -- In  :
                I_KEY_SHIFT   => proc_match_shift      , -- Out :
                O_KEY_VALID   => key_valid             , -- Out :
                O_KEY_CODE    => key_code              , -- Out :
                O_KEY_LAST    => key_last              , -- Out :
                O_KEY_READY   => key_ready             , -- In  :
                MATCH_REQ     => MATCH_REQ             , -- Out :
                MATCH_OK      => MATCH_OK              , -- In  :
                MATCH_NOT     => MATCH_NOT             , -- In  :
                MATCH_SHIFT   => match_shift_vector    , -- In  :
                MATCH_SEL     => proc_match_select     , -- Out :
                MATCH_STATE   => proc_match_state        -- Out :
            );                                           --
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        MATCH_CODE <= intake_code;
        fifo_clear <= '1' when (CLR = '1') or
                               (curr_state = IDLE_STATE) else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        FIFO: MsgPack_Object_Code_FIFO                   -- 
            generic map (                                -- 
                WIDTH         => INTAKE_WIDTH          , --
                DEPTH         => 4                       -- 
            )                                            -- 
            port map (                                   -- 
                CLK           => CLK                   , -- In  :
                RST           => RST                   , -- In  :
                CLR           => fifo_clear            , -- In  :
                I_VALID       => key_valid             , -- In  :
                I_CODE        => key_code              , -- In  :
                I_LAST        => key_last              , -- In  :
                I_READY       => key_ready             , -- Out :
                O_VALID       => proc_name_valid       , -- Out :
                O_CODE        => proc_name_code        , -- Out :
                O_LAST        => proc_name_last        , -- Out :
                O_READY       => proc_name_ready         -- In  :
            );                                           --
    end block;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    MSGID_MATCH: process (msgid_match_run, intake_code, intake_valid, intake_last)
        constant shift : std_logic_vector(INTAKE_WIDTH-1 downto 0) := (0 => '1', others => '0');
    begin
        if (msgid_match_run = '1') then
            if (intake_code(0).valid = '1') then
                if ((intake_code(0).class = MsgPack_Object.CLASS_UINT) or
                    (intake_code(0).class = MsgPack_Object.CLASS_INT )) and
                   (intake_code(0).complete  = '1') then
                    if ((intake_last = '1') and ((intake_valid and not shift) = VALID_ALL_0)) then
                        msgid_match_state <= MsgPack_Object.MATCH_DONE_FOUND_LAST_STATE;
                    else
                        msgid_match_state <= MsgPack_Object.MATCH_DONE_FOUND_CONT_STATE;
                    end if;
                    msgid_match_shift <= shift;
                else
                    msgid_match_state <= MsgPack_Object.MATCH_DONE_NOT_FOUND_CONT_STATE;
                    msgid_match_shift <= (others => '0');
                end if;
            else
                    msgid_match_state <= MsgPack_Object.MATCH_BUSY_STATE;
                    msgid_match_shift <= (others => '0');
            end if;
        else
                    msgid_match_state <= MsgPack_Object.MATCH_IDLE_STATE;
                    msgid_match_shift <= (others => '0');
        end if;
        msgid_match_value <= intake_code(0).data;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    proc_req_start <= priority_selector(proc_check_select and not PROC_BUSY);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                curr_state        <= IDLE_STATE;
                skip_next_state   <= DONE_STATE;
                proc_check_select <= PROC_ALL_0;
                proc_param_select <= PROC_ALL_0;
                message_id        <= MsgPack_RPC.MsgID_Null;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state        <= IDLE_STATE;
                skip_next_state   <= DONE_STATE;
                proc_check_select <= PROC_ALL_0;
                proc_param_select <= PROC_ALL_0;
                message_id        <= MsgPack_RPC.MsgID_Null;
            else
                case curr_state is
                    when IDLE_STATE =>
                        case type_match_state is
                            when MsgPack_Object.MATCH_DONE_FOUND_CONT_STATE     =>
                                curr_state      <= CHECK_MSGID_STATE;
                            when MsgPack_Object.MATCH_DONE_FOUND_LAST_STATE     =>
                                curr_state      <= DONE_STATE;
                            when MsgPack_Object.MATCH_DONE_NOT_FOUND_CONT_STATE |
                                 MsgPack_Object.MATCH_DONE_NOT_FOUND_LAST_STATE =>
                                curr_state      <= SKIP_STATE;
                                skip_next_state <= DONE_STATE;
                            when others =>
                                curr_state      <= IDLE_STATE;
                        end case;
                        proc_check_select <= PROC_ALL_0;
                        proc_param_select <= PROC_ALL_0;
                    when CHECK_MSGID_STATE =>
                        case msgid_match_state is
                            when MsgPack_Object.MATCH_DONE_FOUND_CONT_STATE     =>
                                curr_state      <= MATCH_PROC_STATE;
                            when MsgPack_Object.MATCH_DONE_FOUND_LAST_STATE     =>
                                curr_state      <= WAIT_ERROR_DONE_STATE;
                            when MsgPack_Object.MATCH_DONE_NOT_FOUND_CONT_STATE |
                                 MsgPack_Object.MATCH_DONE_NOT_FOUND_LAST_STATE =>
                                curr_state      <= SKIP_STATE;
                                skip_next_state <= WAIT_ERROR_DONE_STATE;
                            when others =>
                                curr_state      <= CHECK_MSGID_STATE;
                        end case;
                        message_id        <= msgid_match_value;
                        proc_check_select <= PROC_ALL_0;
                        proc_param_select <= PROC_ALL_0;
                    when MATCH_PROC_STATE =>
                        case proc_match_state is
                            when MsgPack_Object.MATCH_DONE_FOUND_CONT_STATE     =>
                                curr_state      <= CHECK_PROC_STATE;
                            when MsgPack_Object.MATCH_DONE_FOUND_LAST_STATE     =>
                                curr_state      <= WAIT_ERROR_DONE_STATE;
                            when MsgPack_Object.MATCH_DONE_NOT_FOUND_CONT_STATE =>
                                curr_state      <= SKIP_STATE;
                                skip_next_state <= WAIT_ERROR_DONE_STATE;
                            when MsgPack_Object.MATCH_DONE_NOT_FOUND_LAST_STATE =>
                                curr_state      <= WAIT_ERROR_DONE_STATE;
                            when others =>
                                curr_state      <= MATCH_PROC_STATE;
                        end case;
                        proc_check_select <= proc_match_select;
                        proc_param_select <= PROC_ALL_0;
                    when CHECK_PROC_STATE =>
                        if (proc_req_start /= PROC_ALL_0) then
                            curr_state <= PROC_PARAM_STATE;
                        else
                            curr_state <= WAIT_ERROR_DONE_STATE;
                        end if;
                        proc_param_select <= proc_req_start;
                    when PROC_PARAM_STATE =>
                        if (proc_param_done = '1') then
                            curr_state        <= DONE_STATE;
                            proc_param_select <= (others => '0');
                        else
                            curr_state        <= PROC_PARAM_STATE;
                        end if;
                    when SKIP_STATE  =>
                        if (skip_state_done = '1') then
                            curr_state <= skip_next_state;
                        else
                            curr_state <= SKIP_STATE;
                        end if;
                    when WAIT_ERROR_DONE_STATE =>
                        if (error_busy = '0') then
                            curr_state <= DONE_STATE;
                        else
                            curr_state <= WAIT_ERROR_DONE_STATE;
                        end if;
                    when DONE_STATE =>
                        curr_state        <= IDLE_STATE;
                        proc_check_select <= (others => '0');
                        proc_param_select <= (others => '0');
                    when others =>
                        curr_state        <= IDLE_STATE;
                        proc_check_select <= (others => '0');
                        proc_param_select <= (others => '0');
                end case;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process(curr_state, msgid_match_state, proc_match_state, proc_req_start) begin
        case curr_state is
            when CHECK_MSGID_STATE =>
                case msgid_match_state is
                    when MsgPack_Object.MATCH_DONE_FOUND_LAST_STATE     |
                         MsgPack_Object.MATCH_DONE_NOT_FOUND_CONT_STATE |
                         MsgPack_Object.MATCH_DONE_NOT_FOUND_LAST_STATE =>
                        error_request <= ERROR_REQ_INVALID_MSG;
                    when others =>
                        error_request <= ERROR_REQ_NONE;
                end case;
            when MATCH_PROC_STATE =>
                case proc_match_state is
                    when MsgPack_Object.MATCH_DONE_FOUND_LAST_STATE     =>
                        error_request <= ERROR_REQ_INVALID_MSG;
                    when MsgPack_Object.MATCH_BUSY_NOT_FOUND_STATE      |
                         MsgPack_Object.MATCH_DONE_NOT_FOUND_CONT_STATE |
                         MsgPack_Object.MATCH_DONE_NOT_FOUND_LAST_STATE =>
                        error_request <= ERROR_REQ_NO_METHOD;
                    when others =>
                        error_request <= ERROR_REQ_NONE;
                end case;
            when CHECK_PROC_STATE =>
                if (proc_req_start = PROC_ALL_0) then
                        error_request <= ERROR_REQ_PROC_BUSY;
                else
                        error_request <= ERROR_REQ_NONE;
                end if;
            when others =>
                        error_request <= ERROR_REQ_NONE;
        end case;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type_match_run   <= '1' when (curr_state = IDLE_STATE  and intake_valid(0) = '1') else '0';
    msgid_match_run  <= '1' when (curr_state = CHECK_MSGID_STATE     ) else '0';
    proc_match_run   <= '1' when (curr_state = MATCH_PROC_STATE) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    skip_state_shift <= intake_valid when (curr_state = SKIP_STATE) else (others => '0');
    skip_state_done  <= '1' when (intake_valid(0) = '1' and intake_last = '1') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    intake_shift     <= type_match_shift  or
                        msgid_match_shift or
                        proc_match_shift  or
                        skip_state_shift  or
                        proc_param_shift;
    intake_ready     <= '1' when (curr_state = IDLE_STATE       ) or
                                 (curr_state = CHECK_MSGID_STATE) or
                                 (curr_state = MATCH_PROC_STATE ) or
                                 (curr_state = PROC_PARAM_STATE ) or
                                 (curr_state = SKIP_STATE       ) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                proc_req_on <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                proc_req_on <= (others => '0');
            elsif (curr_state = CHECK_PROC_STATE) then
                proc_req_on <= proc_req_start;
            else
                for i in 0 to PROC_NUM-1 loop
                    if (proc_req_on(i) = '1' and PROC_BUSY(i) = '1') then
                        proc_req_on(i) <= '0';
                    end if;
                end loop;
            end if;
        end if;
    end process;
    PROC_REQ    <= proc_req_on;
    PROC_REQ_ID <= message_id;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    PARAM_GEN: for i in 0 to PROC_NUM-1 generate
        PARAM_CODE(i)  <= intake_code;
        PARAM_LAST(i)  <= intake_last;
        PARAM_VALID(i) <= proc_param_select(i);
    end generate;
    process (PARAM_SHIFT, proc_param_select, curr_state)
        variable shift : MsgPack_RPC.Shift_Type;
    begin
        shift := (others => '0');
        for i in 0 to PROC_NUM-1 loop
            if (curr_state = PROC_PARAM_STATE) and
               (proc_param_select(i) = '1'   ) then
                shift := shift or PARAM_SHIFT(i);
            end if;
        end loop;
        proc_param_shift <= shift;
    end process;
    proc_param_done <= '1' when (intake_valid(0) = '1') and
                                (intake_last     = '1') and
                                ((intake_valid and not proc_param_shift) = VALID_ALL_0) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ERROR_GEN: block
        constant  proc_busy_code     :  MsgPack_Object.Code_Vector(INTAKE_WIDTH-1 downto 0)
                                     := MsgPack_RPC.New_Error_Code_Vector_Proc_Busy(INTAKE_WIDTH);
        constant  no_method_code     :  MsgPack_Object.Code_Vector(INTAKE_WIDTH-1 downto 0)
                                     := MsgPack_RPC.New_Error_Code_Vector_No_Method(INTAKE_WIDTH);
        constant  msg_error_code     :  MsgPack_Object.Code_Vector(INTAKE_WIDTH-1 downto 0)
                                     := MsgPack_RPC.New_Error_Code_Vector_Invalid_Message(INTAKE_WIDTH);
        signal    send_error_code    :  MsgPack_Object.Code_Vector(INTAKE_WIDTH-1 downto 0);
        signal    send_error_last    :  std_logic;
        signal    send_error_valid   :  std_logic;
        signal    send_error_ready   :  std_logic;
        signal    send_error_busy    :  std_logic;
        constant  error_shift        :  MsgPack_RPC.Shift_Type := (others => '1');
        constant  result_nil_code    :  MsgPack_Object.Code_Vector(INTAKE_WIDTH-1 downto 0)
                                     := MsgPack_Object.New_Code_Vector_Nil(INTAKE_WIDTH);
        type      ERROR_STATE_TYPE  is (IDLE_STATE, DONE_STATE ,
                                        NO_METHOD_ERROR_STATE  , NO_METHOD_RESULT_STATE  ,
                                        MSG_ERROR_ERROR_STATE  , MSG_ERROR_RESULT_STATE  ,
                                        METHOD_BUSY_ERROR_STATE, METHOD_BUSY_RESULT_STATE);
        signal    error_state        :  ERROR_STATE_TYPE;
    begin  
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK, RST) begin
            if (RST = '1') then
                    error_state <= IDLE_STATE;
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    error_state <= IDLE_STATE;
                else
                    case error_state is
                        when IDLE_STATE =>
                            case error_request is
                                when ERROR_REQ_NO_METHOD   =>
                                    error_state <= NO_METHOD_ERROR_STATE;
                                when ERROR_REQ_INVALID_MSG =>
                                    error_state <= MSG_ERROR_ERROR_STATE;
                                when ERROR_REQ_PROC_BUSY   =>
                                    error_state <= METHOD_BUSY_ERROR_STATE;
                                when others => 
                                    error_state <= IDLE_STATE;
                            end case;
                        when NO_METHOD_ERROR_STATE =>
                            if (send_error_ready = '1') then
                                error_state <= NO_METHOD_RESULT_STATE;
                            else
                                error_state <= NO_METHOD_ERROR_STATE;
                            end if;
                        when NO_METHOD_RESULT_STATE =>
                            if (proc_name_valid = '1' and proc_name_ready = '1' and proc_name_last = '1') then
                                error_state <= DONE_STATE;
                            else
                                error_state <= NO_METHOD_RESULT_STATE;
                            end if;
                        when METHOD_BUSY_ERROR_STATE =>
                            if (send_error_ready = '1') then
                                error_state <= METHOD_BUSY_RESULT_STATE;
                            else
                                error_state <= METHOD_BUSY_ERROR_STATE;
                            end if;
                        when METHOD_BUSY_RESULT_STATE =>
                            if (send_error_ready = '1') then
                                error_state <= DONE_STATE;
                            else
                                error_state <= METHOD_BUSY_RESULT_STATE;
                            end if;
                        when MSG_ERROR_ERROR_STATE =>
                            if (send_error_ready = '1') then
                                error_state <= MSG_ERROR_RESULT_STATE;
                            else
                                error_state <= MSG_ERROR_ERROR_STATE;
                            end if;
                        when MSG_ERROR_RESULT_STATE =>
                            if (send_error_ready = '1') then
                                error_state <= DONE_STATE;
                            else
                                error_state <= MSG_ERROR_RESULT_STATE;
                            end if;
                        when DONE_STATE =>
                            if (send_error_busy = '0') then
                                error_state <= IDLE_STATE;
                            else
                                error_state <= DONE_STATE;
                            end if;
                        when others =>
                                error_state <= IDLE_STATE;
                    end case;
                end if;
            end if;
        end process;
        error_busy <= '1' when (error_state /= IDLE_STATE) else '0';
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        send_error_valid <= '1' when (error_state = NO_METHOD_ERROR_STATE                              ) or
                                     (error_state = NO_METHOD_RESULT_STATE  and proc_name_valid   = '1') or
                                     (error_state = MSG_ERROR_ERROR_STATE                              ) or
                                     (error_state = MSG_ERROR_RESULT_STATE                             ) or
                                     (error_state = METHOD_BUSY_ERROR_STATE                            ) or
                                     (error_state = METHOD_BUSY_RESULT_STATE                           ) else '0';
        send_error_last  <= '1' when (error_state = NO_METHOD_RESULT_STATE  and proc_name_last    = '1') or
                                     (error_state = MSG_ERROR_RESULT_STATE                             ) or
                                     (error_state = METHOD_BUSY_RESULT_STATE                           ) else '0';
        send_error_code  <= no_method_code when (error_state = NO_METHOD_ERROR_STATE  ) else
                            proc_name_code when (error_state = NO_METHOD_RESULT_STATE ) else
                            msg_error_code when (error_state = MSG_ERROR_ERROR_STATE  ) else
                            proc_busy_code when (error_state = METHOD_BUSY_ERROR_STATE) else
                            result_nil_code;
        proc_name_ready  <= '1' when (error_state = NO_METHOD_RESULT_STATE   and send_error_ready  = '1') else '0';
        ERROR_RES_ID     <= message_id;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        OUTLET: MsgPack_Object_Code_Reducer                  -- 
            generic map (                                    -- 
                I_WIDTH         => INTAKE_WIDTH            , -- 
                O_WIDTH         => MsgPack_RPC.Code_Length , --
                O_VALID_SIZE    => MsgPack_RPC.Code_Length , -- 
                QUEUE_SIZE      => 0                         -- 
            )                                                -- 
            port map (                                       -- 
                CLK             => CLK                     , -- In  :
                RST             => RST                     , -- In  :
                CLR             => CLR                     , -- In  :
                DONE            => '0'                     , -- In  :
                BUSY            => send_error_busy         , -- Out :
                I_ENABLE        => '1'                     , -- In  :
                I_CODE          => send_error_code         , -- In  :
                I_DONE          => send_error_last         , -- In  :
                I_VALID         => send_error_valid        , -- In  :
                I_READY         => send_error_ready        , -- Out :
                O_ENABLE        => '1'                     , -- In  :
                O_CODE          => ERROR_RES_CODE          , -- Out :
                O_DONE          => ERROR_RES_LAST          , -- Out :
                O_VALID         => ERROR_RES_VALID         , -- Out :
                O_READY         => ERROR_RES_READY         , -- In  :
                O_SHIFT         => error_shift               -- In  :
            );                                               --
    end block;
end RTL;
