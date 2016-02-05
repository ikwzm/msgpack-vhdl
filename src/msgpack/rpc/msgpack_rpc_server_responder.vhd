-----------------------------------------------------------------------------------
--!     @file    msgpack_rpc_server_responder.vhd
--!     @brief   MessagePack-RPC Server Responder Module :
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
entity  MsgPack_RPC_Server_Responder is
    -------------------------------------------------------------------------------
    -- Generic Parameters
    -------------------------------------------------------------------------------
    generic (
        O_BYTES         : integer range 1 to 32 := 1;
        RES_NUM         : integer := 1
    );
    port (
    -------------------------------------------------------------------------------
    -- Clock and Reset Signals
    -------------------------------------------------------------------------------
        CLK             : in  std_logic; 
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPC Byte Stream Output Interface
    -------------------------------------------------------------------------------
        O_DATA          : out std_logic_vector(8*O_BYTES-1 downto 0);
        O_STRB          : out std_logic_vector(  O_BYTES-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- MessagePack-RPCs Method Call Response I/F
    -------------------------------------------------------------------------------
        RES_ID          : in  MsgPack_RPC.MsgID_Vector(RES_NUM-1 downto 0);
        RES_CODE        : in  MsgPack_RPC.Code_Vector (RES_NUM-1 downto 0);
        RES_VALID       : in  std_logic_vector        (RES_NUM-1 downto 0);
        RES_LAST        : in  std_logic_vector        (RES_NUM-1 downto 0);
        RES_READY       : out std_logic_vector        (RES_NUM-1 downto 0)
    );
end  MsgPack_RPC_Server_Responder;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library MsgPack;
use     MsgPack.MsgPack_Object;
use     MsgPack.MsgPack_RPC;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Packer;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Code_Reducer;
use     MsgPack.MsgPack_Object_Components.MsgPack_Object_Encode_String_Constant;
use     MsgPack.PipeWork_Components.QUEUE_ARBITER;
architecture RTL of MsgPack_RPC_Server_Responder is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  OUTLET_WIDTH      :  integer := MsgPack_RPC.Code_Length;
    constant  PACK_WIDTH        :  integer := MsgPack_RPC.Code_Length;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    outlet_code       :  MsgPack_Object.Code_Vector(OUTLET_WIDTH-1 downto 0);
    signal    outlet_last       :  std_logic;
    signal    outlet_valid      :  std_logic;
    signal    outlet_ready      :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    pack_code         :  MsgPack_Object.Code_Vector(PACK_WIDTH-1 downto 0);
    signal    pack_shift        :  std_logic_vector          (PACK_WIDTH-1 downto 0);
    signal    pack_last         :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    resp_req          :  std_logic;
    signal    resp_shift        :  std_logic;
    signal    resp_select       :  std_logic_vector(RES_NUM-1 downto 0);
    signal    resp_select_req   :  std_logic_vector(RES_NUM-1 downto 0);
    constant  SEL_ALL_0         :  std_logic_vector(RES_NUM-1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    response_code     :  MsgPack_Object.Code_Vector(OUTLET_WIDTH-1 downto 0);
    signal    response_last     :  std_logic;
    signal    response_valid    :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    resv_err_code     :  MsgPack_Object.Code_Vector(OUTLET_WIDTH-1 downto 0);
    signal    resv_err_last     :  std_logic;
    signal    resv_err_check    :  std_logic;
    signal    resv_err_valid    :  std_logic;
    signal    resv_err_ready    :  std_logic;
    signal    resv_err_busy     :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      STATE_TYPE        is (IDLE_STATE    ,
                                    TYPE_STATE    ,
                                    MSGID_STATE   ,
                                    RESV_ERR_STATE,
                                    CHK_RESV_STATE,
                                    RESPONSE_STATE
                                );
    signal    curr_state        :  STATE_TYPE;
    signal    next_state        :  STATE_TYPE;
begin 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ARB: QUEUE_ARBITER                           -- 
        generic map (                            -- 
            MIN_NUM         => 0               , -- 
            MAX_NUM         => RES_NUM-1         -- 
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
            ENABLE          => '1'             , -- In  :
            REQUEST         => RES_VALID       , -- In  :
            GRANT           => resp_select_req , -- Out :
            GRANT_NUM       => open            , -- Out :
            REQUEST_O       => resp_req        , -- Out :
            VALID           => open            , -- Out :
            SHIFT           => resp_shift        -- In  :
        );                                       -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                curr_state <= IDLE_STATE;
                resp_select <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                curr_state <= IDLE_STATE;
                resp_select <= (others => '0');
            else
                case curr_state is
                    when IDLE_STATE =>
                        if (outlet_ready = '1' and resp_req = '1') then
                            if (OUTLET_WIDTH > 1) then
                                curr_state <= MSGID_STATE;
                            else
                                curr_state <= TYPE_STATE;
                            end if;
                        else
                                curr_state <= IDLE_STATE;
                        end if;
                        resp_select <= resp_select_req;
                    when TYPE_STATE =>
                        if (outlet_ready = '1') then
                            curr_state <= MSGID_STATE;
                        else
                            curr_state <= TYPE_STATE;
                        end if;
                    when MSGID_STATE =>
                        if    (outlet_ready   = '0') then
                            curr_state <= MSGID_STATE;
                        elsif (resv_err_check = '1') then
                            curr_state <= CHK_RESV_STATE;
                        elsif (resv_err_busy  = '1') then
                            curr_state <= RESV_ERR_STATE;
                        else
                            curr_state <= RESPONSE_STATE;
                        end if;
                    when CHK_RESV_STATE =>
                        if    (resv_err_check = '1') then
                            curr_state <= CHK_RESV_STATE;
                        elsif (resv_err_busy  = '1') then
                            curr_state <= RESV_ERR_STATE;
                        else
                            curr_state <= RESPONSE_STATE;
                        end if;
                    when RESV_ERR_STATE =>
                        if (resv_err_busy = '0') then
                            curr_state <= RESPONSE_STATE;
                        else
                            curr_state <= RESV_ERR_STATE;
                        end if;
                    when RESPONSE_STATE  =>
                        if (outlet_ready = '1' and outlet_valid = '1' and outlet_last = '1') then
                            curr_state <= IDLE_STATE;
                        else
                            curr_state <= RESPONSE_STATE;
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
    ERROR_BLOCK: block
        signal    no_method_code     :  MsgPack_Object.Code_Vector(OUTLET_WIDTH-1 downto 0);
        signal    no_method_last     :  std_logic;
        signal    no_method_start    :  std_logic;
        signal    no_method_valid    :  std_logic;
        signal    no_method_ready    :  std_logic;
        signal    arg_error_code     :  MsgPack_Object.Code_Vector(OUTLET_WIDTH-1 downto 0);
        signal    arg_error_last     :  std_logic;
        signal    arg_error_start    :  std_logic;
        signal    arg_error_valid    :  std_logic;
        signal    arg_error_ready    :  std_logic;
        signal    msg_error_code     :  MsgPack_Object.Code_Vector(OUTLET_WIDTH-1 downto 0);
        signal    msg_error_last     :  std_logic;
        signal    msg_error_start    :  std_logic;
        signal    msg_error_valid    :  std_logic;
        signal    msg_error_ready    :  std_logic;
        signal    proc_busy_code     :  MsgPack_Object.Code_Vector(OUTLET_WIDTH-1 downto 0);
        signal    proc_busy_last     :  std_logic;
        signal    proc_busy_start    :  std_logic;
        signal    proc_busy_valid    :  std_logic;
        signal    proc_busy_ready    :  std_logic;
        constant  result_nil_code    :  MsgPack_Object.Code_Vector(OUTLET_WIDTH-1 downto 0)
                                     := MsgPack_Object.New_Code_Vector_Nil(OUTLET_WIDTH);
        type      ERROR_STATE_TYPE  is (ERROR_IDLE_STATE     ,
                                        ERROR_CHECK_STATE    ,
                                        ERROR_NO_METHOD_STATE,
                                        ERROR_ARG_ERROR_STATE,
                                        ERROR_MSG_ERROR_STATE,
                                        ERROR_PROC_BUSY_STATE
                                       );
        signal    error_state        :  ERROR_STATE_TYPE;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        NO_METHOD: MsgPack_Object_Encode_String_Constant     --
            generic map (                                    -- 
                VALUE           => string'("NoMethodError"), --
                CODE_WIDTH      => OUTLET_WIDTH              --
            )                                                -- 
            port map (                                       -- 
                CLK             => CLK                     , -- In  :
                RST             => RST                     , -- In  :
                CLR             => CLR                     , -- In  :
                START           => no_method_start         , -- In  :
                BUSY            => open                    , -- Out :
                O_CODE          => no_method_code          , -- Out :
                O_LAST          => no_method_last          , -- Out :
                O_ERROR         => open                    , -- Out :
                O_VALID         => no_method_valid         , -- Out :
                O_READY         => no_method_ready           -- In  :
            );                                               --
        no_method_start <= '1' when (error_state = ERROR_CHECK_STATE) and
                                    (response_code(0).valid = '1') and
                                    (MsgPack_RPC.Is_Error_Code_No_Method(response_code(0))) else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        ARG_ERROR: MsgPack_Object_Encode_String_Constant     --
            generic map (                                    -- 
                VALUE           => string'("ArgumentError"), --
                CODE_WIDTH      => OUTLET_WIDTH              --
            )                                                -- 
            port map (                                       -- 
                CLK             => CLK                     , -- In  :
                RST             => RST                     , -- In  :
                CLR             => CLR                     , -- In  :
                START           => arg_error_start         , -- In  :
                BUSY            => open                    , -- Out :
                O_CODE          => arg_error_code          , -- Out :
                O_LAST          => arg_error_last          , -- Out :
                O_ERROR         => open                    , -- Out :
                O_VALID         => arg_error_valid         , -- Out :
                O_READY         => arg_error_ready           -- In  :
            );                                               --
        arg_error_start <= '1' when (error_state = ERROR_CHECK_STATE) and
                                    (response_code(0).valid = '1') and
                                    (MsgPack_RPC.Is_Error_Code_Invalid_Argment(response_code(0))) else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        PROC_BUSY: MsgPack_Object_Encode_String_Constant     --
            generic map (                                    -- 
                VALUE           => string'("MethodBusy")   , --
                CODE_WIDTH      => OUTLET_WIDTH              --
            )                                                -- 
            port map (                                       -- 
                CLK             => CLK                     , -- In  :
                RST             => RST                     , -- In  :
                CLR             => CLR                     , -- In  :
                START           => proc_busy_start         , -- In  :
                BUSY            => open                    , -- Out :
                O_CODE          => proc_busy_code          , -- Out :
                O_LAST          => proc_busy_last          , -- Out :
                O_ERROR         => open                    , -- Out :
                O_VALID         => proc_busy_valid         , -- Out :
                O_READY         => proc_busy_ready           -- In  :
            );
        proc_busy_start <= '1' when (error_state = ERROR_CHECK_STATE) and
                                    (response_code(0).valid = '1') and
                                    (MsgPack_RPC.Is_Error_Code_Proc_Busy(response_code(0))) else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        MSG_ERROR: MsgPack_Object_Encode_String_Constant     --
            generic map (                                    -- 
                VALUE           => string'("MessageError") , --
                CODE_WIDTH      => OUTLET_WIDTH              --
            )                                                -- 
            port map (                                       -- 
                CLK             => CLK                     , -- In  :
                RST             => RST                     , -- In  :
                CLR             => CLR                     , -- In  :
                START           => msg_error_start         , -- In  :
                BUSY            => open                    , -- Out :
                O_CODE          => msg_error_code          , -- Out :
                O_LAST          => msg_error_last          , -- Out :
                O_ERROR         => open                    , -- Out :
                O_VALID         => msg_error_valid         , -- Out :
                O_READY         => msg_error_ready           -- In  :
            );
        msg_error_start <= '1' when (error_state = ERROR_CHECK_STATE) and
                                    (response_code(0).valid = '1') and
                                    (MsgPack_RPC.Is_Error_Code_Invalid_Message(response_code(0))) else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK, RST) begin
            if (RST = '1') then
                    error_state <= ERROR_IDLE_STATE;
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    error_state <= ERROR_IDLE_STATE;
                else
                    case error_state is
                        when ERROR_IDLE_STATE =>
                            if (curr_state = IDLE_STATE) and
                               (outlet_ready = '1' and resp_req = '1') then
                                error_state <= ERROR_CHECK_STATE;
                            else
                                error_state <= ERROR_IDLE_STATE;
                            end if;
                        when ERROR_CHECK_STATE =>
                            if (response_code(0).valid = '0') then
                                error_state <= ERROR_CHECK_STATE;
                            elsif    (no_method_start = '1') then
                                error_state <= ERROR_NO_METHOD_STATE;
                            elsif (arg_error_start = '1') then
                                error_state <= ERROR_ARG_ERROR_STATE;
                            elsif (msg_error_start = '1') then
                                error_state <= ERROR_MSG_ERROR_STATE;
                            elsif (proc_busy_start = '1') then
                                error_state <= ERROR_PROC_BUSY_STATE;
                            else
                                error_state <= ERROR_IDLE_STATE;
                            end if;
                        when ERROR_NO_METHOD_STATE =>
                            if (no_method_valid = '1' and no_method_ready = '1' and no_method_last = '1') then
                                error_state <= ERROR_IDLE_STATE;
                            else
                                error_state <= ERROR_NO_METHOD_STATE;
                            end if;
                        when ERROR_ARG_ERROR_STATE =>
                            if (arg_error_valid = '1' and arg_error_ready = '1' and arg_error_last = '1') then
                                error_state <= ERROR_IDLE_STATE;
                            else
                                error_state <= ERROR_ARG_ERROR_STATE;
                            end if;
                        when ERROR_MSG_ERROR_STATE =>
                            if (msg_error_valid = '1' and msg_error_ready = '1' and msg_error_last = '1') then
                                error_state <= ERROR_IDLE_STATE;
                            else
                                error_state <= ERROR_MSG_ERROR_STATE;
                            end if;
                        when ERROR_PROC_BUSY_STATE =>
                            if (proc_busy_valid = '1' and proc_busy_ready = '1' and proc_busy_last = '1') then
                                error_state <= ERROR_IDLE_STATE;
                            else
                                error_state <= ERROR_PROC_BUSY_STATE;
                            end if;
                        when others =>
                                error_state <= ERROR_IDLE_STATE;
                    end case;
                end if;
            end if;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        resv_err_busy   <= '1' when (error_state /= ERROR_IDLE_STATE) else '0';
        resv_err_check  <= '1' when (error_state = ERROR_CHECK_STATE) else '0';
        resv_err_valid  <= '1' when (error_state = ERROR_PROC_BUSY_STATE and proc_busy_valid = '1') or
                                    (error_state = ERROR_NO_METHOD_STATE and no_method_valid = '1') or
                                    (error_state = ERROR_ARG_ERROR_STATE and arg_error_valid = '1') or
                                    (error_state = ERROR_MSG_ERROR_STATE and msg_error_valid = '1') else '0';
        resv_err_last   <= '0';
        resv_err_code   <= proc_busy_code when (error_state = ERROR_PROC_BUSY_STATE) else
                           no_method_code when (error_state = ERROR_NO_METHOD_STATE) else
                           arg_error_code when (error_state = ERROR_ARG_ERROR_STATE) else
                           msg_error_code when (error_state = ERROR_MSG_ERROR_STATE) else
                           result_nil_code;
        proc_busy_ready <= '1' when (error_state = ERROR_PROC_BUSY_STATE and resv_err_ready = '1') else '0';
        no_method_ready <= '1' when (error_state = ERROR_NO_METHOD_STATE and resv_err_ready = '1') else '0';
        arg_error_ready <= '1' when (error_state = ERROR_ARG_ERROR_STATE and resv_err_ready = '1') else '0';
        msg_error_ready <= '1' when (error_state = ERROR_MSG_ERROR_STATE and resv_err_ready = '1') else '0';
    end block;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (resp_select, RES_CODE, RES_VALID, RES_LAST)
        variable  code      :  MsgPack_Object.Code_Vector(OUTLET_WIDTH-1 downto 0);
    begin
        if ((RES_VALID and resp_select) /= SEL_ALL_0) then
            response_valid <= '1';
        else
            response_valid <= '0';
        end if;
        if ((RES_LAST  and resp_select) /= SEL_ALL_0) then
            response_last  <= '1';
        else
            response_last  <= '0';
        end if;
        code := (others => MsgPack_Object.CODE_NULL);
        for i in 0 to RES_NUM-1 loop
            for pos in code'range loop
                if (resp_select(i) = '1') then
                    code(pos).data     := code(pos).data     or RES_CODE(i)(pos).data;
                    code(pos).strb     := code(pos).strb     or RES_CODE(i)(pos).strb;
                    code(pos).class    := code(pos).class    or RES_CODE(i)(pos).class;
                    code(pos).complete := code(pos).complete or RES_CODE(i)(pos).complete;
                    code(pos).valid    := code(pos).valid    or RES_CODE(i)(pos).valid;
                end if;
            end loop;
        end loop;
        response_code <= code;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (curr_state, resp_req, resp_select, RES_ID,
             response_code, response_valid, response_last,
             resv_err_code, resv_err_valid, resv_err_last)
        function  max(A,B:integer) return integer is begin
            if (A>B) then return A;
            else          return B;
            end if;
        end function;
        constant  max_width :  integer := max(3, OUTLET_WIDTH);
        variable  code      :  MsgPack_Object.Code_Vector(max_width-1 downto 0);
        variable  msgid     :  std_logic_vector(31 downto 0);
    begin
        case curr_state is
            when IDLE_STATE  =>
                outlet_valid   <= resp_req;
                outlet_last    <= '0';
                code(0) := MsgPack_Object.New_Code_ArraySize(4);
                code(1) := MsgPack_Object.New_Code_Unsigned (1);
                code(code'high downto 2) := (code'high downto 2 => MsgPack_Object.CODE_NULL);
                outlet_code <= code(outlet_code'range);
            when TYPE_STATE  =>
                outlet_valid <= '1';
                outlet_last  <= '0';
                code(0) := MsgPack_Object.New_Code_Unsigned (1);
                code(code'high downto 1) := (code'high downto 1 => MsgPack_Object.CODE_NULL);
                outlet_code <= code(outlet_code'range);
            when MSGID_STATE =>
                outlet_valid <= '1';
                outlet_last  <= '0';
                msgid := (others => '0');
                for i in 0 to RES_NUM-1 loop
                    if (resp_select(i) = '1') then
                        msgid := msgid or RES_ID(i);
                    end if;
                end loop;
                code(0) := MsgPack_Object.New_Code_Unsigned (msgid);
                code(code'high downto 1) := (code'high downto 1 => MsgPack_Object.CODE_NULL);
                outlet_code <= code(outlet_code'range);
            when RESV_ERR_STATE =>
                outlet_valid <= resv_err_valid;
                outlet_last  <= resv_err_last;
                outlet_code  <= resv_err_code;
            when RESPONSE_STATE  =>
                outlet_valid <= response_valid;
                outlet_last  <= response_last;
                outlet_code  <= response_code;
            when others =>
                outlet_valid <= '0';
                outlet_last  <= '0';
                outlet_code  <= (others => MsgPack_Object.CODE_NULL);
        end case;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    resv_err_ready <=    '1' when (curr_state = RESV_ERR_STATE and outlet_ready = '1') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    RES_READY <= resp_select when (curr_state = RESPONSE_STATE and outlet_ready = '1') else (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    resp_shift <= '1' when (outlet_valid = '1' and outlet_ready = '1' and outlet_last = '1') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    PACK_BUFFER: MsgPack_Object_Code_Reducer     -- 
        generic map (                            -- 
            I_WIDTH         => OUTLET_WIDTH    , -- 
            O_WIDTH         => PACK_WIDTH      , -- 
            O_VALID_SIZE    => PACK_WIDTH      , -- 
            QUEUE_SIZE      => 0                 -- 
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
            DONE            => '0'             , -- In  :
            BUSY            => open            , -- Out :
            I_ENABLE        => '1'             , -- In  :
            I_CODE          => outlet_code     , -- In  :
            I_DONE          => outlet_last     , -- In  :
            I_VALID         => outlet_valid    , -- In  :
            I_READY         => outlet_ready    , -- Out :
            O_ENABLE        => '1'             , -- In  :
            O_CODE          => pack_code       , -- Out :
            O_DONE          => pack_last       , -- Out :
            O_VALID         => open            , -- Out :
            O_READY         => '1'             , -- In  :
            O_SHIFT         => pack_shift        -- In  :
        );                                       -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    PACK: MsgPack_Object_Packer                  -- 
        generic map (                            -- 
            CODE_WIDTH      => PACK_WIDTH      , --
            O_BYTES         => O_BYTES           --
        )                                        -- 
        port map (                               -- 
            CLK             => CLK             , -- In  :
            RST             => RST             , -- In  :
            CLR             => CLR             , -- In  :
            I_CODE          => pack_code       , -- In  :
            I_LAST          => pack_last       , -- In  :
            I_SHIFT         => pack_shift      , -- Out :
            O_DATA          => O_DATA          , -- Out :
            O_STRB          => O_STRB          , -- Out :
            O_LAST          => O_LAST          , -- Out :
            O_VALID         => O_VALID         , -- Out :
            O_READY         => O_READY           -- In  :
        );                                       -- 
end RTL;
